<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：模型文件与询价流程
// +----------------------------------------------------------------------

namespace app\services\print3d;

use app\Request;
use app\services\order\StoreOrderCreateServices;
use app\services\other\UploadService;
use crmeb\exceptions\ApiException;
use think\facade\Db;

/**
 * 定制打印询价服务
 *
 * 询价单的状态流转：待报价 -> 已报价 -> 已确认。
 * 报价超过有效期后会变为已过期，待报价和已报价阶段均允许用户取消。
 */
class PrintInquiryServices
{
    const FILE_VALIDATING = 1;
    const FILE_PASS = 2;
    const FILE_FAIL = 3;

    const STATUS_PENDING = 1;
    const STATUS_QUOTED = 2;
    const STATUS_CONFIRMED = 3;
    const STATUS_EXPIRED = 4;
    const STATUS_CANCEL = 5;

    protected $statusName = [
        self::STATUS_PENDING => '待报价',
        self::STATUS_QUOTED => '已报价',
        self::STATUS_CONFIRMED => '已确认',
        self::STATUS_EXPIRED => '已过期',
        self::STATUS_CANCEL => '已取消',
    ];

    protected $fileStatusName = [
        self::FILE_VALIDATING => '校验中',
        self::FILE_PASS => '已通过',
        self::FILE_FAIL => '校验失败',
    ];

    /**
     * 上传并校验模型文件。
     * @param Request $request
     * @param int $uid
     * @return array
     */
    public function uploadFile(Request $request, int $uid): array
    {
        $file = $request->file('file');
        if (!$file) {
            throw new ApiException('请上传模型文件');
        }

        $originalName = trim((string)$file->getOriginalName());
        $fileName = basename(str_replace('\\', '/', $originalName));
        $ext = strtolower((string)pathinfo($fileName, PATHINFO_EXTENSION));
        $allowedExt = $this->getAllowedExtensions();
        if (!$fileName || !$ext || !in_array($ext, $allowedExt, true)) {
            throw new ApiException('仅支持 STL、OBJ、3MF、STP、STEP 格式');
        }

        $path = $file->getPathname();
        $size = (int)@filesize($path);
        $maxMb = max(1, (int)sys_config('print_file_max_mb', 100));
        if ($size <= 0) {
            throw new ApiException('模型文件为空');
        }
        if ($size > $maxMb * 1024 * 1024) {
            throw new ApiException('模型文件不能超过' . $maxMb . 'MB');
        }

        $originalMime = strtolower((string)$file->getOriginalMime());
        $detectedMime = $this->detectMime($path);
        if (!$this->isAllowedMime($originalMime) && !$this->isAllowedMime($detectedMime)) {
            throw new ApiException('模型文件类型不受支持');
        }

        $head = (string)@file_get_contents($path, false, null, 0, 4096);
        if (!$this->isValidModelHeader($ext, $head, $size)) {
            throw new ApiException('模型文件内容校验失败，请确认文件未损坏');
        }

        $maxCount = max(1, (int)sys_config('print_file_max_count', 50));
        $usedCount = (int)Db::name('print_file')
            ->where('uid', $uid)
            ->where('is_del', 0)
            ->count();
        if ($usedCount >= $maxCount) {
            throw new ApiException('每位用户最多保存' . $maxCount . '个模型文件');
        }

        // UploadService 负责接入当前站点的本地、OSS、COS 等存储配置。
        $upload = UploadService::init();
        $uploadMimes = $this->getAllowedMimes();
        // 某些客户端会把合法模型标成自定义 MIME；前面的扩展名、内容头校验通过后，
        // 将原始 MIME 传给存储驱动，避免驱动层再次误拒绝。
        if ($originalMime && !in_array($originalMime, $uploadMimes, true) && $this->isAllowedMime($detectedMime)) {
            $uploadMimes[] = $originalMime;
        }
        $uploadInfo = $upload->to('print/model')->setAuthThumb(false)->validate([
            'filesize' => $maxMb * 1024 * 1024,
            'fileExt' => $allowedExt,
            'fileMime' => $uploadMimes,
        ])->move('file');
        if ($uploadInfo === false) {
            throw new ApiException($upload->getError() ?: '模型文件上传失败');
        }

        $info = $upload->getUploadInfo();
        $now = time();
        $id = Db::name('print_file')->insertGetId([
            'uid' => $uid,
            'inquiry_id' => 0,
            'order_id' => 0,
            'filename' => $fileName,
            'stored_name' => (string)($info['dir'] ?? ''),
            'ext' => $ext,
            'size' => $size,
            'status' => self::FILE_PASS,
            'fail_reason' => '',
            'add_time' => $now,
            'update_time' => $now,
            'is_del' => 0,
        ]);

        if (!$id) {
            throw new ApiException('模型文件记录保存失败');
        }

        return $this->formatFile([
            'id' => $id,
            'uid' => $uid,
            'filename' => $fileName,
            'stored_name' => (string)($info['dir'] ?? ''),
            'ext' => $ext,
            'size' => $size,
            'status' => self::FILE_PASS,
            'fail_reason' => '',
            'add_time' => $now,
        ]);
    }

