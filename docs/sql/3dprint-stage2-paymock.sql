-- 阶段2：模拟支付开关（1=开启 0=关闭）
SET NAMES utf8mb4;

DELETE FROM `eb_system_config` WHERE `menu_name` = 'pay_mock_enabled';

INSERT INTO `eb_system_config`
  (`menu_name`, `type`, `input_type`, `config_tab_id`, `parameter`, `upload_type`, `required`, `width`, `high`, `value`, `info`, `desc`, `sort`, `status`, `level`, `link_id`, `link_value`)
VALUES
  ('pay_mock_enabled', 'number', 'number', 200, '', 1, '', 100, 0, '1', '模拟支付开关', '1=开启（支付接口直接成功） 0=关闭', 0, 1, 0, 0, 0);
