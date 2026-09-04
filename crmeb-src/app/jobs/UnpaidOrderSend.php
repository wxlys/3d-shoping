<?php
// +----------------------------------------------------------------------
// | CRMEB [ CRMEB赋能开发者，助力企业发展 ]
// +----------------------------------------------------------------------
// | Copyright (c) 2016~2026 https://www.crmeb.com All rights reserved.
// +----------------------------------------------------------------------
// | Licensed CRMEB并不是自由软件，未经许可不能去掉CRMEB相关版权
// +----------------------------------------------------------------------
// | Author: CRMEB Team <admin@crmeb.com>
// +----------------------------------------------------------------------

namespace app\jobs;


use app\services\order\StoreOrderServices;
use app\services\print3d\PrintNoticeServices;
use crmeb\basic\BaseJobs;
use crmeb\traits\QueueTrait;

/**
 * 未支付10分钟后发送短信
 * Class UnpaidOrderSend
 * @package crmeb\jobs
 */
class UnpaidOrderSend extends BaseJobs
{
    use QueueTrait;

    public function doJob($id)
    {
        /** @var StoreOrderServices $services */
        $services = app()->make(StoreOrderServices::class);
        $orderInfo = $services->get($id);
        if (!$orderInfo) {
            return true;
        }
        if ($orderInfo->paid) {
            return true;
        }
        if ($orderInfo->is_del) {
            return true;
        }
        //收货给用户发送消息
        event('NoticeListener', [['order' => $orderInfo], 'order_pay_false']);
        if ((int)($orderInfo->is_print ?? 0) === 1) {
            app()->make(PrintNoticeServices::class)->send(
                (int)$orderInfo->uid,
                '定制订单待支付提醒',
                '定制订单' . $orderInfo->order_id . '尚未完成支付，请及时支付，超时后订单将自动取消。',
                ['order_id' => (string)$orderInfo->order_id]
            );
        }
        return true;
    }

}
