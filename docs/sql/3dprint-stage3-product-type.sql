-- 阶段3：商品类型字段（0=成品 1=定制打印）
SET NAMES utf8mb4;

ALTER TABLE `eb_store_product`
    ADD COLUMN `product_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '商品类型 0成品 1定制打印' AFTER `is_seckill`;
