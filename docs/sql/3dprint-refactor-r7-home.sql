-- R7.2 首页与个人中心业务化、成品占位数据
-- 执行前必须备份数据库。脚本可重复执行，不会重复创建占位商品。

SET NAMES utf8mb4;
START TRANSACTION;

-- 当前启用主题：首页导航改为真实业务入口，后五个旧商城入口隐藏。
UPDATE eb_theme
SET home_data = JSON_SET(home_data,
  '$.value."1772508227561001".menuConfig.list[0].info[0].value', '商品分类',
  '$.value."1772508227561001".menuConfig.list[0].info[1].value', '/pages/goods_cate/goods_cate',
  '$.value."1772508227561001".menuConfig.list[0].show', TRUE,
  '$.value."1772508227561001".menuConfig.list[1].info[0].value', '定制打印',
  '$.value."1772508227561001".menuConfig.list[1].info[1].value', '/pages/print/inquiry/index',
  '$.value."1772508227561001".menuConfig.list[1].show', TRUE,
  '$.value."1772508227561001".menuConfig.list[2].info[0].value', '我的询价',
  '$.value."1772508227561001".menuConfig.list[2].info[1].value', '/pages/print/inquiry_list/index',
  '$.value."1772508227561001".menuConfig.list[2].show', TRUE,
  '$.value."1772508227561001".menuConfig.list[3].info[0].value', '我的文件',
  '$.value."1772508227561001".menuConfig.list[3].info[1].value', '/pages/print/files/index',
  '$.value."1772508227561001".menuConfig.list[3].show', TRUE,
  '$.value."1772508227561001".menuConfig.list[4].info[0].value', '打印指南',
  '$.value."1772508227561001".menuConfig.list[4].info[1].value', '/pages/extension/news_list/index',
  '$.value."1772508227561001".menuConfig.list[4].show', TRUE,
  '$.value."1772508227561001".menuConfig.list[5].show', FALSE,
  '$.value."1772508227561001".menuConfig.list[6].show', FALSE,
  '$.value."1772508227561001".menuConfig.list[7].show', FALSE,
  '$.value."1772508227561001".menuConfig.list[8].show', FALSE,
  '$.value."1772508227561001".menuConfig.list[9].show', FALSE,
  '$.value."1772508227561003".isHide', TRUE,
  '$.value."1772508227561004".isHide', TRUE,
  '$.value."1772508227561006".isHide', TRUE,
  '$.value."1772508227561007".tabConfig.list[0].chiild[0].val', '精选商品',
  '$.value."1772508227561007".tabConfig.list[0].recommendType', 1,
  '$.value."1772508227561007".tabConfig.list[1].chiild[0].val', '首发新品',
  '$.value."1772508227561007".tabConfig.list[1].recommendType', 3,
  '$.value."1772508227561007".tabConfig.list[2].chiild[0].val', '好物好价',
  '$.value."1772508227561007".tabConfig.list[2].recommendType', 4,
  '$.value."1772508227561007".tabConfig.list[3].chiild[0].val', '热门推荐',
  '$.value."1772508227561007".tabConfig.list[3].recommendType', 2,
  '$.value."1772508227561008".richText.val', '<p style="text-align:center;"><b><font color="#333333" size="3">————&nbsp; 热门推荐&nbsp; ————</font></b></p>',
  '$.value."1772508227561009".recommendType', 2,
  '$.value."1772508227561000".tabListConfig.list[0].text.val', '家居生活',
  '$.value."1772508227561000".tabListConfig.list[0].dataType.tabVal', 1,
  '$.value."1772508227561000".tabListConfig.list[0].classPage.id', 1,
  '$.value."1772508227561000".tabListConfig.list[0].classPage.name', '家居生活',
  '$.value."1772508227561000".tabListConfig.list[1].text.val', '玩具游戏',
  '$.value."1772508227561000".tabListConfig.list[1].dataType.tabVal', 1,
  '$.value."1772508227561000".tabListConfig.list[1].classPage.id', 2,
  '$.value."1772508227561000".tabListConfig.list[1].classPage.name', '玩具与游戏',
  '$.value."1772508227561000".tabListConfig.list[2].text.val', '工具配件',
  '$.value."1772508227561000".tabListConfig.list[2].dataType.tabVal', 1,
  '$.value."1772508227561000".tabListConfig.list[2].classPage.id', 3,
  '$.value."1772508227561000".tabListConfig.list[2].classPage.name', '工具与配件',
  '$.value."1772508227561000".tabListConfig.list[3].text.val', '模型摆件',
  '$.value."1772508227561000".tabListConfig.list[3].dataType.tabVal', 1,
  '$.value."1772508227561000".tabListConfig.list[3].classPage.id', 4,
  '$.value."1772508227561000".tabListConfig.list[3].classPage.name', '模型与摆件',
  '$.value."1772508227561000".tabListConfig.list[4].text.val', '创意礼品',
  '$.value."1772508227561000".tabListConfig.list[4].dataType.tabVal', 1,
  '$.value."1772508227561000".tabListConfig.list[4].classPage.id', 5,
  '$.value."1772508227561000".tabListConfig.list[4].classPage.name', '创意礼品')
