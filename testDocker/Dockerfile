# 使用Python官方镜像作为基础镜像
FROM python:3.9

# 设置工作目录
WORKDIR /app

# 复制项目文件到容器中
COPY . /app

# 安装依赖
RUN pip install -r requirements.txt

# 设置启动命令
CMD ["python", "app.py"]
