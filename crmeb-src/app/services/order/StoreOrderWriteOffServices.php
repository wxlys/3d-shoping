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

namespace app\services\order;


use app\dao\order\StoreOrderDao;
use app\services\activity\combination\StorePinkServices;
use app\services\BaseServices;
use app\services\system\store\SystemStoreStaffServices;
use app\services\user\UserServices;
use app\services\printqueue\PrintQueueServices;
use crmeb\exceptions\ApiException;

/**
 * 核销订单
 * Class StoreOrderWriteOffServices
 * @package app\sservices\order
 */
class StoreOrderWriteOffServices extends BaseServices
{

    /**
     * 构造方法
     * StoreOrderWriteOffServices constructor.
     * @param StoreOrderDao $dao
     */
    public function __construct(StoreOrderDao $dao)
    {
        $this->dao = $dao;
    }

    /**
     * 订单核销
     * @param string $code
     * @param int $confirm
     * @param int $uid
     * @return mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     */
    public function writeOffOrder(string $code, int $confirm, int $uid = 0, $auth = 0)
    {
        $orderInfo = $this->dao->getOne([
            ['verify_code', '=', $code],
            ['paid', '=', 1],
            ['refund_status', '=', 0],
            ['is_del', '=', 0],
            ['pid', '>=', 0]
        ]);
        if (!$orderInfo) {
            throw new ApiException('订单不存在');
        }
        $isPrintOrder = (int)($orderInfo['is_print'] ?? 0) === 1;
        if ($isPrintOrder) {
            if ((int)$orderInfo['queue_status'] !== PrintQueueServices::STATUS_DONE
                || (int)$orderInfo['status'] !== 1) {
                throw new ApiException('打印订单尚未进入待取件状态');
            }
        } elseif (($orderInfo['status'] > 0 && $orderInfo->shipping_type == 2) || ($orderInfo['status'] > 1 && $orderInfo->delivery_type == 'send')) {
            throw new ApiException('该订单已被核销');
        }
        if (!$orderInfo['verify_code'] || ($orderInfo->shipping_type != 2 && $orderInfo->delivery_type != 'send')) {
            throw new ApiException('此订单不能被核销');
        }
        /** @var StoreOrderRefundServices $storeOrderRefundServices */
        $storeOrderRefundServices = app()->make(StoreOrderRefundServices::class);
        if ($storeOrderRefundServices->count(['store_order_id' => $orderInfo['id'], 'refund_type' => [1, 2, 4, 5], 'is_cancel' => 0, 'is_del' => 0])) {
            throw new ApiException('订单有售后申请请先处理');
        }
        if ($uid) {
            $isAuth = true;
            switch ($orderInfo['shipping_type']) {
                case 1://配送订单
                    /** @var DeliveryServiceServices $deliverServiceServices */
                    $deliverServiceServices = app()->make(DeliveryServiceServices::class);
                    $isAuth = $deliverServiceServices->getCount(['uid' => $uid, 'status' => 1]) > 0;
                    break;
                case 2://自提订单
                    /** @var SystemStoreStaffServices $storeStaffServices */
                    $storeStaffServices = app()->make(SystemStoreStaffServices::class);
                    $staffInfo = $storeStaffServices->get(['uid' => $uid, 'verify_status' => 1, 'status' => 1]);
                    if ($staffInfo) {
                        $isAuth = true;
                        $orderInfo->store_id = $staffInfo->store_id;
                    } else {
                        $isAuth = false;
                    }
                    break;
            }
            if (!$isAuth && $auth == 0) {
                throw new ApiException('您无权限核销此订单，请联系管理员');
            }
        }
        if ($orderInfo->status == 2) {
            throw new ApiException('订单已核销');
        }
        /** @var StoreOrderCartInfoServices $orderCartInfo */
        $orderCartInfo = app()->make(StoreOrderCartInfoServices::class);
        // 普通订单的 cart_id 可能是数组/JSON，定制打印订单则使用 print_询价单ID 字符串。
        // 核销只需要商品图片时，统一解析首个有效 cart_id，并兼容空商品信息。
        $cartId = $orderInfo['cart_id'] ?? '';
        if (is_string($cartId)) {
            $decodedCartIds = json_decode($cartId, true);
            $cartId = is_array($decodedCartIds) ? reset($decodedCartIds) : $cartId;
        } elseif (is_array($cartId)) {
            $cartId = reset($cartId);
        }
        if ($cartId) {
            $cartInfo = $orderCartInfo->getOne([
                ['cart_id', '=', $cartId]
            ], 'cart_info');
            $cartData = $cartInfo ? ($cartInfo['cart_info'] ?? []) : [];
            if (is_string($cartData)) $cartData = json_decode($cartData, true) ?: [];
            $orderInfo['image'] = (string)($cartData['productInfo']['image'] ?? '');
        }
        if (!$isPrintOrder && $orderInfo->shipping_type == 2) {
            if ($orderInfo->status > 0) {
                throw new ApiException('订单已核销');
            }
        }
        if ($orderInfo->combination_id && $orderInfo->pink_id) {
            /** @var StorePinkServices $services */
            $services = app()->make(StorePinkServices::class);
            $res = $services->getCount([['id', '=', $orderInfo->pink_id], ['status', '<>', 2]]);
            if ($res) throw new ApiException('拼团订单暂未成功无法核销');
        }
        if ($confirm == 0) {
            /** @var UserServices $services */
            $services = app()->make(UserServices::class);
            $orderInfo['nickname'] = $services->value(['uid' => $orderInfo['uid']], 'nickname');
            return $orderInfo->toArray();
        }
        $orderInfo->status = 2;
        if ($uid) {
            if ($orderInfo->shipping_type == 2) {
                $orderInfo->clerk_id = $uid;
            }
        }
        if ($orderInfo->save()) {
            /** @var StoreOrderTakeServices $storeOrderTask */
            $storeOrderTask = app()->make(StoreOrderTakeServices::class);
            $re = $storeOrderTask->storeProductOrderUserTakeDelivery($orderInfo);
            if (!$re) {
                throw new ApiException('核销失败');
            }
            if ($orderInfo['shipping_type'] == 2) {
                event('OrderShippingListener', ['product', $orderInfo, 4, '', '']);
            }
            return $orderInfo->toArray();
        } else {
            throw new ApiException('核销失败');
        }
    }
}
