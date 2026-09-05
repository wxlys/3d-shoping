<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：排单队列服务
// +----------------------------------------------------------------------

namespace app\services\printqueue;

use app\services\print3d\PrintNoticeServices;
use think\facade\Db;

/**
 * 打印排单队列服务
 * Class PrintQueueServices
 * @package app\services\printqueue
 */
class PrintQueueServices
{
    // 队列状态
    const STATUS_WAIT = 1;    // 排队中
    const STATUS_PRINTING = 2; // 制作中
    const STATUS_DONE = 3;    // 已完成
    const STATUS_CANCEL = 4;  // 已取消

    /**
     * 定制订单支付成功后入队
     * @param array $orderInfo
     * @return bool
     */
    public function enqueue(array $orderInfo): bool
    {
        if ((int)($orderInfo['is_print'] ?? 0) !== 1) {
            return false;
        }

        // 支付回调可能重试，已有排单时直接视为入队成功，避免唯一索引报重复错误。
        $existing = Db::name('print_queue')->where('order_id', (int)$orderInfo['id'])->where('is_del', 0)->find();
        if ($existing) {
            return true;
        }
        $deviceId = (int)Db::name('print_device')->where('status', 1)->where('is_del', 0)->value('id');
        if (!$deviceId) {
            $deviceId = 1;
        }
        $queueNo = (int)Db::name('print_queue')->where('is_del', 0)->max('queue_no') + 1;
        $now = time();
        $expectedDeliverAt = $this->getManualExpectedDeliverAt($orderInfo);
        $res = Db::name('print_queue')->insert([
            'order_id' => (int)$orderInfo['id'],
            'device_id' => $deviceId,
            'queue_no' => $queueNo,
            'status' => 1,
            'expected_start_at' => 0,
            'expected_end_at' => $expectedDeliverAt,
            'add_time' => $now,
            'update_time' => $now,
        ]);
        if ($res) {
            $orderUpdate = ['queue_status' => 1];
            if ($expectedDeliverAt > 0) {
                $orderUpdate['expected_deliver_at'] = $expectedDeliverAt;
            }
            Db::name('store_order')->where('id', (int)$orderInfo['id'])->update($orderUpdate);
            $this->recalcQueue($deviceId);
            $this->sendOrderNotice((int)$orderInfo['id'], '定制订单已进入排队', '你的定制打印订单已付款并进入打印队列，可在订单详情查看预计时间。');
        }
        return (bool)$res;
    }

    /**
     * 同步设备队列中的手动预计交付时间。
     *
     * 排单仍按支付时间维护队列序号和排位，但不再根据尺寸、材料、体积
     * 或设备调试时长计算交付时间。交付时间以管理员报价时填写的询价单
     * 时间为唯一来源，避免入队、开始打印、完成或取消后被自动覆盖。
     *
     * @param int $deviceId
     * @return void
     */
    public function recalcQueue(int $deviceId, int $fromQueueNo = 0, int $baseOverride = 0): void
    {
        $device = Db::name('print_device')->where('id', $deviceId)->where('is_del', 0)->find();
        if (!$device) {
            return;
        }
        $now = time();
        // 开始时间仍作为排单参考展示，但不再用于推导预计交付时间。
        $anchor = (int)Db::name('print_queue')
            ->where('device_id', $deviceId)
            ->whereIn('status', [self::STATUS_PRINTING, self::STATUS_DONE])
            ->where('is_del', 0)
            ->max('expected_end_at');
        $base = max($now, $anchor);
        if ($fromQueueNo > 0 && $baseOverride > 0) {
            $base = $baseOverride;
        }
        $queueList = Db::name('print_queue')
            ->where('device_id', $deviceId)
            ->where('status', self::STATUS_WAIT)
            ->where('is_del', 0)
            ->when($fromQueueNo > 0, function ($query) use ($fromQueueNo) {
                $query->where('queue_no', '>', $fromQueueNo);
            })
            ->order('queue_no asc')
            ->select()
            ->toArray();
        foreach ($queueList as $item) {
            $order = Db::name('store_order')->where('id', (int)$item['order_id'])->find();
            if (!$order || (int)($order['is_print'] ?? 0) !== 1) {
                continue;
            }
            $expectedDeliverAt = $this->getManualExpectedDeliverAt($order);
            if ($expectedDeliverAt <= 0) {
                continue;
            }
            $start = $this->nextBusinessStart(
                $base,
                (string)$device['business_start'],
                (string)$device['business_end']
            );
            Db::name('print_queue')->where('id', (int)$item['id'])->update([
                'expected_start_at' => $start,
                'expected_end_at' => $expectedDeliverAt,
                'update_time' => $now,
            ]);
            Db::name('store_order')->where('id', (int)$item['order_id'])->update([
                'expected_start_at' => $start,
                'expected_deliver_at' => $expectedDeliverAt,
            ]);
            $base = max($start, $expectedDeliverAt);
        }
    }