    /**
     * 用户文件列表。
     * @param int $uid
     * @param int $page
     * @param int $limit
     * @return array
     */
    public function getFileList(int $uid, int $page = 1, int $limit = 20): array
    {
        $page = max(1, $page);
        $limit = min(100, max(1, $limit));
        $query = Db::name('print_file')->where('uid', $uid)->where('is_del', 0);
        $count = (int)(clone $query)->count();
        $list = $query->order('id desc')->page($page, $limit)->select()->toArray();
        foreach ($list as &$item) {
            $item = $this->formatFile($item);
            $item['in_use'] = (int)($item['inquiry_id'] ?? 0) > 0 || (int)($item['order_id'] ?? 0) > 0;
        }
        return compact('count', 'list', 'page', 'limit');
    }

    /**
     * 删除用户未被询价或订单引用的模型文件。
     */
    public function deleteUserFile(int $uid, int $id): bool
    {
        $file = Db::name('print_file')->where([
            'id' => $id,
            'uid' => $uid,
            'is_del' => 0,
        ])->find();
        if (!$file) {
            throw new ApiException('文件不存在');
        }
        if ((int)$file['inquiry_id'] > 0 || (int)$file['order_id'] > 0) {
            throw new ApiException('该文件已被询价或订单使用，不能删除');
        }
        $this->deleteStoredFile((string)$file['stored_name']);
        return false !== Db::name('print_file')->where('id', $id)->update([
            'is_del' => 1,
            'update_time' => time(),
        ]);
    }

    /**
     * 定时清理超过保留期且从未被业务引用的文件。
     */
    public function cleanupUnusedFiles(): int
    {
        $days = max(1, (int)sys_config('print_file_retain_days', 30));
        $files = Db::name('print_file')->where([
            'inquiry_id' => 0,
            'order_id' => 0,
            'is_del' => 0,
        ])->where('add_time', '<=', time() - $days * 86400)->select()->toArray();
        $count = 0;
        foreach ($files as $file) {
            $this->deleteStoredFile((string)$file['stored_name']);
            $count += (int)(false !== Db::name('print_file')->where('id', (int)$file['id'])->update([
                'is_del' => 1,
                'update_time' => time(),
            ]));
        }
        return $count;
    }

    protected function deleteStoredFile(string $storedName): void
    {
        if ($storedName === '') {
            return;
        }
        try {
            UploadService::init()->delete($storedName);
        } catch (\Throwable $e) {
            // 存储文件不存在时仍允许清理数据库记录，避免形成永久脏数据。
        }
    }

