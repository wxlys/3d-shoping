-- R7.3 个人中心只保留业务入口
-- 执行前必须备份数据库。脚本可重复执行。

SET NAMES utf8mb4;
START TRANSACTION;

-- 商品占位数据只服务首页推荐，个人中心不展示商品流或其标题。
UPDATE eb_theme
SET user_data = JSON_SET(user_data,
  '$.value."1772524664735006".isHide', TRUE,
  '$.value."1772524664735007".isHide', TRUE,
  '$.value."1772524664735005".menuConfig.list', JSON_ARRAY(
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[0]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[1]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[5]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[6]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[8]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[7]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[2]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[3]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[4]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[9]'),
    JSON_EXTRACT(user_data, '$.value."1772524664735005".menuConfig.list[10]')))
WHERE is_use = 1 AND JSON_VALID(user_data);

COMMIT;
