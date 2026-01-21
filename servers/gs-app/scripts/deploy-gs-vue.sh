#!/bin/bash
#
# Deploy GlassesShop Vue Project
#
# Edit at 2025-07-18 by Smile

echo '=======================' $(date +"%Y-%m-%d %H:%M:%S") '===============================>'

# ------- 参数解析（顺序不限） -------
FORCE_BUILD=0
DO_UPLOAD=0

for arg in "$@"; do
    case "${arg,,}" in
        upload|--upload)
            DO_UPLOAD=1
            ;;
        force|--force)
            FORCE_BUILD=1
            ;;
        *)
            echo "Warning: 未知参数 '$arg'，已忽略"
            ;;
    esac
done

if [[ $FORCE_BUILD -eq 1 ]]; then
    echo "⚡ 强制构建模式已开启（忽略是否有新代码）"
fi
if [[ $DO_UPLOAD -eq 1 ]]; then
    echo "📤 上传模式已开启（会执行 rsync 同步）"
fi

# 项目根目录
project_path="/data/wwwroot/gs-web-vue"

# 1. 进入源码目录
cd "${project_path}/source" || {
    echo "Error: 源码目录不存在：${project_path}/source"
    exit 1
}

# 2. 拉取最新代码
echo "拉取代码..."
git_output=$(git pull 2>&1)
if [[ $? -ne 0 ]]; then
    echo "Error: git pull 失败："
    echo "${git_output}"
    exit 1
fi

# 3. 判断是否需要构建
if echo "${git_output}" | grep -q "Already up to date."; then
    if [[ $FORCE_BUILD -eq 1 ]]; then
        echo "No updates, 但因强制构建标志，继续执行构建流程。"
    else
        echo "No updates available. Exiting."
        exit 0
    fi
else
    echo "检测到代码更新，开始构建流程。"
fi

# 4. 准备新版本目录
version_path="${project_path}/version/source.$(date +%Y%m%d%H%M%S)"
echo "创建新版本目录：${version_path}"
cp -R "${project_path}/source" "${version_path}" || {
    echo "Error: 复制源码到新版本目录失败"
    exit 1
}

cd "${version_path}" || {
    echo "Error: 进入新版本目录失败"
    exit 1
}

# 5. 构建项目
echo "开始构建项目（yarn build）..."
yarn build 2>&1 | tee build.log
build_status=${PIPESTATUS[0]}
if [[ $build_status -ne 0 ]]; then
    echo "Error: 构建失败，日志如下："
    cat build.log
    echo "回滚并删除新版本目录..."
    cd "${project_path}/version"
    rm -rf "${version_path}"
    exit 1
fi
echo "构建成功。"

# 6. 同步 Assets 到 CDN（仅在 upload 模式）
if [[ $DO_UPLOAD -eq 1 ]]; then
    echo "开始同步 Assets 到 CDN..."
    #rsync -avzl -e "ssh -o HostKeyAlgorithms=+ssh-dss -i ~/.ssh/id_rsa" $version_path/dist/client/assets/ sshacs@glassesshop-static.rsync.upload.akamai.com:/1343177/v2/assets
    #rsync -avzl -e "ssh -o HostKeyAlgorithms=+ssh-dss -i ~/.ssh/id_rsa" $version_path/dist/client/assets/ gs-akamai:/1343177/v2/assets
    rsync -avzl \
        -e "ssh -o HostKeyAlgorithms=+ssh-dss -i ~/.ssh/id_rsa" \
        $version_path/dist/client/assets/ \
        gs-akamai:/1343177/v2/assets

    if [[ $? -ne 0 ]]; then
        echo "Error: rsync 同步失败，退出部署"
        exit 1
    fi
    echo "Assets 同步完成。"
fi

# 7. 切换软链接
echo "更新 current 软链接..."
ln -nfs "${version_path}" "${project_path}/current" || {
    echo "Error: 更新软链接失败"
    exit 1
}

# 8. 重启 PM2 服务
echo "重启 PM2 服务(使用reload重载)..."
pm2 reload gs-vue-ssr --update-env || {
    echo "Error: PM2 重启失败"
    exit 1
}

# 9. 清理旧版本：仅保留最近 3 个，并且删除 5 天前的
echo "开始清理过期版本..."
reservedNum=4
cd "${project_path}/version" || exit 1
ls -1dt source.* 2>/dev/null | tail -n +$reservedNum | while read -r dir; do
    if [[ -d "$dir" ]] && find "$dir" -maxdepth 0 -mtime +5 | grep -q .; then
        echo "删除过期版本：$dir"
        rm -rf "$dir"
    fi
done

echo '<==========================================================================='
echo ''

# 正常退出
exit 0
