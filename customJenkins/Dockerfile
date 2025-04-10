# 基于官方 Jenkins 镜像
FROM jenkins/jenkins:lts

# 切换到 root 用户安装依赖
USER root

# 安装编译 Python 所需的依赖
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libffi-dev \
        libsqlite3-dev \
        curl \
        && rm -rf /var/lib/apt/lists/*

# 下载并编译 Python 3.11.9
RUN curl -O https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar -xzf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make -j $(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-3.11.9 Python-3.11.9.tgz

# 切换回 Jenkins 用户
USER jenkins