WHERE is_use = 1 AND JSON_VALID(home_data);

-- 用户中心保留资料、订单、售后、地址、收藏、秒杀、客服和浏览记录；隐藏会员、积分、领券、签到、账户和抽奖入口。
UPDATE eb_theme
SET user_data = JSON_SET(user_data,
  '$.value."1772524664735000".memberConfig.list', JSON_ARRAY(),
  '$.value."1772524664735000".rightEntryConfig.list', JSON_ARRAY(),
  '$.value."1772524664735004".isHide', TRUE,
  '$.value."1772524664735005".menuConfig.list[2].show', FALSE,
  '$.value."1772524664735005".menuConfig.list[3].show', FALSE,
  '$.value."1772524664735005".menuConfig.list[4].show', FALSE,
  '$.value."1772524664735005".menuConfig.list[9].show', FALSE,
  '$.value."1772524664735005".menuConfig.list[10].show', FALSE,
  '$.value."1772524664735006".titleConfig.value', '热门推荐',
  '$.value."1772524664735007".recommendType', 2)
WHERE is_use = 1 AND JSON_VALID(user_data);

-- 占位成品。SPU 固定用于幂等识别，后续可在后台直接编辑名称、图片、价格、库存和推荐归属。
INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, logistics, freight, min_qty)
SELECT '/statics/system_images/placeholder-home.svg', '/statics/system_images/placeholder-home.svg', '["/statics/system_images/placeholder-home.svg"]', '桌面收纳托盘（占位）', '成品商城占位商品，可在后台直接替换', '收纳,家居,3D打印', '10', 29.90, 39.90, '件', 40, 100, 1, 1, 0, 1, 0, UNIX_TIMESTAMP(), 1, 10.00, 0, 0, '0,1', 'PH26090600001', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'PH26090600001');

INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, logistics, freight, min_qty)
SELECT '/statics/system_images/placeholder-toy.svg', '/statics/system_images/placeholder-toy.svg', '["/statics/system_images/placeholder-toy.svg"]', '创意拼装小车（占位）', '成品商城占位商品，可在后台直接替换', '玩具,拼装,3D打印', '15', 49.90, 59.90, '件', 30, 100, 1, 1, 0, 0, 1, UNIX_TIMESTAMP(), 1, 18.00, 0, 0, '0,1', 'PH26090600002', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'PH26090600002');

INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, logistics, freight, min_qty)
SELECT '/statics/system_images/placeholder-tool.svg', '/statics/system_images/placeholder-tool.svg', '["/statics/system_images/placeholder-tool.svg"]', '多功能理线夹（占位）', '成品商城占位商品，可在后台直接替换', '工具,配件,理线', '18', 12.90, 19.90, '件', 20, 100, 1, 1, 1, 0, 0, UNIX_TIMESTAMP(), 1, 3.00, 0, 0, '0,1', 'PH26090600003', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'PH26090600003');

