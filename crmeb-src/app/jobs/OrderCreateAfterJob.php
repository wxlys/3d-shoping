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


use app\services\order\StoreOrderCartInfoServices;
use app\services\order\StoreOrderCreateServices;
use crmeb\basic\BaseJobs;
use crmeb\traits\QueueTrait;
use think\facade\Log;

class OrderCreateAfterJob extends BaseJobs
{
    use QueueTrait;

    /**
     * 订单后置处理
     * @param $orderId
     * @param $cartInfo
     * @param $priceData
     * @param $order
     * @param $data
     * @return bool
     */
    public function doJob($orderInfo, $data, $activity)
    {
        $uid = (int)$orderInfo['uid'];
        $orderId = (int)$orderInfo['id'];
        try {
            $cartInfo = $data['cartInfo'] ?? [];
            $priceData = $data['priceData'] ?? [];
            $addressId = $data['addressId'] ?? 0;
            /** @var StoreOrderCreateServices $createService */
            $createService = app()->make(StoreOrderCreateServices::class);
            if ($cartInfo && $priceData) {
                /** @var StoreOrderCartInfoServices $cartServices */
                $cartServices = app()->make(StoreOrderCartInfoServices::class);
                [$cartInfo, $unusedSpreadIds] = $createService->computeOrderProductTruePrice($cartInfo, $priceData, $addressId, $uid, $orderInfo);
                $cartServices->updateCartInfo($orderId, $cartInfo);
            }
            $createService->update(['id' => $orderId], [
                'spread_uid' => 0,
                'spread_two_uid' => 0,
                'one_brokerage' => 0,
                'two_brokerage' => 0,
                'staff_brokerage' => 0,
                'agent_brokerage' => 0,
                'division_brokerage' => 0,
                'coupon_id' => 0,
                'coupon_price' => 0,
                'deduction_price' => 0,
                'use_integral' => 0,
                'gain_integral' => 0,
                'gift_price' => 0,
            ]);
        } catch (\Throwable $e) {
            Log::error('计算订单实际优惠、积分、邮费、佣金失败，原因：' . $e->getMessage());
        }

        return true;
    }
}
