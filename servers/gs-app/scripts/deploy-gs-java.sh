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
APP_PORTS=(4746 4747)

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

cd $NGINX_ROOT/snippets
# 先停止4747端口服务
ln -nfs $NGINX_ROOT/snippets/upstreams/upstream-4746.conf $NGINX_ROOT/snippets/upstream.conf
sudo systemctl reload nginx

JAVA_PID=$(ss -ltnp | grep :4747 | awk '{split($6, a, ","); gsub("pid=", "", a[2]); print a[2]}')
echo 'Stopping 4747 ...' $JAVA_PID
kill -9 $JAVA_PID

cd ${APP_HOME}
nohup java -jar ruoyi-admin.jar -Xms2G -Xmx4G -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps  -XX:+PrintGCDetails -XX:NewRatio=1 -XX:SurvivorRatio=30 -XX:+UseParallelGC -XX:+UseParallelOldGC --server.port=4747 > /dev/null 2>&1 &

while : ; do
    sleep 10
    IS_UP=$(lsof -i :4747 | wc -l)
    if [ "$IS_UP" -ge 1 ]; then
        break
    fi
done
echo 'Process 4747 is UP'
sleep 30

# 操作另外一个端口
ln -nfs $NGINX_ROOT/snippets/upstreams/upstream-4747.conf $NGINX_ROOT/snippets/upstream.conf
sudo systemctl reload nginx

JAVA_PID=$(ss -ltnp | grep :4746 | awk '{split($6, a, ","); gsub("pid=", "", a[2]); print a[2]}')
echo 'Stopping 4746 ...' $JAVA_PID
kill -9 $JAVA_PID

cd ${APP_HOME}
nohup java -jar ruoyi-admin.jar -Xms2G -Xmx4G -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps  -XX:+PrintGCDetails -XX:NewRatio=1 -XX:SurvivorRatio=30 -XX:+UseParallelGC -XX:+UseParallelOldGC --server.port=4746 > /dev/null 2>&1 &

while : ; do
    sleep 10
    IS_UP=$(lsof -i :4746 | wc -l)
    if [ "$IS_UP" -ge 1 ]; then
        break
    fi
done
echo 'Process 4746 is UP'
sleep 30

ln -nfs $NGINX_ROOT/snippets/upstreams/upstream.conf $NGINX_ROOT/snippets/upstream.conf
sudo systemctl reload nginx

echo '<==========================================================================='
echo ''

# 正常退出
exit 0;
