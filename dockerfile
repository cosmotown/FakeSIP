# 第一阶段：构建环境
FROM debian:bookworm-slim AS builder

# 安装构建依赖
# libnetfilter-queue-dev, libmnl-dev, libnfnetlink-dev 是编译所需的头文件
RUN apt-get update && apt-get install -y \
    build-essential \
    libnetfilter-queue-dev \
    libmnl-dev \
    libnfnetlink-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# 克隆源码（或者你可以选择 COPY 本地文件）
WORKDIR /app
RUN git clone https://github.com/MikeWang000000/FakeSIP.git .

# 编译项目
# 根据项目 Makefile，通常直接 make 即可
RUN make

# 第二阶段：运行环境
FROM debian:bookworm-slim

# 安装运行时依赖
# iptables/nftables 是必须的，因为程序需要操作防火墙规则
# libnetfilter-queue1 等是运行编译后程序所需的共享库
RUN apt-get update && apt-get install -y \
    libnetfilter-queue1 \
    libmnl0 \
    libnfnetlink0 \
    iptables \
    nftables \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /app/fakesip /usr/local/bin/fakesip

# 设置工作目录
WORKDIR /root

# 设置入口点
# 这里不设置具体的参数，允许用户在 docker run 时传入
ENTRYPOINT ["fakesip"]

# 默认显示帮助信息
CMD ["-h"]