    /**
     * 创建询价单。
     * @param int $uid
     * @param array $data
     * @return array
     */
    public function createInquiry(int $uid, array $data): array
    {
        $fileId = (int)($data['file_id'] ?? 0);
        $sizeLevel = strtoupper(trim((string)($data['size_level'] ?? '')));
        $material = strtoupper(trim((string)($data['material'] ?? '')));
        $quantity = (int)($data['quantity'] ?? 1);
        if (!$fileId || !in_array($sizeLevel, ['S', 'M', 'L', 'XL'], true)) {
            throw new ApiException('请选择模型文件和尺寸档位');
        }
        if (!in_array($material, ['PLA', 'PETG'], true)) {
            throw new ApiException('请选择打印材料');
        }
        if ($quantity < 1 || $quantity > 100) {
            throw new ApiException('打印数量应在1-100之间');
        }

        $file = Db::name('print_file')->where([
            'id' => $fileId,
            'uid' => $uid,
            'is_del' => 0,
        ])->find();
        if (!$file) {
            throw new ApiException('模型文件不存在');
        }
        if ((int)$file['status'] !== self::FILE_PASS) {
            throw new ApiException('模型文件尚未通过校验');
        }
        if ((int)$file['inquiry_id'] > 0) {
            throw new ApiException('该模型文件已提交过询价，请重新上传文件');
        }

        $now = time();
        $inquiryNo = $this->generateInquiryNo();
        $id = Db::name('inquiry')->insertGetId([
            'inquiry_no' => $inquiryNo,
            'uid' => $uid,
            'file_id' => $fileId,
            'size_level' => $sizeLevel,
            'material' => $material,
            'quantity' => $quantity,
            'status' => self::STATUS_PENDING,
            'quote_amount' => '0.00',
            'quote_by' => 0,
            'quote_at' => 0,
            'expire_at' => 0,
            'order_id' => 0,
            'add_time' => $now,
            'update_time' => $now,
            'is_del' => 0,
        ]);
        if (!$id) {
            throw new ApiException('询价单创建失败');
        }
        Db::name('print_file')->where('id', $fileId)->update([
            'inquiry_id' => $id,
            'update_time' => $now,
        ]);
        return $this->getUserDetail($uid, $id);
    }

    /**
     * 用户询价单列表。
     * @param int $uid
     * @param array $where
     * @return array
     */
    public function getUserList(int $uid, array $where = []): array
    {
        $this->expireQuoted();
        $page = max(1, (int)($where['page'] ?? 1));
        $limit = min(100, max(1, (int)($where['limit'] ?? 20)));
        $query = Db::name('inquiry')->where('uid', $uid)->where('is_del', 0);
        if (($where['status'] ?? '') !== '') {
            $query->where('status', (int)$where['status']);
        }
        $count = (int)(clone $query)->count();
        $list = $query->order('id desc')->page($page, $limit)->select()->toArray();
        foreach ($list as &$item) {
            $file = Db::name('print_file')->where('id', (int)$item['file_id'])->find();
            $order = $item['order_id'] ? Db::name('store_order')->where('id', (int)$item['order_id'])->field('id,order_id,paid,status,pay_price,queue_status')->find() : null;
            $item = $this->formatInquiry($item, $file ?: [], [], $order ?: []);
        }
        return compact('count', 'list', 'page', 'limit');
    }

    /**
     * 用户查看询价单详情。
     * @param int $uid
     * @param int $id
     * @return array
     */
    public function getUserDetail(int $uid, int $id): array
    {
        $this->expireQuoted();
        $inquiry = Db::name('inquiry')->where([
            'id' => $id,
            'uid' => $uid,
            'is_del' => 0,
        ])->find();
        if (!$inquiry) {
            throw new ApiException('询价单不存在');
        }
        $file = Db::name('print_file')->where('id', (int)$inquiry['file_id'])->find();
        $order = $inquiry['order_id'] ? Db::name('store_order')->where('id', (int)$inquiry['order_id'])->field('id,order_id,paid,status,pay_price,queue_status')->find() : null;
        return $this->formatInquiry($inquiry, $file ?: [], [], $order ?: []);
    }

    /**
     * 用户取消待报价询价单。
     * @param int $uid
     * @param int $id
     * @return bool
     */
    public function cancelInquiry(int $uid, int $id): bool
    {
        $res = Db::name('inquiry')->where([
            'id' => $id,
            'uid' => $uid,
            'is_del' => 0,
        ])->whereIn('status', [self::STATUS_PENDING, self::STATUS_QUOTED])->update([
            'status' => self::STATUS_CANCEL,
            'update_time' => time(),
        ]);
        if (!$res) {
            throw new ApiException('当前询价单不能取消');
        }
        return true;
    }

