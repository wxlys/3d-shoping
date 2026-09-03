-- 阶段4 节点C：待取时间字段 + 待评价超时自动完成定时任务
SET NAMES utf8mb4;

ALTER TABLE `eb_store_order`
    ADD COLUMN `pickup_at` int(11) NOT NULL DEFAULT '0' COMMENT '进入待取时间戳' AFTER `progress_note`;

DELETE FROM `eb_system_timer` WHERE `mark` = 'print_auto_receipt';

INSERT INTO `eb_system_timer`
  (`name`, `mark`, `content`, `type`, `month`, `week`, `day`, `hour`, `minute`, `second`, `last_execution_time`, `next_execution_time`, `add_time`, `update_time`, `is_del`, `is_open`, `customCode`, `timeStr`)
VALUES
  ('3D打印评价超时自动完成', 'print_auto_receipt', '待评价满N天自动完成', 3, 0, 0, 0, 1, 0, 0, 0, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 1, 'app()->make(\app\services\printqueue\PrintQueueServices::class)->autoReceipt();', '每小时执行')
