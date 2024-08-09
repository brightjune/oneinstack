#!/bin/bash
#
# Deploy GlassesShop Vue Project
#
# Edit at 2024-07-22 by Smile

echo '=======================' $(date +"%Y-%m-%d %H:%M:%S") '===============================>'

# 项目目录
project_path="/data/wwwroot/gs-web-vue"
cd "$project_path/source"

# 拉取代码
output=$(git pull 2>&1)

if [[ "$output" == *"Already up to date."* ]]; then
    # 没有新代码提交
    echo "No updates available. Exiting."
else
    cd $project_path

    # 新编译目录
    version_path="$project_path/version/source.`date +%Y%m%d%H%M%S`"

    cp -R "$project_path/source" $version_path

    cd $version_path

    # 项目编译
    yarn build

    # 设置软链接
    ln -nfs $version_path "$project_path/current"

    # PM2重启项目
    pm2 restart gs-vue-ssr

    # 将Assets目录同步到CDN
    rsync -avzl -e "ssh -o HostKeyAlgorithms=+ssh-dss -i ~/.ssh/id_rsa" $project_path/current/dist/client/assets/ sshacs@glassesshop-static.rsync.upload.akamai.com:/1343177/v2/assets
fi

echo '<==========================================================================='
echo ''

# 正常退出
exit 0;