    /**
     * 用户确认报价并生成待支付定制订单。
     * @param int $uid
     * @param int $id
     * @return array
     */
    public function confirmInquiry(int $uid, int $id): array
    {
        $this->expireQuoted();
        return Db::transaction(function () use ($uid, $id) {
            $inquiry = Db::name('inquiry')->where([
                'id' => $id,
                'uid' => $uid,
                'is_del' => 0,
            ])->lock(true)->find();
            if (!$inquiry) {
                throw new ApiException('询价单不存在');
            }
            if ((int)$inquiry['status'] === self::STATUS_CONFIRMED && (int)$inquiry['order_id'] > 0) {
                $order = Db::name('store_order')->where('id', (int)$inquiry['order_id'])->field('id,order_id,pay_price,paid')->find();
                return [
                    'inquiry_id' => $id,
                    'order_id' => (string)($order['order_id'] ?? ''),
                    'order_db_id' => (int)($order['id'] ?? 0),
                    'pay_price' => (string)($order['pay_price'] ?? $inquiry['quote_amount']),
                    'paid' => (int)($order['paid'] ?? 0),
                ];
            }
            if ((int)$inquiry['status'] !== self::STATUS_QUOTED) {
                throw new ApiException('当前询价单还不能确认报价');
            }
            if ((int)$inquiry['expire_at'] > 0 && (int)$inquiry['expire_at'] <= time()) {
                Db::name('inquiry')->where('id', $id)->update([
                    'status' => self::STATUS_EXPIRED,
                    'update_time' => time(),
                ]);
                throw new ApiException('报价已过期，请重新提交询价');
            }

            $file = Db::name('print_file')->where([
                'id' => (int)$inquiry['file_id'],
                'uid' => $uid,
                'is_del' => 0,
            ])->find();
            if (!$file || (int)$file['status'] !== self::FILE_PASS) {
                throw new ApiException('模型文件不存在或已失效');
            }
            $user = Db::name('user')->where('uid', $uid)->field('uid,nickname,real_name,phone')->find() ?: [];
            $orderNo = app()->make(StoreOrderCreateServices::class)->getNewOrderId('3d');
            $now = time();
            $quoteAmount = number_format((float)$inquiry['quote_amount'], 2, '.', '');
            $cartId = 'print_' . $id;
            $unique = md5($cartId . $orderNo . $uid);

            $orderDbId = Db::name('store_order')->insertGetId([
                'pid' => 0,
                'order_id' => $orderNo,
                'trade_no' => '',
                'uid' => $uid,
                'real_name' => (string)($user['real_name'] ?: ($user['nickname'] ?? '')),
                'user_phone' => (string)($user['phone'] ?? ''),
                'user_address' => '',
                'cart_id' => $cartId,
                'freight_price' => '0.00',
                'total_num' => (int)$inquiry['quantity'],
                'total_price' => $quoteAmount,
                'total_postage' => '0.00',
                'pay_price' => $quoteAmount,
                'pay_postage' => '0.00',
                'deduction_price' => '0.00',
                'coupon_id' => 0,
                'coupon_price' => '0.00',
                'paid' => 0,
                'pay_time' => 0,
                'pay_type' => '',
                'add_time' => $now,
                'status' => 0,
                'is_stock_up' => 0,
                'refund_status' => 0,
                'refund_type' => 0,
                'mark' => '定制打印询价 ' . $inquiry['inquiry_no'],
                'is_del' => 0,
                'is_cancel' => 0,
                'unique' => $unique,
                'remark' => '',
                'mer_id' => 0,
                'combination_id' => 0,
                'pink_id' => 0,
                'seckill_id' => 0,
                'bargain_id' => 0,
                'advance_id' => 0,
                'verify_code' => '',
                'store_id' => 0,
                'shipping_type' => 2,
                'clerk_id' => 0,
                'is_channel' => 0,
                'is_remind' => 0,
                'is_system_del' => 0,
                'channel_type' => 'h5',
                'province' => '',
                'express_dump' => '',
                'virtual_type' => 0,
                'virtual_info' => '',
                'pay_uid' => $uid,
                'custom_form' => '[]',
                'staff_id' => 0,
                'agent_id' => 0,
                'division_id' => 0,
                'is_gift' => 0,
                'gift_price' => '0.00',
                'gift_uid' => 0,
                'gift_mark' => '',
                'is_print' => 1,
                'print_file_id' => (int)$file['id'],
                'size_level' => (string)$inquiry['size_level'],
                'material' => (string)$inquiry['material'],
                'expected_start_at' => 0,
                'expected_deliver_at' => 0,
                'queue_status' => 0,
                'progress_note' => '',
                'inquiry_id' => $id,
            ]);
            if (!$orderDbId) {
                throw new ApiException('定制订单创建失败');
            }

            $cartInfo = [
                'id' => $cartId,
                'cart_num' => (int)$inquiry['quantity'],
                'surplus_num' => (int)$inquiry['quantity'],
                'refund_num' => 0,
                'truePrice' => $quoteAmount,
                'vip_truePrice' => $quoteAmount,
                'price_type' => '',
                'productInfo' => [
                    'id' => 0,
                    'store_name' => '定制打印 - ' . $inquiry['inquiry_no'],
                    'image' => '',
                    'price' => $quoteAmount,
                    'ot_price' => $quoteAmount,
                    'vip_price' => $quoteAmount,
                    'vip_truePrice' => $quoteAmount,
                    'attrInfo' => [
                        'id' => 0,
                        'product_id' => 0,
                        'suk' => $inquiry['size_level'] . ' / ' . $inquiry['material'],
                        'price' => $quoteAmount,
                        'image' => '',
                        'unique' => $unique,
                    ],
                ],
                'combination_id' => 0,
                'pink_id' => 0,
                'seckill_id' => 0,
                'bargain_id' => 0,
                'advance_id' => 0,
            ];
            Db::name('store_order_cart_info')->insert([
                'oid' => $orderDbId,
                'uid' => $uid,
                'cart_id' => $cartId,
                'product_id' => 0,
                'old_cart_id' => '',
                'cart_num' => (int)$inquiry['quantity'],
                'refund_num' => 0,
                'surplus_num' => (int)$inquiry['quantity'],
                'split_status' => 0,
                'cart_info' => json_encode($cartInfo, JSON_UNESCAPED_UNICODE),
                'unique' => $unique,
            ]);
            Db::name('inquiry')->where('id', $id)->update([
                'status' => self::STATUS_CONFIRMED,
                'order_id' => $orderDbId,
                'update_time' => $now,
            ]);
            Db::name('print_file')->where('id', (int)$file['id'])->update([
                'order_id' => $orderDbId,
                'update_time' => $now,
            ]);

            return [
                'inquiry_id' => $id,
                'order_id' => $orderNo,
                'order_db_id' => $orderDbId,
                'pay_price' => $quoteAmount,
                'paid' => 0,
            ];
        });
    }

