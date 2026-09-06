-- R8 MakerWorld 成品商品种子
-- 目标：为 8 个一级分类各提供至少 1 个可追溯的 3D 打印成品。
-- 来源：MakerWorld 模型页；优先选择页面/API 标注 CC0（Creative Commons Public Domain）的模型。
-- 依赖：先执行同目录的 3dprint-refactor-r1-catalog.sql，确保一级/二级分类 ID 已收敛为 3D 打印分类。
-- 执行前必须备份数据库。脚本可重复执行（按 SPU 幂等），不会重复插入商品及关联数据。

SET NAMES utf8mb4;
START TRANSACTION;

-- R7 的四条占位成品不再上架；不删除，便于回滚或后台复核。
UPDATE eb_store_product
SET is_show = 0
WHERE spu IN ('PH26090600001', 'PH26090600002', 'PH26090600003', 'PH26090600004')
  AND store_name IN ('桌面收纳托盘（占位）', '创意拼装小车（占位）', '多功能理线夹（占位）', '建筑展示模型（占位）');

-- 家居生活 / 收纳整理
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US5aa25103dcd4a4/design/2025-04-16_2d772dddbaf8e.jpeg', 'https://makerworld.bblmw.com/makerworld/model/US5aa25103dcd4a4/design/2025-04-16_2d772dddbaf8e.jpeg', '["https://makerworld.bblmw.com/makerworld/model/US5aa25103dcd4a4/design/2025-04-16_2d772dddbaf8e.jpeg"]', '摩艾眼镜收纳架（Moai Glasses Holder）', '公共领域模型打印成品；眼镜、手机与笔一体收纳', '摩艾,眼镜架,桌面收纳,MakerWorld', '10', 39.90, 49.90, '件', 80, 100, 1, 1, 0, 1, 1, UNIX_TIMESTAMP(), 1, 12.00, 0, 0, '0,1', 'MW26090600001', 'https://makerworld.com/en/models/1327366-moai-glasses-holder', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600001');

-- 玩具与游戏 / 益智玩具
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US8a0669dcf3430b/design/2025-02-13_bc6c89c84d6bf.jpg', 'https://makerworld.bblmw.com/makerworld/model/US8a0669dcf3430b/design/2025-02-13_bc6c89c84d6bf.jpg', '["https://makerworld.bblmw.com/makerworld/model/US8a0669dcf3430b/design/2025-02-13_bc6c89c84d6bf.jpg"]', '链环指尖陀螺（Chain-Link Fidget Spinner）', '免 AMS 打印的链环解压玩具，适合桌面把玩', '指尖陀螺,解压玩具,益智玩具,MakerWorld', '15', 29.90, 39.90, '件', 70, 100, 1, 1, 1, 0, 1, UNIX_TIMESTAMP(), 1, 8.00, 0, 0, '0,1', 'MW26090600002', 'https://makerworld.com/en/models/1105532-chain-link-fidget-spinner', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600002');

-- 工具与配件 / 维修辅助
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US33a17eb041343e/design/2025-01-12_feead0bb63812.jpg', 'https://makerworld.bblmw.com/makerworld/model/US33a17eb041343e/design/2025-01-12_feead0bb63812.jpg', '["https://makerworld.bblmw.com/makerworld/model/US33a17eb041343e/design/2025-01-12_feead0bb63812.jpg"]', '青蛙胶带遮蔽工具（Frog Tape Masking Tool）', '用于涂装贴胶带的便携辅助工具，PLA/PETG 均可打印', '胶带工具,涂装,维修辅助,MakerWorld', '19', 19.90, 29.90, '件', 60, 100, 1, 0, 1, 0, 1, UNIX_TIMESTAMP(), 1, 5.00, 0, 0, '0,1', 'MW26090600003', 'https://makerworld.com/en/models/985320-frog-tape-masking-tool-1-41-inch-36mm', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600003');

