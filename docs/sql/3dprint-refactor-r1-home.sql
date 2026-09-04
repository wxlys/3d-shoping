-- 3D 打印业务收敛重构：R1.3 首页装修模板清理
-- 保留 DIY 编辑能力，仅隐藏当前首页模板中已下线的营销组件。

SET NAMES utf8mb4;
START TRANSACTION;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'bargain', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'bargain', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'combination', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'combination', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'coupon', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'coupon', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'signIn', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'signIn', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'presale', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'presale', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'pointsMall', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'pointsMall', NULL, '$.*.name') IS NOT NULL;

UPDATE eb_diy
SET value = JSON_SET(value,
    REPLACE(JSON_UNQUOTE(JSON_SEARCH(value, 'one', 'liveBroadcast', NULL, '$.*.name')), '.name', '.isHide'), TRUE)
WHERE is_del = 0 AND JSON_VALID(value) AND JSON_SEARCH(value, 'one', 'liveBroadcast', NULL, '$.*.name') IS NOT NULL;

-- 默认首页导航改为业务入口；管理员仍可在装修页自行增删、排序和换图。
UPDATE eb_diy
SET value = JSON_SET(value,
    '$."1741225405161001".menuConfig.list',
    CAST('[
      {"img":"","show":true,"info":[{"title":"标题","value":"商品分类","tips":"请输入导航标题","max":4},{"title":"链接","value":"/pages/goods_cate/goods_cate","tips":"请输入链接","max":100}]},
      {"img":"","show":true,"info":[{"title":"标题","value":"定制打印","tips":"请输入导航标题","max":4},{"title":"链接","value":"/pages/print/inquiry/index","tips":"请输入链接","max":100}]},
      {"img":"","show":true,"info":[{"title":"标题","value":"我的询价","tips":"请输入导航标题","max":4},{"title":"链接","value":"/pages/print/inquiry_list/index","tips":"请输入链接","max":100}]},
      {"img":"","show":true,"info":[{"title":"标题","value":"我的文件","tips":"请输入导航标题","max":4},{"title":"链接","value":"/pages/print/files/index","tips":"请输入链接","max":100}]},
      {"img":"","show":true,"info":[{"title":"标题","value":"打印指南","tips":"请输入导航标题","max":4},{"title":"链接","value":"/pages/extension/news_list/index","tips":"请输入链接","max":100}]}
    ]' AS JSON),
    '$."1741225405161001".number.tabVal', 2)
WHERE id = 8 AND is_del = 0 AND JSON_VALID(value);

COMMIT;
