#!/bin/bash
#
# Deploy GlassesShop JAVA Project
#
# Edit at 2024-07-22 by Smile

echo '=======================' $(date +"%Y-%m-%d %H:%M:%S") '===============================>'
# Nginx配置目录
NGINX_ROOT=/data/nginx
# 项目目录
APP_HOME=/data/wwwroot/gs-java-v2/ruoyi-admin/target
# 应用端口
APP_PORT=$1          

cd ${APP_HOME}
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

nohup java -jar ruoyi-admin.jar -Xms2G -Xmx4G -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps  -XX:+PrintGCDetails -XX:NewRatio=1 -XX:SurvivorRatio=30 -XX:+UseParallelGC -XX:+UseParallelOldGC --server.port=${APP_PORT} > /dev/null 2>&1 &

echo '<==========================================================================='
echo ''

# 正常退出
exit 0;
