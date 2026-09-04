-- 3D 打印业务收敛重构：R2.1 后台菜单收敛
-- 只调整后台可见入口，不删除路由、控制器或共享权限数据。

SET NAMES utf8mb4;
START TRANSACTION;

-- 分销与佣金不属于当前业务，先关闭入口，后续节点仍保留底层代码。
UPDATE eb_system_menus SET is_show = 0 WHERE id IN (26, 28, 896, 3450, 29, 38);

-- 订单核心入口全部保留；收银订单是独立收银台入口，当前业务不需要。
UPDATE eb_system_menus SET is_show = 0 WHERE id = 760;

-- 活动只保留秒杀，其他营销模块不再出现在后台菜单。
UPDATE eb_system_menus SET menu_name = '活动管理', is_show = 1 WHERE id = 27;
UPDATE eb_system_menus SET is_show = 0 WHERE id IN (
  2460, 3446, 1023, 3425, 3420, 686, 731,
  32, 31, 909, 34, 30
);
UPDATE eb_system_menus SET is_show = 1 WHERE id = 33;

-- 装修能力完整保留，并显式打开首页、分类页、个人中心等管理入口。
UPDATE eb_system_menus SET is_show = 1 WHERE id IN (
  656, 566, 2461, 3453, 3461, 128, 902, 3464, 3460, 3459,
  3441, 3440, 657
);

COMMIT;
