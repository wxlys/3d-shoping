#!/bin/bash
set -e
cd ~/3dprint-deploy

H=$(docker compose exec -T php php -r "echo password_hash('123456', PASSWORD_BCRYPT);")
echo "new_hash_prefix=${H:0:7}"

docker compose exec -T mysql mysql -uroot -pCrmeb@2026 crmeb -e "UPDATE eb_system_admin SET pwd='$H' WHERE account='admin'; SELECT id,account,status,LEFT(pwd,4) AS pfx FROM eb_system_admin WHERE account='admin';" 2>/dev/null

docker compose exec -T php php -r "var_dump(password_verify('123456', '$H'));"
