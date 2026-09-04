-- ============================================================
-- 3D 打印业务收敛重构 R2：后台权限登记与角色预置
-- 目标库：crmeb（MySQL 5.7，utf8mb4）
--
-- 说明：
-- 1. 超级管理员使用 eb_system_admin.level=0，继续拥有全部权限。
-- 2. 其余管理员通过 eb_system_admin.roles 关联本脚本预置的角色。
-- 3. 角色规则保存菜单/按钮/接口记录 ID；脚本可重复执行。
-- 4. 不删除任何旧菜单、路由或共享权限记录。
-- ============================================================

SET NAMES utf8mb4;
SET SESSION group_concat_max_len = 65535;

-- 工作台接口。原有工作台页面只登记了菜单，没有登记接口，导致角色无法
-- 对工作台数据接口进行最小授权。
INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', x.`menu_name`, 'admin', '', '', x.`api_url`, x.`methods`, '[]', 1, 1, 1, 1, '', '', 2, '', 0, x.`unique_auth`, 0, x.`menu_name`
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-home' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
JOIN (
  SELECT '工作台头部统计' AS `menu_name`, 'home/header' AS `api_url`, 'GET' AS `methods`, 'admin-home-header' AS `unique_auth`
  UNION ALL SELECT '工作台订单图表', 'home/order', 'GET', 'admin-home-order'
  UNION ALL SELECT '工作台用户图表', 'home/user', 'GET', 'admin-home-user'
  UNION ALL SELECT '工作台交易排行', 'home/rank', 'GET', 'admin-home-rank'
  UNION ALL SELECT '工作台提醒', 'jnotice', 'GET', 'admin-home-notice'
  UNION ALL SELECT '打印业务统计', 'home/print_stats', 'GET', 'admin-home-print-stats'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_menus` m
  WHERE m.`api_url` = x.`api_url` AND m.`methods` = x.`methods` AND m.`is_del` = 0
);

-- 核心订单接口登记。已有同路径权限记录时不重复写入。
INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', x.`menu_name`, 'admin', '', '', x.`api_url`, x.`methods`, '[]', 1, 1, 1, 1, '', '', 2, '', 0, x.`unique_auth`, 0, x.`menu_name`
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order-storeOrder-index' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
JOIN (
  SELECT '订单列表' AS `menu_name`, 'order/list' AS `api_url`, 'GET' AS `methods`, 'admin-order-list' AS `unique_auth`
  UNION ALL SELECT '订单图表', 'order/chart', 'GET', 'admin-order-chart'
  UNION ALL SELECT '订单详情', 'order/info/<id>', 'GET', 'admin-order-info'
  UNION ALL SELECT '订单状态', 'order/status/<id>', 'GET', 'admin-order-status'
  UNION ALL SELECT '订单修改', 'order/update/<id>', 'PUT', 'admin-order-update'
  UNION ALL SELECT '订单发货', 'order/delivery/<id>', 'PUT', 'admin-order-delivery'
  UNION ALL SELECT '订单配送信息', 'order/distribution/<id>', 'GET', 'admin-order-distribution'
  UNION ALL SELECT '保存配送信息', 'order/distribution/<id>', 'PUT', 'admin-order-distribution-save'
  UNION ALL SELECT '订单备注', 'order/remark/<id>', 'PUT', 'admin-order-remark'
  UNION ALL SELECT '订单确认收货', 'order/take/<id>', 'PUT', 'admin-order-take'
  UNION ALL SELECT '订单核销', 'order/write', 'POST', 'admin-order-write'
  UNION ALL SELECT '订单核销确认', 'order/write_update/<order_id>', 'PUT', 'admin-order-write-update'
  UNION ALL SELECT '开始打印', 'order/print/start', 'POST', 'admin-order-print-start'
  UNION ALL SELECT '完成打印', 'order/print/complete', 'POST', 'admin-order-print-complete'
  UNION ALL SELECT '调整打印排期', 'order/print/adjust_schedule', 'POST', 'admin-order-print-adjust'
  UNION ALL SELECT '更新打印进度', 'order/print/progress', 'POST', 'admin-order-print-progress'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_menus` m
  WHERE m.`api_url` = x.`api_url` AND m.`methods` = x.`methods` AND m.`is_del` = 0
);