    /**
     * 后台询价单列表。
     * @param array $where
     * @return array
     */
    public function getAdminList(array $where = []): array
    {
        $this->expireQuoted();
        $page = max(1, (int)($where['page'] ?? 1));
        $limit = min(100, max(1, (int)($where['limit'] ?? 20)));
        $query = Db::name('inquiry')->alias('i')
            ->leftJoin('print_file f', 'f.id=i.file_id')
            ->leftJoin('user u', 'u.uid=i.uid')
            ->where('i.is_del', 0);
        if (($where['status'] ?? '') !== '') {
            $query->where('i.status', (int)$where['status']);
        }
        if (!empty($where['keyword'])) {
            $keyword = '%' . trim((string)$where['keyword']) . '%';
            $query->where(function ($subQuery) use ($keyword) {
                $subQuery->whereLike('i.inquiry_no', $keyword)->whereOrLike('f.filename', $keyword);
            });
        }
        $count = (int)(clone $query)->count();
        $rows = $query->field('i.*,f.filename,f.stored_name,f.ext,f.size as file_size,f.status as file_status,f.fail_reason,u.nickname,u.phone')
            ->order('i.id desc')->page($page, $limit)->select()->toArray();
        $list = [];
        foreach ($rows as $row) {
            $list[] = $this->formatInquiry($row, [
                'id' => $row['file_id'],
                'uid' => $row['uid'],
                'filename' => $row['filename'] ?? '',
                'stored_name' => $row['stored_name'] ?? '',
                'ext' => $row['ext'] ?? '',
                'size' => $row['file_size'] ?? 0,
                'status' => $row['file_status'] ?? self::FILE_PASS,
                'fail_reason' => $row['fail_reason'] ?? '',
            ], [
                'nickname' => $row['nickname'] ?? '',
                'phone' => $row['phone'] ?? '',
            ]);
        }
        return compact('count', 'list', 'page', 'limit');
    }

