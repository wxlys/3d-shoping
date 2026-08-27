# CRMEB 3D 打印服务系统部署包（独立环境）

## 隔离说明

- 使用独立的 compose 项目 `crmeb3d`，与服务器上已有容器完全隔离。
- 独立容器：crmeb3d-mysql / crmeb3d-redis / crmeb3d-php / crmeb3d-nginx。
- 独立数据卷：crmeb3d-mysql-data / crmeb3d-redis-data。
- 端口：nginx 对外 18080；MySQL 13306、Redis 16379 仅绑定本机 127.0.0.1，不对外。
- 不修改、不重启、不删除服务器上任何现有容器。

## 目录结构

```text
deploy-crmeb/
├── docker-compose.yml
├── Dockerfile.php
├── nginx.conf
├── app.env
├── sql/
│   └── crmeb.sql          # 从 ~/crmeb/crmeb/public/install/crmeb.sql 拷贝
└── crmeb/                 # PHP 代码根目录，从 ~/crmeb/crmeb 拷贝或软链
```

## 启动步骤（服务器上执行）

```bash
cd ~/3dprint-deploy
mkdir -p sql
cp ~/crmeb/crmeb/public/install/crmeb.sql sql/
ln -s ~/crmeb/crmeb crmeb        # 或 cp -r ~/crmeb/crmeb ./crmeb
docker compose up -d --build
docker compose ps
```

## 验证

```bash
curl http://127.0.0.1:18080/               # 返回页面或 JSON
docker compose logs -f php                 # 查看 PHP 日志
docker compose exec mysql mysql -uroot -pCrmeb@2026 crmeb -e "show tables;" | head
```

## 当前状态（2026-08-27）

- 4 个独立容器已运行：crmeb3d-mysql / crmeb3d-redis / crmeb3d-php / crmeb3d-nginx。
- 数据库：crmeb，157 张表已导入（导入时关闭 MySQL 严格模式，避免 CRMEB SQL 字段超长中断）。
- 用户端 H5：http://服务器IP:18080/ （已返回 200）。
- 管理后台：http://服务器IP:18080/admin/ （默认账号 admin，密码通常为 123456，登录后立即修改）。
- API 验证：http://服务器IP:18080/api/version 返回 JSON，商品接口 /api/products 返回 200。
- App：源码在 ~/crmeb/template/uni-app，需用 HBuilderX 编译 APK 后指向本服务。

## 已知注意事项

- 安装锁文件路径：`crmeb/public/install.lock`（不是 install/ 目录内），compose 启动命令已自动创建。
- 云服务器安全组需放行 18080 端口才能公网访问。
- MySQL 初始账号 root / Crmeb@2026，仅内网使用；生产环境务必修改。

## 后续

- 管理后台：`template/admin` 构建后产物放到 `crmeb/public/admin`，访问 `http://服务器IP:18080/admin`。
- 用户端 H5：`template/uni-app` 构建后部署到 `crmeb/public`。
- App：uni-app 编译的 APK 连接 `http://服务器IP:18080/api`。
