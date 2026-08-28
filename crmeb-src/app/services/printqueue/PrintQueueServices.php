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
        }
        return (bool)$res;
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