-- 用户查看与封禁接口登记，客服角色只授予这些接口，不授予用户资料、余额、会员和分销操作。
INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', x.`menu_name`, 'admin', '', '', x.`api_url`, x.`methods`, '[]', 1, 1, 1, 1, '', '', 2, '', 0, x.`unique_auth`, 0, x.`menu_name`
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-user-user-index' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
JOIN (
  SELECT '用户列表' AS `menu_name`, 'user/user' AS `api_url`, 'POST' AS `methods`, 'admin-user-list' AS `unique_auth`
  UNION ALL SELECT '用户详情', 'user/user/<id>', 'GET', 'admin-user-info'
  UNION ALL SELECT '用户附加信息', 'user/one_info/<id>', 'GET', 'admin-user-one-info'
  UNION ALL SELECT '封禁或解封用户', 'user/set_status/<status>/<id>', 'PUT', 'admin-user-set-status'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_menus` m
  WHERE m.`api_url` = x.`api_url` AND m.`methods` = x.`methods` AND m.`is_del` = 0
);

-- 定制打印接口登记。
INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', x.`menu_name`, 'admin', '', '', x.`api_url`, x.`methods`, '[]', 1, 1, 1, 1, '', '', 2, '', 0, x.`unique_auth`, 0, x.`menu_name`
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order-print-queue-index' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
JOIN (
  SELECT '打印排单列表' AS `menu_name`, 'print/queue/list' AS `api_url`, 'GET' AS `methods`, 'admin-print-queue-list' AS `unique_auth`
  UNION ALL SELECT '开始排单打印', 'print/queue/start', 'POST', 'admin-print-queue-start'
  UNION ALL SELECT '完成排单打印', 'print/queue/complete', 'POST', 'admin-print-queue-complete'
  UNION ALL SELECT '调整排单时间', 'print/queue/adjust', 'POST', 'admin-print-queue-adjust'
  UNION ALL SELECT '更新打印进度', 'print/queue/progress', 'POST', 'admin-print-queue-progress'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_menus` m
  WHERE m.`api_url` = x.`api_url` AND m.`methods` = x.`methods` AND m.`is_del` = 0
);

INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', x.`menu_name`, 'admin', '', '', x.`api_url`, x.`methods`, '[]', 1, 1, 1, 1, '', '', 2, '', 0, x.`unique_auth`, 0, x.`menu_name`
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order-print-inquiry-index' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
JOIN (
  SELECT '询价单列表' AS `menu_name`, 'print/inquiry/list' AS `api_url`, 'GET' AS `methods`, 'admin-print-inquiry-list' AS `unique_auth`
  UNION ALL SELECT '询价单详情', 'print/inquiry/info/<id>', 'GET', 'admin-print-inquiry-info'
  UNION ALL SELECT '保存询价报价', 'print/inquiry/quote/<id>', 'POST', 'admin-print-inquiry-quote'
  UNION ALL SELECT '作废询价报价', 'print/inquiry/expire/<id>', 'POST', 'admin-print-inquiry-expire'
) x
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_menus` m
  WHERE m.`api_url` = x.`api_url` AND m.`methods` = x.`methods` AND m.`is_del` = 0
);

-- 构造角色规则。MySQL 5.7 不支持递归 CTE，使用带 source_root 的临时表展开最多 8 层菜单树。
DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu` (
  `role_key` varchar(32) NOT NULL,
  `menu_id` int(11) NOT NULL,
  `source_root` int(11) NOT NULL,
  `expand_children` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`role_key`, `menu_id`)
) ENGINE=InnoDB;

-- 客服：工作台、用户列表、订单全流程（含询价/退款/核销）。
INSERT INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`) VALUES
  ('customer_service', 7, 7, 1),
  ('customer_service', 4, 4, 1),
  ('customer_service', 9, 9, 0),
  ('customer_service', 10, 10, 0);

-- 财务：工作台、订单/财务页面；接口权限后续只保留 GET。
INSERT INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`) VALUES
  ('finance', 7, 7, 1),
  ('finance', 4, 4, 0),
  ('finance', 5, 5, 1),
  ('finance', 35, 35, 1),
  ('finance', 3466, 3466, 1);

