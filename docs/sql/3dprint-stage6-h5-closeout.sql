-- 3D打印改版阶段6：合并并启用周期维护任务。
-- 每5分钟执行：询价报价过期、待取自动完成、未引用模型文件清理。

UPDATE `eb_system_timer`
SET `name` = '3D打印业务维护',
    `mark` = 'printMaintenance',
    `content` = '每隔5分钟处理报价过期、自动收货和未引用模型清理',
    `type` = 2,
    `month` = 0,
    `week` = 1,
    `day` = 1,
    `hour` = 1,
    `minute` = 5,
    `second` = 0,
    `is_open` = 1,
    `is_del` = 0,
    `timeStr` = '0 */5 * * * *',
    `next_execution_time` = UNIX_TIMESTAMP() + 300,
    `update_time` = UNIX_TIMESTAMP()
WHERE `mark` = 'print_auto_receipt';

INSERT INTO `eb_system_timer`
(`name`, `mark`, `content`, `type`, `month`, `week`, `day`, `hour`, `minute`, `second`, `last_execution_time`, `next_execution_time`, `add_time`, `update_time`, `is_del`, `is_open`, `customCode`, `timeStr`)
SELECT '3D打印业务维护', 'printMaintenance', '每隔5分钟处理报价过期、自动收货和未引用模型清理', 2, 0, 1, 1, 1, 5, 0, 0, UNIX_TIMESTAMP() + 300, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 1, '', '0 */5 * * * *'
WHERE NOT EXISTS (SELECT 1 FROM `eb_system_timer` WHERE `mark` = 'printMaintenance' AND `is_del` = 0);

UPDATE `eb_system_timer`
SET `is_open` = 0, `is_del` = 1, `update_time` = UNIX_TIMESTAMP()
WHERE `mark` = 'print_inquiry_expire';
