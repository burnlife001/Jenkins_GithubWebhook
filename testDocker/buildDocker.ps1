# 切换到脚本所在目录
Set-Location $PSScriptRoot

# 停止并删除已存在的容器（如果有）
docker rm -f python-app 2>$null

# 直接运行容器并挂载当前目录
docker run -d --name python-app -p 5000:5000 -v ${PSScriptRoot}:/app python:3.9.18-slim python /app/app.py