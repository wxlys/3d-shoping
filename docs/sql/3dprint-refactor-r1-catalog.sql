-- 3D 打印业务收敛重构：R1.1 分类初始化
-- 说明：保留现有分类 ID，避免装修配置和历史关联因分类重建而断链。
-- 执行前应完成数据库备份；本脚本仅面向当前项目的演示分类数据。

SET NAMES utf8mb4;
START TRANSACTION;

UPDATE eb_store_category SET pid = 0, cate_name = '家居生活', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 1;
UPDATE eb_store_category SET pid = 0, cate_name = '玩具与游戏', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 2;
UPDATE eb_store_category SET pid = 0, cate_name = '工具与配件', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 3;
UPDATE eb_store_category SET pid = 0, cate_name = '模型与摆件', sort = 4, pic = '', big_pic = '', is_show = 1 WHERE id = 4;
UPDATE eb_store_category SET pid = 0, cate_name = '创意礼品', sort = 5, pic = '', big_pic = '', is_show = 1 WHERE id = 5;
UPDATE eb_store_category SET pid = 0, cate_name = '教育与创客', sort = 6, pic = '', big_pic = '', is_show = 1 WHERE id = 6;
UPDATE eb_store_category SET pid = 0, cate_name = '3D打印耗材', sort = 7, pic = '', big_pic = '', is_show = 1 WHERE id = 7;
UPDATE eb_store_category SET pid = 0, cate_name = '其他成品', sort = 8, pic = '', big_pic = '', is_show = 1 WHERE id = 8;

UPDATE eb_store_category SET pid = 1, cate_name = '收纳整理', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 10;
UPDATE eb_store_category SET pid = 1, cate_name = '厨卫用品', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 12;
UPDATE eb_store_category SET pid = 1, cate_name = '家居装饰', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 13;
UPDATE eb_store_category SET pid = 2, cate_name = '益智玩具', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 15;
UPDATE eb_store_category SET pid = 2, cate_name = '桌游配件', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 16;
UPDATE eb_store_category SET pid = 2, cate_name = '模型玩具', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 17;
UPDATE eb_store_category SET pid = 3, cate_name = '夹具支架', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 18;
UPDATE eb_store_category SET pid = 3, cate_name = '维修辅助', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 19;
UPDATE eb_store_category SET pid = 3, cate_name = '数码配件', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 20;
UPDATE eb_store_category SET pid = 4, cate_name = '建筑模型', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 22;
UPDATE eb_store_category SET pid = 4, cate_name = '角色摆件', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 23;
UPDATE eb_store_category SET pid = 4, cate_name = '展示模型', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 24;
UPDATE eb_store_category SET pid = 5, cate_name = '个性礼物', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 25;
UPDATE eb_store_category SET pid = 5, cate_name = '纪念品', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 26;
UPDATE eb_store_category SET pid = 5, cate_name = '创意装饰', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 27;
UPDATE eb_store_category SET pid = 6, cate_name = '教具模型', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 28;
UPDATE eb_store_category SET pid = 6, cate_name = '创客零件', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 29;
UPDATE eb_store_category SET pid = 6, cate_name = '实验套件', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 30;
UPDATE eb_store_category SET pid = 7, cate_name = 'PLA 耗材', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 31;
UPDATE eb_store_category SET pid = 7, cate_name = 'PETG 耗材', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 32;
UPDATE eb_store_category SET pid = 7, cate_name = '打印工具', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 34;
UPDATE eb_store_category SET pid = 8, cate_name = '节日装饰', sort = 1, pic = '', big_pic = '', is_show = 1 WHERE id = 35;
UPDATE eb_store_category SET pid = 8, cate_name = '桌面用品', sort = 2, pic = '', big_pic = '', is_show = 1 WHERE id = 36;
UPDATE eb_store_category SET pid = 8, cate_name = '其他成品', sort = 3, pic = '', big_pic = '', is_show = 1 WHERE id = 37;
UPDATE eb_store_category SET pid = 5, cate_name = '礼赠包装', sort = 4, pic = '', big_pic = '', is_show = 1 WHERE id = 38;
UPDATE eb_store_category SET pid = 4, cate_name = '模型底座', sort = 4, pic = '', big_pic = '', is_show = 1 WHERE id = 39;
UPDATE eb_store_category SET pid = 3, cate_name = '维修替换件', sort = 4, pic = '', big_pic = '', is_show = 1 WHERE id = 40;

-- 当前版本不再使用旧演示分类图片，避免前端继续展示手机、家电等无关素材。
-- 首页装修仍保留，分类入口会通过现有动态接口读取上述分类。

COMMIT;
