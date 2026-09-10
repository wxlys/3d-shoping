# 线上短信验证码与支付 Mock API

该服务作为当前系统唯一的短信验证码和支付服务使用：正常业务路由始终返回成功，不连接第三方短信或支付供应商。短信 Mock 表示“发送成功并写入 CRMEB 验证码缓存”，不会真的向手机发送短信；联调可通过受保护的查询路由取得验证码。失败、超时、限流和无效响应路由只用于后续接口异常测试。

## 启动

本地直接启动：

```bash
cd tools/sms-mock
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt  # Windows
python app.py
```

线上使用 Docker Compose 运行，监听容器内 `5055` 端口。通过 `MOCK_SHARED_TOKEN` 为 `/mock/*` 路由设置共享令牌；`/health` 不需要令牌。

## 正常业务路由

所有正常路由只返回成功，适合 PHP 线上业务调用：

```text
POST /mock/sms/send
POST /mock/payment/pay
```

请求示例：

```json
{"phone":"13800138000","type":"reset","ttl":300}
{"order_id":"order-001","amount":"12.00","paytype":"weixin"}
```

支付接口按 `order_id` 幂等；重复请求会返回同一笔 `transaction_id`，不会重复生成支付结果。

## 验证码查看与测试控制

```text
GET  /mock/sms/code?phone=13800138000
POST /mock/sms/reset
POST /mock/sms/expire    # 表单传 phone
GET  /mock/payment/status?order_id=order-001
POST /mock/payment/reset
GET  /health
```

设置 `SMS_MOCK_FIXED_CODE=123456` 可以让每次发送都返回固定验证码。所有 `/mock/*` 请求均需在 `X-Mock-Token` 请求头中传入共享令牌。

## 异常场景路由

后续接口测试可显式调用以下路由，线上正常业务不会触发：

```text
POST /mock/sms/send/fail
POST /mock/sms/send/timeout
POST /mock/sms/send/rate_limit
POST /mock/sms/send/invalid
POST /mock/payment/pay/fail
POST /mock/payment/pay/timeout
POST /mock/payment/pay/rate_limit
POST /mock/payment/pay/invalid
```

也可以向正常路由传入 `mode` 字段选择场景。`timeout` 的等待时长由 `MOCK_TIMEOUT_DELAY` 控制，默认 6 秒。