    /**
     * 后台查看询价单详情。
     * @param int $id
     * @return array
     */
    public function getAdminDetail(int $id): array
    {
        $this->expireQuoted();
        $inquiry = Db::name('inquiry')->where(['id' => $id, 'is_del' => 0])->find();
        if (!$inquiry) {
            throw new ApiException('询价单不存在');
        }
        $file = Db::name('print_file')->where('id', (int)$inquiry['file_id'])->find();
        $user = Db::name('user')->where('uid', (int)$inquiry['uid'])->field('uid,nickname,real_name,phone')->find();
        $order = $inquiry['order_id'] ? Db::name('store_order')->where('id', (int)$inquiry['order_id'])->field('id,order_id,paid,status,pay_price,queue_status')->find() : null;
        return $this->formatInquiry($inquiry, $file ?: [], $user ?: [], $order ?: []);
    }

    /**
     * 后台报价。
     * @param int $id
     * @param string|float $amount
     * @param int $adminId
     * @return array
     */
    public function quote(int $id, $amount, int $adminId = 0): array
    {
        $amount = trim((string)$amount);
        if (!preg_match('/^\\d{1,10}(?:\\.\\d{1,2})?$/', $amount) || (float)$amount <= 0) {
            throw new ApiException('请输入大于0的有效报价');
        }
        $quoteAmount = number_format((float)$amount, 2, '.', '');
        $now = time();
        $hours = max(1, (int)sys_config('inquiry_expire_hours', 48));
        $res = Db::name('inquiry')->where([
            'id' => $id,
            'status' => self::STATUS_PENDING,
            'is_del' => 0,
        ])->update([
            'status' => self::STATUS_QUOTED,
            'quote_amount' => $quoteAmount,
            'quote_by' => $adminId,
            'quote_at' => $now,
            'expire_at' => $now + $hours * 3600,
            'update_time' => $now,
        ]);
        if (!$res) {
            throw new ApiException('当前询价单不能报价');
        }
        $detail = $this->getAdminDetail($id);
        app()->make(PrintNoticeServices::class)->send(
            (int)$detail['user']['uid'],
            '定制询价已报价',
            '询价单' . $detail['inquiry_no'] . '已报价 ¥' . $quoteAmount . '，请在有效期内确认。',
            ['inquiry_id' => $id]
        );
        return $detail;
    }

    /**
     * 后台手动作废报价。
     * @param int $id
     * @return bool
     */
    public function expire(int $id): bool
    {
        $res = Db::name('inquiry')->where([
            'id' => $id,
            'status' => self::STATUS_QUOTED,
            'is_del' => 0,
        ])->update([
            'status' => self::STATUS_EXPIRED,
            'update_time' => time(),
        ]);
        if (!$res) {
            throw new ApiException('当前询价单不能作废');
        }
        return true;
    }

    /**
     * 定时任务调用：将过期报价统一更新为已过期。
     * @return int
     */
    public function expireQuoted(): int
    {
        $query = Db::name('inquiry')->where([
            'status' => self::STATUS_QUOTED,
            'is_del' => 0,
        ])->where('expire_at', '>', 0)->where('expire_at', '<=', time());
        $expired = (clone $query)->field('id,uid,inquiry_no')->select()->toArray();
        if (!$expired) {
            return 0;
        }
        $count = (int)$query->update([
            'status' => self::STATUS_EXPIRED,
            'update_time' => time(),
        ]);
        foreach ($expired as $item) {
            app()->make(PrintNoticeServices::class)->send(
                (int)$item['uid'],
                '定制询价已过期',
                '询价单' . $item['inquiry_no'] . '的报价已过期，如仍需制作请重新提交询价。',
                ['inquiry_id' => (int)$item['id']]
            );
        }
        return $count;
    }

    /**
     * 获取用户自己的文件，供下载接口做权限校验。
     * @param int $uid
     * @param int $id
     * @return array
     */
    public function getUserFile(int $uid, int $id): array
    {
        $file = Db::name('print_file')->where([
            'id' => $id,
            'uid' => $uid,
            'is_del' => 0,
        ])->find();
        if (!$file) {
            throw new ApiException('文件不存在');
        }
        return $file;
    }