    /**
     * 开始打印：排队中 -> 制作中
     * @param int $orderId
     * @return bool
     */
    public function startPrint(int $orderId): bool
    {
        $queue = Db::name('print_queue')->where('order_id', $orderId)->where('is_del', 0)->find();
        if (!$queue || (int)$queue['status'] !== self::STATUS_WAIT) {
            return false;
        }
        $order = Db::name('store_order')->where('id', $orderId)->find();
        if (!$order || (int)$order['paid'] !== 1 || (int)$order['is_print'] !== 1
            || (int)$order['queue_status'] !== self::STATUS_WAIT || (int)$order['refund_status'] !== 0) {
            return false;
        }
        Db::name('print_queue')->where('id', (int)$queue['id'])->update([
            'status' => self::STATUS_PRINTING,
            'actual_start_at' => time(),
            'update_time' => time(),
        ]);
        Db::name('store_order')->where('id', $orderId)->update(['queue_status' => self::STATUS_PRINTING]);
        $this->sendOrderNotice($orderId, '定制订单开始制作', '你的定制打印订单已开始制作，请留意后续进度。');
        return true;
    }

    /**
     * 打印完成：制作中 -> 待取（生成取件码、记录取件开始时间）
     * @param int $orderId
     * @return bool
     */
    public function completePrint(int $orderId): bool
    {
        $queue = Db::name('print_queue')->where('order_id', $orderId)->where('is_del', 0)->find();
        if (!$queue || (int)$queue['status'] !== self::STATUS_PRINTING) {
            return false;
        }
        $order = Db::name('store_order')->where('id', $orderId)->find();
        if (!$order || (int)($order['is_print'] ?? 0) !== 1
            || (int)($order['paid'] ?? 0) !== 1
            || (int)($order['queue_status'] ?? 0) !== self::STATUS_PRINTING
            || (int)($order['refund_status'] ?? 0) !== 0) {
            return false;
        }
        $now = time();
        $verifyCode = (string)($order['verify_code'] ?? '');
        if ($verifyCode === '') {
            $verifyCode = $this->generateVerifyCode();
        }
        Db::name('print_queue')->where('id', (int)$queue['id'])->update([
            'status' => self::STATUS_DONE,
            'actual_end_at' => $now,
            'update_time' => $now,
        ]);
        Db::name('store_order')->where('id', $orderId)->update([
            'queue_status' => self::STATUS_DONE,
            'status' => 1,
            'pickup_at' => $now,
            'verify_code' => $verifyCode,
        ]);
        $this->recalcQueue((int)$queue['device_id']);
        $this->sendOrderNotice($orderId, '定制订单待取件', '你的定制打印已完成，取件码：' . $verifyCode . '，请到店取件。');
        return true;
    }

