#!/bin/bash
#
# Deploy GlassesShop Vue Project
#
# Edit at 2024-07-22 by Smile

echo '=======================' $(date +"%Y-%m-%d %H:%M:%S") '===============================>'

ACTION=$1

# 项目目录
project_path="/data/wwwroot/gs-web-vue"
cd "$project_path/source"

# 拉取代码
echo "拉取代码"
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
    echo '开始构建项目（yarn build）'
    build_output=$(yarn build 2>&1)
    # 检查$build_output变量中是否包含错误信息
    if echo "$build_output" | grep -q "error during build"; then
        # 输出构建错误详情
        echo "构建失败，输出结果包含错误信息并回滚目录"
        echo "$build_output"
        cd "$project_path/version"
        rm -rf $version_path
        exit 1
    else
        echo "构建成功，输出构建成功的详情（如有需要）"
        #echo "$build_output"
    fi

    # 将Assets目录同步到CDN
    if [ "${ACTION,,}"x = "upload"x ]; then
        rsync -avzl -e "ssh -o HostKeyAlgorithms=+ssh-dss -i ~/.ssh/id_rsa" $version_path/dist/client/assets/ sshacs@glassesshop-static.rsync.upload.akamai.com:/1343177/v2/assets
    fi

    # 设置软链接
    ln -nfs $version_path "$project_path/current"

    # PM2重启项目
    pm2 restart gs-vue-ssr

    # 删除过期的目录(默认删除5天前的过期目录), 并保存最新 3个文件夹
    reservedNum=3
    currentDate=`date +%s`
    let isDeleted=24*3600*5
    for file in $project_path/version/*; do
        folderNum=$(ls -l $project_path/version | grep 'source' | wc -l)
        if [ $folderNum -gt $reservedNum ]; then
            createdTime=`stat -c %Y $file`
            if [ $[ $currentDate - $createdTime ] -gt $isDeleted ]; then
                echo "Delete File: $file"
                /bin/rm -rf $file
            fi
        fi
    done
fi

echo '<==========================================================================='
echo ''

# 正常退出
exit 0;
