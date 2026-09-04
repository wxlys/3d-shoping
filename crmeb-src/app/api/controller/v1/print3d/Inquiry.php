<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：用户询价接口
// +----------------------------------------------------------------------

namespace app\api\controller\v1\print3d;

use app\Request;
use app\services\print3d\PrintInquiryServices;
use crmeb\exceptions\ApiException;

/**
 * 定制打印询价
 * Class Inquiry
 */
class Inquiry
{
    protected $services;

    public function __construct(PrintInquiryServices $services)
    {
        $this->services = $services;
    }

    public function upload(Request $request)
    {
        $data = $this->services->uploadFile($request, $this->uid($request));
        return app('json')->success('模型文件上传成功', $data);
    }

    public function files(Request $request)
    {
        [$page, $limit] = $request->getMore([
            ['page', 1],
            ['limit', 20],
        ], true);
        return app('json')->success($this->services->getFileList($this->uid($request), (int)$page, (int)$limit));
    }

    public function fileInfo(Request $request, $id)
    {
        return app('json')->success($this->services->getUserFileInfo($this->uid($request), (int)$id));
    }

    public function download(Request $request, $id)
    {
        $file = $this->services->getUserFile($this->uid($request), (int)$id);
        return $this->services->downloadFile($file);
    }

    public function signedDownload(Request $request, $id)
    {
        $expires = (int)$request->get('expires', 0);
        $signature = (string)$request->get('signature', '');
        if (!$this->services->verifyDownloadSignature((int)$id, $expires, $signature)) {
            throw new ApiException('下载地址已失效');
        }
        return $this->services->downloadFile($this->services->getFileById((int)$id));
    }

    public function deleteFile(Request $request, $id)
    {
        $this->services->deleteUserFile($this->uid($request), (int)$id);
        return app('json')->success('模型文件已删除');
    }

    public function create(Request $request)
    {
        [$fileId, $sizeLevel, $material, $quantity] = $request->postMore([
            ['file_id', 0],
            ['size_level', ''],
            ['material', 'PLA'],
            ['quantity', 1],
        ], true);
        $data = $this->services->createInquiry($this->uid($request), [
            'file_id' => $fileId,
            'size_level' => $sizeLevel,
            'material' => $material,
            'quantity' => $quantity,
        ]);
        return app('json')->success('询价单提交成功，请等待报价', $data);
    }

    public function lst(Request $request)
    {
        [$status, $page, $limit] = $request->getMore([
            ['status', ''],
            ['page', 1],
            ['limit', 20],
        ], true);
        return app('json')->success($this->services->getUserList($this->uid($request), [
            'status' => $status,
            'page' => $page,
            'limit' => $limit,
        ]));
    }

    public function detail(Request $request, $id)
    {
        return app('json')->success($this->services->getUserDetail($this->uid($request), (int)$id));
    }

    public function cancel(Request $request, $id)
    {
        $this->services->cancelInquiry($this->uid($request), (int)$id);
        return app('json')->success('询价单已取消');
    }

    public function confirm(Request $request, $id)
    {
        $data = $this->services->confirmInquiry($this->uid($request), (int)$id);
        return app('json')->success('报价已确认，请完成支付', $data);
    }

    protected function uid(Request $request): int
    {
        $uid = (int)$request->uid();
        if ($uid <= 0) {
            throw new ApiException('请先登录');
        }
        return $uid;
    }
}
