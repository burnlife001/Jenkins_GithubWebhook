# 切换到脚本所在目录
Set-Location $PSScriptRoot

# 停止并删除已存在的容器（如果有）
docker stop python-app 2>$null
docker rm python-app 2>$null

# 确保安装了必要的包
docker run -d --name python-app `
    -p 5000:5000 `
    -v ${PSScriptRoot}/app:/app `
    python:3.9.18-slim `
    /bin/bash -c "pip install flask && python /app/app.py"

Write-Host "应用已启动，访问 http://localhost:5000 查看效果"