    /**
     * 管理员调整排期（仅排队中订单），并重算后续队列
     * @param int $orderId
     * @param int $expectedStartAt
     * @param int $adjustedBy
     * @param int $expectedDeliverAt 管理员手动填写的预计交付时间，可选
     * @return bool
     */
    public function adjustSchedule(int $orderId, int $expectedStartAt, int $adjustedBy = 0, int $expectedDeliverAt = 0): bool
    {
        if ($expectedStartAt <= time()) {
            return false;
        }
        $queue = Db::name('print_queue')->where('order_id', $orderId)->where('is_del', 0)->find();
        if (!$queue || (int)$queue['status'] !== self::STATUS_WAIT) {
            return false;
        }
        $order = Db::name('store_order')->where('id', $orderId)->find();
        if (!$order || (int)($order['is_print'] ?? 0) !== 1) {
            return false;
        }
        $oldExpectedStartAt = (int)($order['expected_start_at'] ?? 0) ?: (int)($queue['expected_start_at'] ?? 0);
        $oldExpectedDeliverAt = $this->getManualExpectedDeliverAt($order);
        // 页面会回传当前交付时间：只有值被改动时才视为手动覆盖，否则按开始时间的位移同步交付时间。
        if ($expectedDeliverAt > 0 && $expectedDeliverAt !== $oldExpectedDeliverAt) {
            $nextExpectedDeliverAt = $expectedDeliverAt;
        } elseif ($oldExpectedStartAt > 0 && $oldExpectedDeliverAt > $oldExpectedStartAt) {
            $nextExpectedDeliverAt = $oldExpectedDeliverAt + ($expectedStartAt - $oldExpectedStartAt);
        } else {
            $nextExpectedDeliverAt = max($oldExpectedDeliverAt, $expectedStartAt + 3600);
        }
        if ($nextExpectedDeliverAt <= $expectedStartAt) {
            return false;
        }
        $now = time();
        if ((int)($order['inquiry_id'] ?? 0) > 0) {
            Db::name('inquiry')->where('id', (int)$order['inquiry_id'])->where('is_del', 0)->update([
                'quote_expected_deliver_at' => $nextExpectedDeliverAt,
                'update_time' => $now,
            ]);
        }
        Db::name('print_queue')->where('id', (int)$queue['id'])->update([
            'expected_start_at' => $expectedStartAt,
            'expected_end_at' => $nextExpectedDeliverAt,
            'adjusted_by' => $adjustedBy,
            'adjusted_at' => time(),
            'update_time' => $now,
        ]);
        Db::name('store_order')->where('id', $orderId)->update([
            'expected_start_at' => $expectedStartAt,
            'expected_deliver_at' => $nextExpectedDeliverAt,
        ]);
        $this->recalcQueue((int)$queue['device_id'], (int)$queue['queue_no'], $nextExpectedDeliverAt);
        $this->sendOrderNotice($orderId, '定制订单排期已调整', '你的定制打印预计开始时间和交付时间已更新，请在订单详情查看最新排期。');
        return true;
    }

    /**
     * 更新打印进度备注
     * @param int $orderId
     * @param string $note
     * @return bool
     */
    public function updateProgress(int $orderId, string $note): bool
    {
        $order = Db::name('store_order')->where('id', $orderId)->field('id,is_print')->find();
        if (!$order || (int)($order['is_print'] ?? 0) !== 1) {
            return false;
        }
        Db::name('store_order')->where('id', $orderId)->update(['progress_note' => $note]);
        $this->sendOrderNotice($orderId, '定制订单进度更新', $note !== '' ? $note : '你的定制打印进度已更新。');
        return true;
    }

    /**
     * 取消排单（退款/取消时调用），并重算后续队列
     * @param int $orderId
     * @return bool
     */
    public function cancelQueue(int $orderId): bool
    {
        $queue = Db::name('print_queue')->where('order_id', $orderId)->where('is_del', 0)->find();
        if (!$queue) {
            return false;
        }
        $order = Db::name('store_order')->where('id', $orderId)->field('id,is_print')->find();
        if (!$order || (int)($order['is_print'] ?? 0) !== 1) {
            return false;
        }
        $deviceId = (int)$queue['device_id'];
        Db::name('print_queue')->where('id', (int)$queue['id'])->update([
            'status' => self::STATUS_CANCEL,
            'update_time' => time(),
        ]);
        Db::name('store_order')->where('id', $orderId)->update(['queue_status' => self::STATUS_CANCEL]);
        $this->recalcQueue($deviceId);
        return true;
    }

    /**
     * 自动完成：收货后待评价满 N 天仍未评价则自动完成。
     *
     * 定制订单的用户确认收货和后台取件码核销都会先进入 status=2（待评价），
     * 收货时间以订单状态表中的 take_delivery 记录为准，不能使用 pickup_at，
     * 因为 pickup_at 代表打印完成进入待取，而不是用户实际收货时间。
     *
     * @return int 处理订单数
     */
    public function autoReceipt(): int
    {
        $days = (int)sys_config('auto_receipt_days', 7);
        if ($days <= 0) {
            return 0;
        }
        $timeoutSeconds = $days * 86400;
        $now = time();
        $orders = Db::name('store_order')
            ->where('paid', 1)
            ->where('status', 2)
            ->where('is_print', 1)
            ->where('queue_status', self::STATUS_DONE)
            ->where('refund_status', 0)
            ->where('is_del', 0)
            ->field('id,order_id')
            ->select()
            ->toArray();
        if (!$orders) {
            return 0;
        }

        $completed = 0;
        foreach ($orders as $order) {
            $receivedAt = (int)Db::name('store_order_status')
                ->where('oid', (int)$order['id'])
                ->where('change_type', 'take_delivery')
                ->order('change_time desc')
                ->value('change_time');
            if ($receivedAt <= 0 || $this->getEvaluationElapsedSeconds((int)$order['id'], $receivedAt, $now) < $timeoutSeconds) {
                continue;
            }

            $updated = Db::name('store_order')
                ->where('id', (int)$order['id'])
                ->where('status', 2)
                ->where('refund_status', 0)
                ->update(['status' => 3]);
            if (!$updated) {
                continue;
            }

            Db::name('store_order_status')->insert([
                'oid' => (int)$order['id'],
                'change_type' => 'check_order_over',
                'change_message' => '评价超时自动完成',
                'change_time' => time(),
            ]);
            $this->sendOrderNotice((int)$order['id'], '定制订单已完成', '评价期限已到，订单已自动完成。');
            $completed++;
        }
        return $completed;
    }