    /**
     * 输出一个受保护的本地下载响应；远程存储则跳转到存储地址。
     * @param array $file
     * @return mixed
     */
    public function downloadFile(array $file)
    {
        $storedName = (string)($file['stored_name'] ?? '');
        if (preg_match('/^https?:\\/\\//i', $storedName)) {
            return redirect($storedName);
        }
        $relativePath = parse_url($storedName, PHP_URL_PATH) ?: $storedName;
        $relativePath = '/' . ltrim(str_replace('\\', '/', $relativePath), '/');
        if (strpos($relativePath, '/uploads/') !== 0) {
            throw new ApiException('文件地址无效');
        }
        $publicRoot = realpath(app()->getRootPath() . 'public/uploads');
        $absolutePath = realpath(app()->getRootPath() . 'public' . $relativePath);
        if (!$publicRoot || !$absolutePath || strpos($absolutePath, $publicRoot . DIRECTORY_SEPARATOR) !== 0 || !is_file($absolutePath)) {
            throw new ApiException('文件不存在或已被清理');
        }
        return download($absolutePath, (string)($file['filename'] ?? 'model.' . ($file['ext'] ?? 'stl')));
    }

    protected function formatInquiry(array $inquiry, array $file = [], array $user = [], array $order = []): array
    {
        $status = (int)($inquiry['status'] ?? 0);
        $result = [
            'id' => (int)($inquiry['id'] ?? 0),
            'inquiry_no' => (string)($inquiry['inquiry_no'] ?? ''),
            'uid' => (int)($inquiry['uid'] ?? 0),
            'file_id' => (int)($inquiry['file_id'] ?? 0),
            'size_level' => (string)($inquiry['size_level'] ?? ''),
            'material' => (string)($inquiry['material'] ?? ''),
            'quantity' => (int)($inquiry['quantity'] ?? 0),
            'status' => $status,
            'status_name' => $this->statusName[$status] ?? '未知状态',
            'quote_amount' => number_format((float)($inquiry['quote_amount'] ?? 0), 2, '.', ''),
            'quote_by' => (int)($inquiry['quote_by'] ?? 0),
            'quote_at' => (int)($inquiry['quote_at'] ?? 0),
            'quote_at_text' => $this->formatTime($inquiry['quote_at'] ?? 0),
            'expire_at' => (int)($inquiry['expire_at'] ?? 0),
            'expire_at_text' => $this->formatTime($inquiry['expire_at'] ?? 0),
            'order_id' => (int)($inquiry['order_id'] ?? 0),
            'add_time' => (int)($inquiry['add_time'] ?? 0),
            'add_time_text' => $this->formatTime($inquiry['add_time'] ?? 0),
            'file' => $file ? $this->formatFile($file) : [],
            'user' => [
                'uid' => (int)($user['uid'] ?? $inquiry['uid'] ?? 0),
                'nickname' => (string)($user['nickname'] ?? ''),
                'real_name' => (string)($user['real_name'] ?? ''),
                'phone' => (string)($user['phone'] ?? ''),
            ],
            'order' => $order ? [
                'id' => (int)($order['id'] ?? 0),
                'order_id' => (string)($order['order_id'] ?? ''),
                'paid' => (int)($order['paid'] ?? 0),
                'status' => (int)($order['status'] ?? 0),
                'pay_price' => (string)($order['pay_price'] ?? '0.00'),
                'queue_status' => (int)($order['queue_status'] ?? 0),
            ] : [],
        ];
        return $result;
    }

    public function formatFile(array $file): array
    {
        $status = (int)($file['status'] ?? 0);
        return [
            'id' => (int)($file['id'] ?? 0),
            'uid' => (int)($file['uid'] ?? 0),
            'filename' => (string)($file['filename'] ?? ''),
            'stored_name' => (string)($file['stored_name'] ?? ''),
            'ext' => strtolower((string)($file['ext'] ?? '')),
            'size' => (int)($file['size'] ?? $file['file_size'] ?? 0),
            'size_text' => $this->formatSize((int)($file['size'] ?? $file['file_size'] ?? 0)),
            'status' => $status,
            'status_name' => $this->fileStatusName[$status] ?? '未知状态',
            'fail_reason' => (string)($file['fail_reason'] ?? ''),
            'add_time' => (int)($file['add_time'] ?? 0),
            'add_time_text' => $this->formatTime($file['add_time'] ?? 0),
            'file_url' => $this->getFileUrl((string)($file['stored_name'] ?? '')),
            'inquiry_id' => (int)($file['inquiry_id'] ?? 0),
            'order_id' => (int)($file['order_id'] ?? 0),
        ];
    }

