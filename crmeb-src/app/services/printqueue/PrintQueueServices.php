<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：排单队列服务
// +----------------------------------------------------------------------

namespace app\services\printqueue;

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
        $deviceId = (int)Db::name('print_device')->where('status', 1)->where('is_del', 0)->value('id');
        if (!$deviceId) {
            $deviceId = 1;
        }
        $queueNo = (int)Db::name('print_queue')->where('is_del', 0)->max('queue_no') + 1;
        $now = time();
        $res = Db::name('print_queue')->insert([
            'order_id' => (int)$orderInfo['id'],
            'device_id' => $deviceId,
            'queue_no' => $queueNo,
            'status' => 1,
            'expected_start_at' => 0,
            'expected_end_at' => 0,
            'add_time' => $now,
            'update_time' => $now,
        ]);
        if ($res) {
            Db::name('store_order')->where('id', (int)$orderInfo['id'])->update(['queue_status' => 1]);
            $this->recalcQueue($deviceId);
        }
        return (bool)$res;
    }

    /**
     * 重算设备队列的预计开始/交付时间
     * @param int $deviceId
     * @return void
     */
    public function recalcQueue(int $deviceId): void
    {
        $device = Db::name('print_device')->where('id', $deviceId)->where('is_del', 0)->find();
        if (!$device) {
            return;
        }
        $now = time();
        // 锚点：制作中/已完成队列的最后结束时间（若无则从当前时间开始）
        $anchor = (int)Db::name('print_queue')
            ->where('device_id', $deviceId)
            ->whereIn('status', [self::STATUS_PRINTING, self::STATUS_DONE])
            ->where('is_del', 0)
            ->max('expected_end_at');
        $base = max($now, $anchor);
        $queueList = Db::name('print_queue')
            ->where('device_id', $deviceId)
            ->where('status', self::STATUS_WAIT)
            ->where('is_del', 0)
            ->order('queue_no asc')
            ->select()
            ->toArray();
        foreach ($queueList as $item) {
            $order = Db::name('store_order')->where('id', (int)$item['order_id'])->find();
            $totalMinutes = $this->computeMinutes(
                (string)($order['size_level'] ?? ''),
                (string)($order['material'] ?? ''),
                (int)$device['setup_minutes']
            );
            $start = $this->nextBusinessStart(
                $base,
                (string)$device['business_start'],
                (string)$device['business_end']
            );
            $end = $start + $totalMinutes * 60;
            Db::name('print_queue')->where('id', (int)$item['id'])->update([
                'expected_start_at' => $start,
                'expected_end_at' => $end,
                'update_time' => $now,
            ]);
            Db::name('store_order')->where('id', (int)$item['order_id'])->update([
                'expected_start_at' => $start,
                'expected_deliver_at' => $end,
            ]);
            $base = $end;
        }
    }

    /**
     * 计算单笔订单占机时长（打印+调试），单位：分钟
     * @param string $sizeLevel
     * @param string $material
     * @param int $setupMinutes
     * @return int
     */
    protected function computeMinutes(string $sizeLevel, string $material, int $setupMinutes): int
    {
        $sizeVolumes = [
            'S' => (float)sys_config('print_size_s', 100),
            'M' => (float)sys_config('print_size_m', 500),
            'L' => (float)sys_config('print_size_l', 2000),
            'XL' => (float)sys_config('print_size_xl', 4000),
        ];
        $speeds = [
            'PLA' => (float)sys_config('print_speed_pla', 21),
            'PETG' => (float)sys_config('print_speed_petg', 15),
        ];
        $volume = $sizeVolumes[strtoupper($sizeLevel)] ?? 100;
        $speed = $speeds[strtoupper($material)] ?? 21;
        $fillRatio = (float)sys_config('print_fill_ratio', 0.2);
        $efficiency = (float)sys_config('print_efficiency', 0.6);
        $materialVolume = $volume * $fillRatio;
        $flowCm3PerMin = $speed * $efficiency * 60 / 1000;
        $printMinutes = $flowCm3PerMin > 0 ? (int)ceil($materialVolume / $flowCm3PerMin) : 0;
        return $printMinutes + $setupMinutes;
    }

    /**
     * 计算营业时段内的下一个可开始时间（跨天顺延次日营业开始）
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
