-- 3D 打印改版节点 H：将打印配置挂载到后台“系统配置”菜单。
-- 旧版本已创建配置分类 200，但 pid=0、menus_id=0 时不会出现在现有配置页面中。

UPDATE `eb_system_config_tab`
SET `pid` = 129,
    `menus_id` = 23,
    `sort` = 99,
    `status` = 1
WHERE `id` = 200;