-- 模型与摆件 / 角色摆件
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US92e03b8347e8d3/design/2025-02-04_75be35700476.jpg', 'https://makerworld.bblmw.com/makerworld/model/US92e03b8347e8d3/design/2025-02-04_75be35700476.jpg', '["https://makerworld.bblmw.com/makerworld/model/US92e03b8347e8d3/design/2025-02-04_75be35700476.jpg"]', '迷你小龙摆件（Tiny Dragon）', '可动或静态展示的小型龙主题摆件，适合作为桌面礼物', '小龙,摆件,桌面装饰,MakerWorld', '23', 49.90, 69.90, '件', 50, 100, 1, 1, 0, 1, 1, UNIX_TIMESTAMP(), 1, 15.00, 0, 0, '0,1', 'MW26090600004', 'https://makerworld.com/en/models/1073648-tiny-dragon-sell-it', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600004');

-- 创意礼品 / 个性礼物
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US9524b8b18320bf/design/2025-07-04_a0ef0bec886488.jpeg', 'https://makerworld.bblmw.com/makerworld/model/US9524b8b18320bf/design/2025-07-04_a0ef0bec886488.jpeg', '["https://makerworld.bblmw.com/makerworld/model/US9524b8b18320bf/design/2025-07-04_a0ef0bec886488.jpeg"]', '迷你三角钢琴礼品盒（Grand Piano）', '可开合的迷你钢琴盒，可作首饰盒、礼品盒或桌面装饰', '钢琴,礼品盒,创意礼物,MakerWorld', '25', 59.90, 79.90, '件', 40, 100, 1, 1, 0, 1, 1, UNIX_TIMESTAMP(), 1, 20.00, 0, 0, '0,1', 'MW26090600005', 'https://makerworld.com/en/models/1575340-grand-piano', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600005');

-- 教育与创客 / 教具模型
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/USdce52deb9ad668/design/2024-09-06_674d69057699c.jpeg', 'https://makerworld.bblmw.com/makerworld/model/USdce52deb9ad668/design/2024-09-06_674d69057699c.jpeg', '["https://makerworld.bblmw.com/makerworld/model/USdce52deb9ad668/design/2024-09-06_674d69057699c.jpeg"]', '剖面锁结构教学模型（Cutaway Pin Tumbler Lock）', '可拆解观察锁芯与安全销的机械结构教具', '锁芯结构,机械教具,创客,MakerWorld', '28', 69.90, 89.90, '件', 30, 100, 1, 0, 0, 1, 1, UNIX_TIMESTAMP(), 1, 22.00, 0, 0, '0,1', 'MW26090600006', 'https://makerworld.com/en/models/626233-cutaway-pin-tumbler-lock-with-security-pins', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600006');

-- 3D打印耗材 / 打印工具
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/USdd0085315070c5/design/2024-12-27_7130ab9540804.jpg', 'https://makerworld.bblmw.com/makerworld/model/USdd0085315070c5/design/2024-12-27_7130ab9540804.jpg', '["https://makerworld.bblmw.com/makerworld/model/USdd0085315070c5/design/2024-12-27_7130ab9540804.jpg"]', 'PLA/PETG 线材防松夹（Spring Clip）', '适配多种线材卷，单手安装并可标记 PLA/PETG 类型', '线材夹,PLA,PETG,打印工具,MakerWorld', '34', 9.90, 12.90, '件', 20, 100, 1, 0, 1, 0, 1, UNIX_TIMESTAMP(), 1, 2.00, 0, 0, '0,1', 'MW26090600007', 'https://makerworld.com/en/models/919366-spring-clip', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600007');

