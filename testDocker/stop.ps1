Set-Location $PSScriptRoot
# 停止并删除容器
docker stop python-app
docker rm python-app

Write-Host "应用已停止"