    /**
     * 计算待评价的有效计时秒数，扣除退款审核期间。
     *
     * 退款申请期间订单仍停留在待评价，但这段时间不应消耗评价期限。
     * 退款表保存申请和处理时间；用户取消退款时则以订单状态记录中的
     * cancel_refund_order 作为暂停区间的结束时间。
     */
    protected function getEvaluationElapsedSeconds(int $orderId, int $receivedAt, int $now): int
    {
        $elapsed = max(0, $now - $receivedAt);
        $refunds = Db::name('store_order_refund')
            ->where('store_order_id', $orderId)
            ->where('is_del', 0)
            ->field('refund_type,refunded_time,is_cancel,add_time')
            ->select()
            ->toArray();
        if (!$refunds) {
            return $elapsed;
        }

        foreach ($refunds as $refund) {
            $startedAt = max($receivedAt, (int)($refund['add_time'] ?? 0));
            if ($startedAt <= 0 || $startedAt >= $now) {
                continue;
            }

            $endedAt = (int)($refund['refunded_time'] ?? 0);
            if ((int)($refund['is_cancel'] ?? 0) === 1) {
                $endedAt = (int)Db::name('store_order_status')
                    ->where('oid', $orderId)
                    ->where('change_type', 'cancel_refund_order')
                    ->where('change_time', '>=', $startedAt)
                    ->where('change_time', '<=', $now)
                    ->order('change_time asc')
                    ->value('change_time');
            } elseif (in_array((int)($refund['refund_type'] ?? 0), [1, 2, 4, 5], true) && $endedAt <= 0) {
                // 当前订单通常会被上面的 refund_status=0 条件排除；保留该分支，
                // 防止数据短暂不一致时把仍在审核的退款计入待评价时间。
                $endedAt = $now;
            }

            if ($endedAt > $startedAt) {
                $elapsed -= min($endedAt, $now) - $startedAt;
            }
        }

        return max(0, $elapsed);
    }

    protected function sendOrderNotice(int $orderId, string $title, string $content): void
    {
        $order = Db::name('store_order')->where('id', $orderId)->field('uid,order_id')->find();
        if (!$order) {
            return;
        }
        app()->make(PrintNoticeServices::class)->send(
            (int)$order['uid'],
            $title,
            $content . '（订单号：' . $order['order_id'] . '）',
            ['order_id' => (string)$order['order_id']]
        );
    }

    /**
     * 获取管理员在询价阶段填写的预计交付时间。
     *
     * 询价单字段优先，兼容历史订单没有询价关联时已保存的订单字段。
     *
     * @param array $order
     * @return int
     */
    protected function getManualExpectedDeliverAt(array $order): int
    {
        $inquiryId = (int)($order['inquiry_id'] ?? 0);
        if ($inquiryId > 0) {
            $expectedDeliverAt = (int)Db::name('inquiry')
                ->where('id', $inquiryId)
                ->where('is_del', 0)
                ->value('quote_expected_deliver_at');
            if ($expectedDeliverAt > 0) {
                return $expectedDeliverAt;
            }
        }
        return (int)($order['expected_deliver_at'] ?? 0);
    }

    /**
     * 计算营业时段内的下一个可开始时间（仅用于排单参考展示）。
     * @param int $from
     * @param string $businessStart
     * @param string $businessEnd
     * @return int
     */
    protected function nextBusinessStart(int $from, string $businessStart, string $businessEnd): int
    {
        $open = strtotime(date('Y-m-d', $from) . ' ' . $businessStart);
        $close = strtotime(date('Y-m-d', $from) . ' ' . $businessEnd);
        if ($from >= $close) {
            $open = strtotime('+1 day', $open);
        }
        return max($from, $open);
    }

    /**
     * 生成6位数字取件码（唯一）
     * @return string
     */
    public function generateVerifyCode(): string
    {
        do {
            $code = str_pad((string)mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $exists = Db::name('store_order')->where('verify_code', $code)->count();
        } while ($exists > 0);
        return $code;
    }
}