-- 其他成品 / 节日装饰
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, soure_link, logistics, freight, min_qty)
SELECT 'https://makerworld.bblmw.com/makerworld/model/US6ae15a66fc6a9a/design/2024-11-06_fb13676e75d95.jpg', 'https://makerworld.bblmw.com/makerworld/model/US6ae15a66fc6a9a/design/2024-11-06_fb13676e75d95.jpg', '["https://makerworld.bblmw.com/makerworld/model/US6ae15a66fc6a9a/design/2024-11-06_fb13676e75d95.jpg"]', '礼品包装纸裁切器（Gift Paper Cutter）', '适配 9mm 刀片的节日包装辅助工具，免支撑打印；刀片需另备', '礼品包装,裁切器,节日装饰,MakerWorld', '35', 15.90, 22.90, '件', 10, 100, 1, 0, 1, 0, 1, UNIX_TIMESTAMP(), 1, 4.00, 0, 0, '0,1', 'MW26090600008', 'https://makerworld.com/en/models/762321-gift-paper-cutter', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'MW26090600008');

-- 为 R8 商品补齐默认规格、SKU、详情和分类辅助关系。
INSERT INTO eb_store_product_attr (product_id, attr_name, attr_values, type)
SELECT p.id, '规格', '默认', 0
FROM eb_store_product p
WHERE p.spu LIKE 'MW260906%'
  AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr a WHERE a.product_id = p.id AND a.type = 0);

UPDATE eb_store_product_attr a
JOIN eb_store_product p ON p.id = a.product_id
SET a.attr_values = '默认'
WHERE p.spu LIKE 'MW260906%' AND a.type = 0;

INSERT INTO eb_store_product_attr_value (product_id, suk, stock, price, image, `unique`, cost, ot_price, type, is_show)
SELECT p.id, '默认', p.stock, p.price, p.image, RIGHT(CONCAT('00000000', p.id), 8), p.cost, p.ot_price, 0, 1
FROM eb_store_product p
WHERE p.spu LIKE 'MW260906%'
  AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr_value v WHERE v.product_id = p.id AND v.type = 0);

INSERT INTO eb_store_product_attr_result (product_id, result, change_time, type)
SELECT p.id,
  JSON_OBJECT('attr', JSON_ARRAY(JSON_OBJECT('value', '规格', 'detailValue', '', 'attrHidden', '', 'detail', JSON_ARRAY('默认'))),
    'value', JSON_ARRAY(JSON_OBJECT('value1', '规格', 'detail', JSON_OBJECT('规格', '默认'), 'pic', p.image, 'price', p.price, 'cost', p.cost, 'ot_price', p.ot_price, 'stock', p.stock, 'id', 0))),
  UNIX_TIMESTAMP(), 0
FROM eb_store_product p
WHERE p.spu LIKE 'MW260906%'
  AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr_result r WHERE r.product_id = p.id AND r.type = 0);

INSERT INTO eb_store_product_description (product_id, description, type)
SELECT p.id,
  CONCAT('<p><b>', p.store_name, '</b></p><p>', p.store_info, '</p><p>模型来源：<a target="_blank" rel="noopener noreferrer" href="', p.soure_link, '">MakerWorld 模型页面</a></p><p>来源许可记录：CC0 / Creative Commons Public Domain。此处销售的是打印成品，不提供模型数字文件；上架前请再次核对来源页的最新许可与作者备注，并保留作者署名与来源链接。</p>'),
  0
FROM eb_store_product p
WHERE p.spu LIKE 'MW260906%'
  AND NOT EXISTS (SELECT 1 FROM eb_store_product_description d WHERE d.product_id = p.id AND d.type = 0);

INSERT INTO eb_store_product_cate (product_id, cate_id, add_time, cate_pid, status)
SELECT p.id, CAST(p.cate_id AS UNSIGNED), UNIX_TIMESTAMP(), c.pid, 1
FROM eb_store_product p
JOIN eb_store_category c ON c.id = CAST(p.cate_id AS UNSIGNED)
WHERE p.spu LIKE 'MW260906%'
  AND NOT EXISTS (SELECT 1 FROM eb_store_product_cate pc WHERE pc.product_id = p.id AND pc.cate_id = c.id);

COMMIT;
