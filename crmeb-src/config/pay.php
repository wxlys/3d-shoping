<?php
// +----------------------------------------------------------------------
// | CRMEB [ CRMEB赋能开发者，助力企业发展 ]
// +----------------------------------------------------------------------

use think\facade\Env;
// | Copyright (c) 2016~2026 https://www.crmeb.com All rights reserved.
// +----------------------------------------------------------------------
// | Licensed CRMEB并不是自由软件，未经许可不能去掉CRMEB相关版权
// +----------------------------------------------------------------------
// | Author: CRMEB Team <admin@crmeb.com>
// +----------------------------------------------------------------------

return [
    //默认支付模式
    'default' => 'wechat_pay',
    //支付方式
    'payType' => ['weixin' => '微信支付', 'yue' => '余额支付', 'offline' => '线下支付'],
    //提现方式
    'extractType' => ['alipay', 'bank', 'weixin'],
    //配送方式
    'deliveryType' => ['send' => '商家配送', 'express' => '快递配送'],
    // 当前系统支付服务。线上由统一 Flask 服务提供成功响应，异常路由仅供接口测试。
    'mock' => [
        'enabled' => filter_var(Env::get('pay.mock.enabled', Env::get('PAY_MOCK_ENABLED', false)), FILTER_VALIDATE_BOOLEAN),
        'url' => rtrim((string)Env::get('pay.mock.url', Env::get('PAY_MOCK_URL', 'http://127.0.0.1:5055')), '/'),
        'timeout' => (int)Env::get('pay.mock.timeout', Env::get('PAY_MOCK_TIMEOUT', 5)),
        'token' => (string)Env::get('pay.mock.token', Env::get('PAY_MOCK_TOKEN', Env::get('MOCK_SHARED_TOKEN', ''))),
    ],
    //驱动模式
    'stores' => [
        //微信支付
        'wechat_pay' => [],
        //支付宝支付
        'ali_pay' => [],
        //余额支付
        'yue' => [],
    ]
];