-- 库管：工作台、商品全权限、订单查看、打印排单全权限。
INSERT INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`) VALUES
  ('warehouse', 7, 7, 1),
  ('warehouse', 1, 1, 1),
  ('warehouse', 4, 4, 0),
  ('warehouse', 5, 5, 1),
  ('warehouse', 3465, 3465, 1);

-- MySQL 5.7 不能在同一条语句中读写同一临时表，每轮先复制快照再展开一层。
DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu_source`;
CREATE TEMPORARY TABLE `tmp_3d_role_menu_source` AS SELECT * FROM `tmp_3d_role_menu`;
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT r.`role_key`, m.`id`, r.`source_root`, 1
FROM `tmp_3d_role_menu_source` r
JOIN `eb_system_menus` m ON m.`pid` = r.`menu_id` AND m.`is_del` = 0 AND m.`is_show` = 1
WHERE r.`expand_children` = 1;
DROP TEMPORARY TABLE `tmp_3d_role_menu_source`;

-- 客服允许读取用户列表/详情并执行封禁解封；这些接口不是用户菜单的子树，单独加入规则。
INSERT IGNORE INTO `tmp_3d_role_menu` (`role_key`, `menu_id`, `source_root`, `expand_children`)
SELECT 'customer_service', m.`id`, 10, 0
FROM `eb_system_menus` m
WHERE (
       (m.`api_url` = 'user/user' AND m.`methods` = 'POST')
    OR (m.`api_url` = 'user/user/<id>' AND m.`methods` = 'GET')
    OR (m.`api_url` = 'user/one_info/<id>' AND m.`methods` = 'GET')
    OR (m.`api_url` = 'user/set_status/<status>/<id>' AND m.`methods` = 'PUT')
  )
  AND m.`is_del` = 0;

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_rules`;
CREATE TEMPORARY TABLE `tmp_3d_role_rules` (
  `role_key` varchar(32) NOT NULL,
  `rules` text NOT NULL,
  PRIMARY KEY (`role_key`)
) ENGINE=InnoDB;

INSERT INTO `tmp_3d_role_rules` (`role_key`, `rules`)
SELECT r.`role_key`, GROUP_CONCAT(r.`menu_id` ORDER BY r.`menu_id` SEPARATOR ',')
FROM `tmp_3d_role_menu` r
JOIN `eb_system_menus` m ON m.`id` = r.`menu_id` AND m.`is_del` = 0
WHERE
  r.`role_key` = 'customer_service'
  OR (r.`role_key` = 'finance' AND (m.`auth_type` = 1 OR (m.`auth_type` = 2 AND UPPER(m.`methods`) = 'GET')))
  OR (r.`role_key` = 'warehouse' AND (r.`source_root` IN (1, 3465, 7) OR m.`auth_type` = 1 OR (m.`auth_type` = 2 AND UPPER(m.`methods`) = 'GET')))
GROUP BY r.`role_key`;

-- 角色已存在时刷新为本次预置权限；管理员账号不会被改动。
UPDATE `eb_system_role` r
JOIN `tmp_3d_role_rules` p ON p.`role_key` = CASE r.`role_name`
  WHEN '客服' THEN 'customer_service'
  WHEN '财务' THEN 'finance'
  WHEN '库管' THEN 'warehouse'
  ELSE '' END
SET r.`rules` = p.`rules`, r.`level` = 1, r.`status` = 1;

INSERT INTO `eb_system_role` (`role_name`, `rules`, `level`, `status`)
SELECT x.`role_name`, p.`rules`, 1, 1
FROM (
  SELECT '客服' AS `role_name`, 'customer_service' AS `role_key`
  UNION ALL SELECT '财务', 'finance'
  UNION ALL SELECT '库管', 'warehouse'
) x
JOIN `tmp_3d_role_rules` p ON p.`role_key` = x.`role_key`
WHERE NOT EXISTS (
  SELECT 1 FROM `eb_system_role` r WHERE r.`role_name` = x.`role_name`
);

DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_rules`;
DROP TEMPORARY TABLE IF EXISTS `tmp_3d_role_menu`;
