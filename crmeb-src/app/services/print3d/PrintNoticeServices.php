<?php
// +----------------------------------------------------------------------
// | 3D打印服务改造：站内消息
// +----------------------------------------------------------------------

namespace app\services\print3d;

use app\services\message\MessageSystemServices;

class PrintNoticeServices
{
    public function send(int $uid, string $title, string $content, array $data = []): bool
    {
        if ($uid <= 0) {
            return false;
        }
        return false !== app()->make(MessageSystemServices::class)->save([
            'mark' => 'print_notice',
            'uid' => $uid,
            'title' => $title,
            'content' => $content,
            'data' => $data ? json_encode($data, JSON_UNESCAPED_UNICODE) : '',
            'type' => 1,
            'add_time' => time(),
        ]);
    }
}
