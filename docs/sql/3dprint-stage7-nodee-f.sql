-- 3D打印改版阶段7：节点 E/F 报价交付时间与支付超时补齐。
-- 已部署数据库执行一次；脚本会在字段已存在时跳过变更。

SET NAMES utf8mb4;

SET @quote_eta_exists := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'eb_inquiry'
    AND column_name = 'quote_expected_deliver_at'
);
SET @quote_eta_sql := IF(
  @quote_eta_exists = 0,
  'ALTER TABLE `eb_inquiry` ADD COLUMN `quote_expected_deliver_at` int(11) NOT NULL DEFAULT ''0'' COMMENT ''报价预计交付时间戳'' AFTER `quote_at`',
  'SELECT 1'
);
PREPARE quote_eta_stmt FROM @quote_eta_sql;
EXECUTE quote_eta_stmt;
DEALLOCATE PREPARE quote_eta_stmt;