    protected function getAllowedExtensions(): array
    {
        $configured = sys_config('print_file_extensions', 'stl,obj,3mf,stp,step');
        $extensions = is_array($configured) ? $configured : explode(',', (string)$configured);
        $extensions = array_map(function ($item) {
            return strtolower(trim((string)$item));
        }, $extensions);
        $extensions = array_values(array_filter($extensions));
        return $extensions ?: ['stl', 'obj', '3mf', 'stp', 'step'];
    }

    protected function getAllowedMimes(): array
    {
        return [
            'application/octet-stream',
            'application/zip',
            'application/x-zip-compressed',
            'application/vnd.ms-package.3dmanufacturing-3dmodel',
            'model/stl',
            'model/obj',
            'application/step',
            'application/x-step',
            'text/plain',
            'text/xml',
        ];
    }

    protected function isAllowedMime(string $mime): bool
    {
        return $mime === '' || in_array($mime, $this->getAllowedMimes(), true);
    }

    protected function detectMime(string $path): string
    {
        if (function_exists('finfo_open')) {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            if ($finfo) {
                $mime = (string)finfo_file($finfo, $path);
                finfo_close($finfo);
                return strtolower($mime);
            }
        }
        return '';
    }

    protected function isValidModelHeader(string $ext, string $head, int $size): bool
    {
        if (strpos($head, '<?php') !== false || preg_match('/<script\\b/i', $head)) {
            return false;
        }
        switch ($ext) {
            case '3mf':
                return substr($head, 0, 4) === "PK\x03\x04" || substr($head, 0, 4) === "PK\x05\x06" || substr($head, 0, 4) === "PK\x07\x08";
            case 'stp':
            case 'step':
                return (bool)preg_match('/ISO-10303-21|HEADER;/i', $head);
            case 'obj':
                return (bool)preg_match('/^\\s*(?:v|vn|vt|f|o|g|usemtl|mtllib)\\s+/m', $head);
            case 'stl':
                $ascii = (bool)preg_match('/^\\s*solid\\b/i', $head) && (bool)preg_match('/\\bfacet\\b/i', $head);
                $binary = false;
                if ($size >= 84 && strlen($head) >= 84) {
                    $unpacked = unpack('VtriangleCount', substr($head, 80, 4));
                    $triangleCount = (int)($unpacked['triangleCount'] ?? 0);
                    $binary = $triangleCount > 0 && $triangleCount <= (int)floor(($size - 84) / 50);
                }
                return $ascii || $binary;
            default:
                return false;
        }
    }

    protected function generateInquiryNo(): string
    {
        do {
            $number = 'XJ' . date('ymdHis') . mt_rand(1000, 9999);
        } while (Db::name('inquiry')->where('inquiry_no', $number)->count() > 0);
        return $number;
    }

    protected function formatTime($time): string
    {
        return (int)$time > 0 ? date('Y-m-d H:i:s', (int)$time) : '';
    }

    protected function formatSize(int $size): string
    {
        if ($size >= 1024 * 1024) {
            return number_format($size / 1024 / 1024, 2) . ' MB';
        }
        if ($size >= 1024) {
            return number_format($size / 1024, 2) . ' KB';
        }
        return $size . ' B';
    }

    protected function getFileUrl(string $path): string
    {
        if (!$path) {
            return '';
        }
        if (preg_match('/^https?:\\/\\//i', $path)) {
            return $path;
        }
        $url = function_exists('path_to_url') ? path_to_url($path) : $path;
        if (preg_match('/^https?:\\/\\//i', (string)$url)) {
            return $url;
        }
        $siteUrl = rtrim((string)sys_config('site_url', ''), '/');
        return $siteUrl . '/' . ltrim((string)$url, '/');
    }
}
