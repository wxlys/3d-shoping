-- ============================================================
-- 3D 打印服务系统 改版 阶段1：数据表 + 订单扩展 + 打印参数
-- 目标库：crmeb（MySQL 5.7，utf8mb4）
-- 执行方式：mysql -uroot -p < 3dprint-stage1.sql
-- ============================================================

SET NAMES utf8mb4;

-- 1. 打印设备表
CREATE TABLE IF NOT EXISTS `eb_print_device` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '设备名称',
  `model` varchar(50) NOT NULL DEFAULT 'Bambu Lab A1' COMMENT '设备型号',
  `build_volume` varchar(50) NOT NULL DEFAULT '256x256x256' COMMENT '构建体积(mm)',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1启用 0停用',
  `business_start` varchar(10) NOT NULL DEFAULT '09:00' COMMENT '营业开始',
  `business_end` varchar(10) NOT NULL DEFAULT '21:00' COMMENT '营业结束',
  `setup_minutes` int(11) NOT NULL DEFAULT '30' COMMENT '每单设备调试时长(分钟)',
  `add_time` int(11) NOT NULL DEFAULT '0',
  `update_time` int(11) NOT NULL DEFAULT '0',
  `is_del` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打印设备表';

-- 2. 排单队列表
CREATE TABLE IF NOT EXISTS `eb_print_queue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单ID',
  `device_id` int(11) NOT NULL DEFAULT '0' COMMENT '设备ID',
  `queue_no` int(11) NOT NULL DEFAULT '0' COMMENT '队列序号',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1排队中 2制作中 3已完成 4已取消',
  `expected_start_at` int(11) NOT NULL DEFAULT '0' COMMENT '预计开始时间戳',
  `expected_end_at` int(11) NOT NULL DEFAULT '0' COMMENT '预计结束时间戳',
  `actual_start_at` int(11) NOT NULL DEFAULT '0' COMMENT '实际开始时间戳',
  `actual_end_at` int(11) NOT NULL DEFAULT '0' COMMENT '实际结束时间戳',
  `adjusted_by` int(11) NOT NULL DEFAULT '0' COMMENT '调整人(管理员ID)',
  `adjusted_at` int(11) NOT NULL DEFAULT '0' COMMENT '调整时间',
  `add_time` int(11) NOT NULL DEFAULT '0',
  `update_time` int(11) NOT NULL DEFAULT '0',
  `is_del` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order` (`order_id`),
  KEY `idx_device_status` (`device_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打印排单队列表';

-- 3. 打印文件表
CREATE TABLE IF NOT EXISTS `eb_print_file` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL DEFAULT '0' COMMENT '用户ID',
  `inquiry_id` int(11) NOT NULL DEFAULT '0' COMMENT '询价单ID',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单ID',
  `filename` varchar(255) NOT NULL DEFAULT '' COMMENT '原始文件名',
  `stored_name` varchar(255) NOT NULL DEFAULT '' COMMENT '存储文件名(随机)',
  `ext` varchar(20) NOT NULL DEFAULT '' COMMENT '扩展名',
  `size` int(11) NOT NULL DEFAULT '0' COMMENT '文件大小(字节)',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1校验中 2通过 3失败',
  `fail_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '失败原因',
  `add_time` int(11) NOT NULL DEFAULT '0',
  `update_time` int(11) NOT NULL DEFAULT '0',
  `is_del` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_uid` (`uid`),
  KEY `idx_inquiry` (`inquiry_id`),
  KEY `idx_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打印模型文件表';

-- 4. 询价单表
CREATE TABLE IF NOT EXISTS `eb_inquiry` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `inquiry_no` varchar(32) NOT NULL DEFAULT '' COMMENT '询价单号',
  `uid` int(11) NOT NULL DEFAULT '0' COMMENT '用户ID',
  `file_id` int(11) NOT NULL DEFAULT '0' COMMENT '打印文件ID',
  `size_level` varchar(10) NOT NULL DEFAULT '' COMMENT '尺寸档位 S/M/L/XL',
  `material` varchar(20) NOT NULL DEFAULT '' COMMENT '材料 PLA/PETG',
  `quantity` int(11) NOT NULL DEFAULT '1' COMMENT '数量',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1待报价 2已报价 3已确认 4已过期 5已取消',
  `quote_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '报价金额',
  `quote_by` int(11) NOT NULL DEFAULT '0' COMMENT '报价管理员ID',
  `quote_at` int(11) NOT NULL DEFAULT '0' COMMENT '报价时间',
  `expire_at` int(11) NOT NULL DEFAULT '0' COMMENT '报价过期时间',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '转正式订单ID',
  `add_time` int(11) NOT NULL DEFAULT '0',
  `update_time` int(11) NOT NULL DEFAULT '0',
  `is_del` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_inquiry_no` (`inquiry_no`),
  KEY `idx_uid` (`uid`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='定制询价单表';

-- 5. 订单表扩展字段（迁移执行一次；重复执行前需先删除以下字段）
ALTER TABLE `eb_store_order`
    ADD COLUMN `is_print` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否定制打印',
    ADD COLUMN `print_file_id` int(11) NOT NULL DEFAULT '0' COMMENT '打印文件ID',
    ADD COLUMN `size_level` varchar(10) NOT NULL DEFAULT '' COMMENT '尺寸档位',
    ADD COLUMN `material` varchar(20) NOT NULL DEFAULT '' COMMENT '材料',
    ADD COLUMN `expected_start_at` int(11) NOT NULL DEFAULT '0' COMMENT '预计开始时间戳',
    ADD COLUMN `expected_deliver_at` int(11) NOT NULL DEFAULT '0' COMMENT '预计交付时间戳',
    ADD COLUMN `queue_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0不排队 1排队中 2制作中 3已制作完成 4已取消',
    ADD COLUMN `progress_note` varchar(500) NOT NULL DEFAULT '' COMMENT '打印进度备注',
    ADD COLUMN `inquiry_id` int(11) NOT NULL DEFAULT '0' COMMENT '询价单ID';

-- 6. 打印配置分类
INSERT INTO `eb_system_config_tab` (`id`, `pid`, `title`, `eng_title`, `status`, `info`, `icon`, `type`, `sort`, `menus_id`)
VALUES (200, 0, '打印设置', 'print_setting', 1, 0, 'md-print', 0, 100, 0)
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`);

-- 7. 打印参数（value 为 JSON 编码）
DELETE FROM `eb_system_config` WHERE `config_tab_id` = 200;

INSERT INTO `eb_system_config`
  (`menu_name`, `type`, `input_type`, `config_tab_id`, `parameter`, `upload_type`, `required`, `width`, `high`, `value`, `info`, `desc`, `sort`, `status`, `level`, `link_id`, `link_value`)
VALUES
  ('print_business_start', 'text', 'input', 200, '', 1, '', 100, 0, '"09:00"', '营业开始时间', '排单计算使用', 1, 1, 0, 0, 0),
  ('print_business_end', 'text', 'input', 200, '', 1, '', 100, 0, '"21:00"', '营业结束时间', '排单计算使用', 2, 1, 0, 0, 0),
  ('print_device_count', 'number', 'number', 200, '', 1, '', 100, 0, '1', '设备数量', '并行打印设备数', 3, 1, 0, 0, 0),
  ('print_setup_minutes', 'number', 'number', 200, '', 1, '', 100, 0, '30', '每单调试时长(分钟)', '设备调试时间', 4, 1, 0, 0, 0),
  ('print_fill_ratio', 'number', 'number', 200, '', 1, '', 100, 0, '0.2', '填充系数', '预估材料体积=标准体积*填充系数', 5, 1, 0, 0, 0),
  ('print_efficiency', 'number', 'number', 200, '', 1, '', 100, 0, '0.6', '打印效率系数', '有效流速=材料最大流速*效率', 6, 1, 0, 0, 0),
  ('print_speed_pla', 'number', 'number', 200, '', 1, '', 100, 0, '21', 'PLA 最大体积速度(mm³/s)', '官方参数', 7, 1, 0, 0, 0),
  ('print_speed_petg', 'number', 'number', 200, '', 1, '', 100, 0, '15', 'PETG 最大体积速度(mm³/s)', '官方参数', 8, 1, 0, 0, 0),
  ('print_size_s', 'number', 'number', 200, '', 1, '', 100, 0, '100', 'S 档标准体积(cm³)', '尺寸档位', 9, 1, 0, 0, 0),
  ('print_size_m', 'number', 'number', 200, '', 1, '', 100, 0, '500', 'M 档标准体积(cm³)', '尺寸档位', 10, 1, 0, 0, 0),
  ('print_size_l', 'number', 'number', 200, '', 1, '', 100, 0, '2000', 'L 档标准体积(cm³)', '尺寸档位', 11, 1, 0, 0, 0),
  ('print_size_xl', 'number', 'number', 200, '', 1, '', 100, 0, '4000', 'XL 档标准体积(cm³)', '尺寸档位', 12, 1, 0, 0, 0),
  ('print_material_pla', 'number', 'number', 200, '', 1, '', 100, 0, '1.0', 'PLA 材料系数', '相对 PLA 基准', 13, 1, 0, 0, 0),
  ('print_material_petg', 'number', 'number', 200, '', 1, '', 100, 0, '0.71', 'PETG 材料系数', '相对 PLA 基准', 14, 1, 0, 0, 0),
  ('pay_timeout_minutes', 'number', 'number', 200, '', 1, '', 100, 0, '15', '支付超时(分钟)', '超时自动取消', 15, 1, 0, 0, 0),
  ('inquiry_expire_hours', 'number', 'number', 200, '', 1, '', 100, 0, '48', '报价有效期(小时)', '超时自动过期', 16, 1, 0, 0, 0),
  ('auto_receipt_days', 'number', 'number', 200, '', 1, '', 100, 0, '7', '自动收货天数', '待取满N天自动完成', 17, 1, 0, 0, 0),
  ('print_file_max_mb', 'number', 'number', 200, '', 1, '', 100, 0, '100', '模型文件大小上限(MB)', '上传限制', 18, 1, 0, 0, 0),
  ('print_file_max_count', 'number', 'number', 200, '', 1, '', 100, 0, '50', '模型文件数量上限(个/用户)', '上传限制', 19, 1, 0, 0, 0),
  ('print_file_retain_days', 'number', 'number', 200, '', 1, '', 100, 0, '30', '模型文件保留天数', '未引用自动清理', 20, 1, 0, 0, 0),
  ('print_file_extensions', 'text', 'input', 200, '', 1, '', 100, 0, '"stl,obj,3mf,stp,step"', '模型文件格式白名单', '逗号分隔', 21, 1, 0, 0, 0)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

-- 8. 初始化默认设备（拓竹 A1 × 1）
INSERT INTO `eb_print_device`
  (`name`, `model`, `build_volume`, `status`, `business_start`, `business_end`, `setup_minutes`, `add_time`, `update_time`, `is_del`)
SELECT '1号打印设备', 'Bambu Lab A1', '256x256x256', 1, '09:00', '21:00', 30, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0
WHERE NOT EXISTS (SELECT 1 FROM `eb_print_device` WHERE `is_del` = 0);
