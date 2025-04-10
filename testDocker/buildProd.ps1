# 切换到脚本所在目录
Set-Location $PSScriptRoot
# 构建生产环境镜像
docker build -t python-app .