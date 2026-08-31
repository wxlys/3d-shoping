<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：后台排单接口
// +----------------------------------------------------------------------

namespace app\adminapi\controller\v1\print3d;

use app\adminapi\controller\AuthController;
use app\services\printqueue\PrintQueueServices;
use think\facade\App;
use think\facade\Db;

/**
 * 定制打印排单管理
 * Class PrintQueue
 */
class PrintQueue extends AuthController
{
    protected $services;

    public function __construct(App $app, PrintQueueServices $services)
    {
        parent::__construct($app);
        $this->services = $services;
    }

    public function lst()
    {
        $where = $this->request->getMore([
            ['status', ''],
            ['device_id', ''],
            ['order_id', ''],
            ['page', 1],
            ['limit', 20],
        ]);
        $page = max(1, (int)$where['page']);
        $limit = min(100, max(1, (int)$where['limit']));
        $query = Db::name('print_queue')->alias('q')
            ->leftJoin('store_order o', 'o.id=q.order_id')
            ->leftJoin('user u', 'u.uid=o.uid')
            ->leftJoin('print_file f', 'f.id=o.print_file_id')
            ->where('q.is_del', 0)
            ->where('o.is_del', 0)
            ->where('o.is_print', 1);
        if ($where['status'] !== '') {
            $query->where('q.status', (int)$where['status']);
        }
        if ($where['device_id'] !== '') {
            $query->where('q.device_id', (int)$where['device_id']);
        }
        if ($where['order_id'] !== '') {
            $query->whereLike('o.order_id', '%' . trim((string)$where['order_id']) . '%');
        }
        $count = (int)(clone $query)->count();
        $list = $query->field('q.id,q.order_id as order_db_id,q.device_id,q.queue_no,q.status,q.expected_start_at,q.expected_end_at,q.actual_start_at,q.actual_end_at,q.adjusted_by,q.adjusted_at,q.add_time,q.update_time,o.order_id,o.uid,o.real_name,o.user_phone,o.size_level,o.material,o.total_num,o.queue_status,o.progress_note,o.expected_start_at as order_expected_start_at,o.expected_deliver_at as order_expected_deliver_at,f.filename,u.nickname')
            ->order('q.queue_no asc')->page($page, $limit)->select()->toArray();
        foreach ($list as &$item) {
            $item = $this->formatRow($item);
        }
        return app('json')->success([
            'count' => $count,
            'list' => $list,
            'page' => $page,
            'limit' => $limit,
            'summary' => $this->summary(),
        ]);
    }

    public function start()
    {
        [$orderId] = $this->request->postMore([['order_id', 0]], true);
        if (!$orderId || !$this->services->startPrint((int)$orderId)) {
            return app('json')->fail('订单状态不允许开始打印');
        }
        return app('json')->success('已开始打印');
    }

    public function complete()
    {
        [$orderId] = $this->request->postMore([['order_id', 0]], true);
        if (!$orderId || !$this->services->completePrint((int)$orderId)) {
            return app('json')->fail('订单状态不允许完成打印');
        }
        return app('json')->success('打印完成，订单进入待取');
    }

    public function adjust()
    {
        [$orderId, $expectedStartAt] = $this->request->postMore([
            ['order_id', 0],
            ['expected_start_at', 0],
        ], true);
        if (!$orderId || (int)$expectedStartAt <= time()) {
            return app('json')->fail('排期时间必须晚于当前时间');
        }
        if (!$this->services->adjustSchedule((int)$orderId, (int)$expectedStartAt, (int)$this->adminId)) {
            return app('json')->fail('当前订单不能调整排期');
        }
        return app('json')->success('排期已调整');
    }

    public function progress()
    {
        [$orderId, $note] = $this->request->postMore([
            ['order_id', 0],
            ['progress_note', ''],
        ], true);
        if (!$orderId) {
            return app('json')->fail('参数错误');
        }
        $this->services->updateProgress((int)$orderId, trim((string)$note));
        return app('json')->success('进度备注已更新');
    }

    protected function summary(): array
    {
        $rows = Db::name('print_queue')->where('is_del', 0)->field('status,count(*) as count')->group('status')->select()->toArray();
        $summary = [1 => 0, 2 => 0, 3 => 0, 4 => 0];
        foreach ($rows as $row) {
            $summary[(int)$row['status']] = (int)$row['count'];
        }
        return $summary;
    }

    protected function formatRow(array $row): array
    {
        $status = (int)$row['status'];
        $statusName = [
            PrintQueueServices::STATUS_WAIT => '排队中',
            PrintQueueServices::STATUS_PRINTING => '制作中',
            PrintQueueServices::STATUS_DONE => '已完成',
            PrintQueueServices::STATUS_CANCEL => '已取消',
        ];
        foreach (['expected_start_at', 'expected_end_at', 'actual_start_at', 'actual_end_at', 'add_time', 'adjusted_at'] as $field) {
            $row[$field . '_text'] = (int)$row[$field] > 0 ? date('Y-m-d H:i:s', (int)$row[$field]) : '';
        }
        $row['status'] = $status;
        $row['status_name'] = $statusName[$status] ?? '未知状态';
        $row['order_id'] = (string)$row['order_id'];
        $row['nickname'] = (string)($row['nickname'] ?: ($row['real_name'] ?? ''));
        $row['filename'] = (string)($row['filename'] ?? '');
        $row['total_num'] = (int)($row['total_num'] ?? 0);
        return $row;
    }
}
