<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：后台询价管理接口
// +----------------------------------------------------------------------

namespace app\adminapi\controller\v1\print3d;

use app\adminapi\controller\AuthController;
use app\services\print3d\PrintInquiryServices;
use think\facade\App;

/**
 * 定制打印询价管理
 * Class Inquiry
 */
class Inquiry extends AuthController
{
    protected $services;

    public function __construct(App $app, PrintInquiryServices $services)
    {
        parent::__construct($app);
        $this->services = $services;
    }

    public function lst()
    {
        $where = $this->request->getMore([
            ['status', ''],
            ['keyword', ''],
            ['page', 1],
            ['limit', 20],
        ]);
        return app('json')->success($this->services->getAdminList($where));
    }

    public function info($id)
    {
        return app('json')->success($this->services->getAdminDetail((int)$id));
    }

    public function quote($id)
    {
        [$amount, $expectedDeliverAt] = $this->request->postMore([
            ['quote_amount', ''],
            ['quote_expected_deliver_at', 0],
        ], true);
        return app('json')->success('报价已保存', $this->services->quote((int)$id, $amount, $expectedDeliverAt, (int)$this->adminId));
    }

    public function expire($id)
    {
        $this->services->expire((int)$id);
        return app('json')->success('报价已作废');
    }
}
