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

# 使用for循环遍历数组并进行操作
for index in "${!APP_PORTS[@]}"; do
    # 获取当前需要操作的端口
    APP_PORT="${APP_PORTS[index]}"

    # 停止APP_PORT端口服务
    ln -nfs $NGINX_ROOT/snippets/upstreams/upstream-$APP_PORT.conf $NGINX_ROOT/snippets/upstream.conf
    sudo systemctl reload nginx

    JAVA_PID=$(ss -ltnp | grep :$APP_PORT | awk '{split($6, a, ","); gsub("pid=", "", a[2]); print a[2]}')
    echo "Stopping ${APP_PORT}, PID [${JAVA_PID}]..."
    kill -9 $JAVA_PID

    cd ${APP_HOME}
    nohup java -jar ruoyi-admin.jar -Xms2G -Xmx4G -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDateStamps  -XX:+PrintGCDetails -XX:NewRatio=1 -XX:SurvivorRatio=30 -XX:+UseParallelGC -XX:+UseParallelOldGC --server.port=$APP_PORT > /dev/null 2>&1 &

    while : ; do
        sleep 10
        IS_UP=$(lsof -i :$APP_PORT | wc -l)
        if [ "$IS_UP" -ge 1 ]; then
            break
        fi
    done
    echo "Process ${APP_PORT} is UP"
    sleep 30
done

ln -nfs $NGINX_ROOT/snippets/upstreams/upstream.conf $NGINX_ROOT/snippets/upstream.conf
sudo systemctl reload nginx

echo '<==========================================================================='
echo ''

# 正常退出
exit 0;
