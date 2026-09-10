"""线上可用的短信验证码与支付 Mock API。

正常业务路由默认始终返回成功；失败、超时、限流和无效响应路由只用于接口异常测试。
生产环境通过 MOCK_SHARED_TOKEN 保护所有 /mock/* 路由，/health 保持公开用于容器探活。
"""

from __future__ import annotations

import hashlib
import hmac
import os
import secrets
import time
from threading import Lock
from typing import Dict, Any

from flask import Flask, jsonify, request


app = Flask(__name__)
codes: Dict[str, Dict[str, Any]] = {}
payments: Dict[str, Dict[str, Any]] = {}
state_lock = Lock()


def _configured_code() -> str:
    fixed = os.getenv("SMS_MOCK_FIXED_CODE", "").strip()
    if fixed.isdigit() and len(fixed) == 6:
        return fixed
    return f"{secrets.randbelow(1_000_000):06d}"


def _payload() -> Dict[str, Any]:
    payload = request.get_json(silent=True)
    return payload if isinstance(payload, dict) else request.form.to_dict()


def _authorized() -> bool:
    expected = os.getenv("MOCK_SHARED_TOKEN", "").strip()
    if not expected:
        return True
    supplied = request.headers.get("X-Mock-Token", "")
    if not supplied:
        supplied = request.args.get("token", "")
    return bool(supplied) and hmac.compare_digest(supplied, expected)


@app.before_request
def protect_mock_routes():
    if request.path.startswith("/mock/") and not _authorized():
        return jsonify({"ok": False, "message": "mock authorization required"}), 401
    return None


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "payment-sms-mock"})


def _sms_send(scenario: str = "success"):
    data = _payload()
    phone = str(data.get("phone", "")).strip()
    code_type = str(data.get("type", "reset")).strip() or "reset"
    try:
        ttl = max(1, int(data.get("ttl", 60)))
    except (TypeError, ValueError):
        ttl = 60
    if not phone:
        return jsonify({"ok": False, "message": "phone is required"}), 400

    scenario = str(data.get("mode", scenario)).strip().lower() or "success"
    if scenario in {"fail", "error", "invalid"}:
        status = 503 if scenario != "invalid" else 200
        return jsonify({"ok": False, "message": "mock sms send failed"}), status
    if scenario in {"rate_limit", "rate-limited"}:
        return jsonify({"ok": False, "message": "mock sms rate limited"}), 429
    if scenario == "timeout":
        time.sleep(min(30, max(1, int(os.getenv("MOCK_TIMEOUT_DELAY", "6")))))
        return jsonify({"ok": False, "message": "mock sms timeout"}), 504

    now = int(time.time())
    record = {
        "phone": phone,
        "type": code_type,
        "code": _configured_code(),
        "created_at": now,
        "expires_at": now + ttl,
    }
    with state_lock:
        codes[phone] = record
    return jsonify({"ok": True, "code": record["code"], "expires_at": record["expires_at"]})


@app.post("/mock/sms/send")
def send_code():
    return _sms_send("success")


@app.post("/mock/sms/send/<scenario>")
def send_code_scenario(scenario: str):
    return _sms_send(scenario)


@app.get("/mock/sms/code")
def get_code():
    phone = request.args.get("phone", "").strip()
    with state_lock:
        record = dict(codes.get(phone, {}))
    if not record:
        return jsonify({"ok": False, "message": "code not found"}), 404
    if int(record["expires_at"]) <= int(time.time()):
        return jsonify({"ok": False, "message": "code expired", "expires_at": record["expires_at"]}), 410
    return jsonify({"ok": True, **record})


@app.post("/mock/sms/reset")
def reset_codes():
    with state_lock:
        codes.clear()
    return jsonify({"ok": True})


@app.post("/mock/sms/expire")
def expire_code():
    data = _payload()
    phone = str(data.get("phone", "")).strip()
    with state_lock:
        if phone not in codes:
            return jsonify({"ok": False, "message": "code not found"}), 404
        codes[phone]["expires_at"] = int(time.time()) - 1
    return jsonify({"ok": True})


def _payment_pay(scenario: str = "success"):
    data = _payload()
    order_id = str(data.get("order_id", data.get("orderId", ""))).strip()
    if not order_id:
        return jsonify({"ok": False, "message": "order_id is required"}), 400

    scenario = str(data.get("mode", scenario)).strip().lower() or "success"
    if scenario in {"fail", "error"}:
        return jsonify({"ok": False, "payment_status": "failed", "message": "mock payment failed"}), 402
    if scenario in {"rate_limit", "rate-limited"}:
        return jsonify({"ok": False, "payment_status": "failed", "message": "mock payment rate limited"}), 429
    if scenario == "timeout":
        time.sleep(min(30, max(1, int(os.getenv("MOCK_TIMEOUT_DELAY", "6")))))
        return jsonify({"ok": False, "payment_status": "timeout", "message": "mock payment timeout"}), 504
    if scenario == "invalid":
        return jsonify({"success": True, "message": "invalid mock response"}), 200

    with state_lock:
        existing = payments.get(order_id)
        if existing:
            return jsonify({"ok": True, **existing, "idempotent": True})
        timestamp = int(time.time())
        transaction = "MOCK" + str(timestamp) + hashlib.sha256(
            f"{order_id}:{timestamp}:{secrets.token_hex(4)}".encode("utf-8")
        ).hexdigest()[:12].upper()
        record = {
            "order_id": order_id,
            "amount": str(data.get("amount", "0.00")),
            "paytype": str(data.get("paytype", "")),
            "payment_status": "success",
            "transaction_id": transaction,
            "paid_at": timestamp,
        }
        payments[order_id] = record
    return jsonify({"ok": True, **record, "idempotent": False})


@app.post("/mock/payment/pay")
def payment_pay():
    return _payment_pay("success")


@app.post("/mock/payment/pay/<scenario>")
def payment_pay_scenario(scenario: str):
    return _payment_pay(scenario)


@app.get("/mock/payment/status")
def payment_status():
    order_id = request.args.get("order_id", request.args.get("orderId", "")).strip()
    with state_lock:
        record = dict(payments.get(order_id, {}))
    if not record:
        return jsonify({"ok": False, "message": "payment not found"}), 404
    return jsonify({"ok": True, **record})


@app.post("/mock/payment/reset")
def payment_reset():
    with state_lock:
        payments.clear()
    return jsonify({"ok": True})


if __name__ == "__main__":
    app.run(
        host=os.getenv("MOCK_HOST", "127.0.0.1"),
        port=int(os.getenv("MOCK_PORT", "5055")),
        debug=False,
    )
