<?php
use think\facade\Db;

require __DIR__ . '/vendor/autoload.php';
(new \think\App())->initialize();

Db::startTrans();
try {
    $now = time();
    $o1 = Db::name('store_order')->insertGetId([
        'order_id' => 'T' . $now . '1',
        'uid' => 0,
        'unique' => md5('t1' . $now),
        'add_time' => $now,
        'paid' => 1,
        'is_print' => 1,
        'size_level' => 'M',
        'material' => 'PLA',
    ]);
    $o2 = Db::name('store_order')->insertGetId([
        'order_id' => 'T' . $now . '2',
        'uid' => 0,
        'unique' => md5('t2' . $now),
        'add_time' => $now,
        'paid' => 1,
        'is_print' => 1,
        'size_level' => 'L',
        'material' => 'PETG',
    ]);
    $base = (int)Db::name('print_queue')->max('queue_no');
    $q1 = Db::name('print_queue')->insertGetId([
        'order_id' => $o1, 'device_id' => 1, 'queue_no' => $base + 1, 'status' => 1, 'add_time' => $now, 'update_time' => $now,
    ]);
    $q2 = Db::name('print_queue')->insertGetId([
        'order_id' => $o2, 'device_id' => 1, 'queue_no' => $base + 2, 'status' => 1, 'add_time' => $now, 'update_time' => $now,
    ]);
    $svc = app()->make(\app\services\printqueue\PrintQueueServices::class);
    $svc->recalcQueue(1);
    $r1 = Db::name('print_queue')->where('id', $q1)->find();
    $r2 = Db::name('print_queue')->where('id', $q2)->find();
    echo 'q1 start=' . date('Y-m-d H:i', $r1['expected_start_at']) . ' end=' . date('Y-m-d H:i', $r1['expected_end_at']) . PHP_EOL;
    echo 'q2 start=' . date('Y-m-d H:i', $r2['expected_start_at']) . ' end=' . date('Y-m-d H:i', $r2['expected_end_at']) . PHP_EOL;
    echo 'order1 deliver=' . Db::name('store_order')->where('id', $o1)->value('expected_deliver_at') . PHP_EOL;
    $ok = $r1['expected_start_at'] > 0 && $r2['expected_end_at'] > $r1['expected_end_at'];
    echo 'CHECK=' . ($ok ? 'PASS' : 'FAIL') . PHP_EOL;
    Db::rollback();
    echo 'ROLLED_BACK' . PHP_EOL;
} catch (\Throwable $e) {
    Db::rollback();
    echo 'ERR: ' . $e->getMessage() . PHP_EOL;
}