INSERT INTO eb_store_product
  (image, recommend_image, slider_image, store_name, store_info, keyword, cate_id, price, ot_price, unit_name, sort, stock, is_show, is_hot, is_benefit, is_best, is_new, add_time, is_postage, cost, product_type, spec_type, activity, spu, logistics, freight, min_qty)
SELECT '/statics/system_images/placeholder-model.svg', '/statics/system_images/placeholder-model.svg', '["/statics/system_images/placeholder-model.svg"]', '建筑展示模型（占位）', '成品商城占位商品，可在后台直接替换', '模型,摆件,建筑', '22', 89.90, 109.90, '件', 10, 100, 1, 1, 1, 1, 1, UNIX_TIMESTAMP(), 1, 35.00, 0, 0, '0,1', 'PH26090600004', '1,2', 2, 1
WHERE NOT EXISTS (SELECT 1 FROM eb_store_product WHERE spu = 'PH26090600004');

SET @p1 = (SELECT id FROM eb_store_product WHERE spu = 'PH26090600001' LIMIT 1);
SET @p2 = (SELECT id FROM eb_store_product WHERE spu = 'PH26090600002' LIMIT 1);
SET @p3 = (SELECT id FROM eb_store_product WHERE spu = 'PH26090600003' LIMIT 1);
SET @p4 = (SELECT id FROM eb_store_product WHERE spu = 'PH26090600004' LIMIT 1);

INSERT INTO eb_store_product_attr (product_id, attr_name, attr_values, type)
SELECT p.id, '规格', '默认', 0 FROM eb_store_product p
WHERE p.spu LIKE 'PH2609060000_' AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr a WHERE a.product_id = p.id AND a.type = 0);

UPDATE eb_store_product_attr a JOIN eb_store_product p ON p.id = a.product_id
SET a.attr_values = '默认'
WHERE p.spu LIKE 'PH2609060000_' AND a.type = 0;

INSERT INTO eb_store_product_attr_value (product_id, suk, stock, price, image, `unique`, cost, ot_price, type, is_show)
SELECT p.id, '默认', p.stock, p.price, p.image, RIGHT(CONCAT('00000000', p.id), 8), p.cost, p.ot_price, 0, 1
FROM eb_store_product p
WHERE p.spu LIKE 'PH2609060000_' AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr_value v WHERE v.product_id = p.id AND v.type = 0);

INSERT INTO eb_store_product_attr_result (product_id, result, change_time, type)
SELECT p.id, JSON_OBJECT('attr', JSON_ARRAY(JSON_OBJECT('value', '规格', 'detailValue', '', 'attrHidden', '', 'detail', JSON_ARRAY('默认'))), 'value', JSON_ARRAY(JSON_OBJECT('value1', '规格', 'detail', JSON_OBJECT('规格', '默认'), 'pic', p.image, 'price', p.price, 'cost', p.cost, 'ot_price', p.ot_price, 'stock', p.stock, 'id', 0))), UNIX_TIMESTAMP(), 0
FROM eb_store_product p
WHERE p.spu LIKE 'PH2609060000_' AND NOT EXISTS (SELECT 1 FROM eb_store_product_attr_result r WHERE r.product_id = p.id AND r.type = 0);

INSERT INTO eb_store_product_description (product_id, description, type)
SELECT p.id, CONCAT('<p>', p.store_name, '</p><p>这是首页占位成品，请在后台商品编辑页替换为正式商品资料。</p>'), 0
FROM eb_store_product p
WHERE p.spu LIKE 'PH2609060000_' AND NOT EXISTS (SELECT 1 FROM eb_store_product_description d WHERE d.product_id = p.id AND d.type = 0);

INSERT INTO eb_store_product_cate (product_id, cate_id, add_time, cate_pid, status)
SELECT p.id, CAST(p.cate_id AS UNSIGNED), UNIX_TIMESTAMP(), c.pid, 1
FROM eb_store_product p JOIN eb_store_category c ON c.id = CAST(p.cate_id AS UNSIGNED)
WHERE p.spu LIKE 'PH2609060000_' AND NOT EXISTS (SELECT 1 FROM eb_store_product_cate pc WHERE pc.product_id = p.id AND pc.cate_id = c.id);

COMMIT;
