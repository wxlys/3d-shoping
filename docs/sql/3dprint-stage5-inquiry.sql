-- ============================================================
-- 3D打印服务系统 改版 阶段5：询价闭环 + 后台排单菜单
-- 说明：阶段1/2/3/4 的表结构与配置请先按原脚本执行；本脚本不重复修改订单表字段。
-- 目标库：crmeb（MySQL 5.7，utf8mb4）
-- 执行方式：mysql -uroot -p crmeb < 3dprint-stage5-inquiry.sql
-- ============================================================

SET NAMES utf8mb4;

-- 报价有效期兜底任务：每小时将超过有效期的“已报价”询价单改为“已过期”。
DELETE FROM `eb_system_timer` WHERE `mark` = 'print_inquiry_expire';

INSERT INTO `eb_system_timer`
  (`name`, `mark`, `content`, `type`, `month`, `week`, `day`, `hour`, `minute`, `second`, `last_execution_time`, `next_execution_time`, `add_time`, `update_time`, `is_del`, `is_open`, `customCode`, `timeStr`)
VALUES
  ('3D打印询价过期', 'print_inquiry_expire', '报价超过有效期自动过期', 3, 0, 0, 0, 1, 0, 0, 0, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0, 1, 'app()->make(\app\services\print3d\PrintInquiryServices::class)->expireQuoted();', '每小时执行');

-- 后台菜单：挂在现有“订单”菜单（unique_auth 用于前端路由鉴权）。
INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', '排单管理', 'admin', 'order.print_queue', 'index', '', '', '[]', 8, 1, 1, 1, '/order/print-queue', CAST(p.`id` AS CHAR), 1, 'order', 0, 'admin-order-print-queue-index', 0, '排单管理'
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order-print-queue-index' AND `is_del` = 0);

INSERT INTO `eb_system_menus`
  (`pid`, `icon`, `menu_name`, `module`, `controller`, `action`, `api_url`, `methods`, `params`, `sort`, `is_show`, `is_show_path`, `access`, `menu_path`, `path`, `auth_type`, `header`, `is_header`, `unique_auth`, `is_del`, `mark`)
SELECT p.`id`, '', '询价单管理', 'admin', 'order.print_inquiry', 'index', '', '', '[]', 7, 1, 1, 1, '/order/inquiry', CAST(p.`id` AS CHAR), 1, 'order', 0, 'admin-order-print-inquiry-index', 0, '询价单管理'
FROM (SELECT `id` FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order' AND `is_del` = 0 ORDER BY `id` LIMIT 1) p
WHERE NOT EXISTS (SELECT 1 FROM `eb_system_menus` WHERE `unique_auth` = 'admin-order-print-inquiry-index' AND `is_del` = 0);
