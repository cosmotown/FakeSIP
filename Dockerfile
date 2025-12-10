# ==========================================
# 第一阶段：编译构建环境
# ==========================================
FROM debian:bookworm-slim AS builder

# 1. 设置工作目录
WORKDIR /app

# 2. 安装编译所需的依赖库和工具
# build-essential: 包含 gcc, make 等
# libnetfilter-queue-dev 等: 编译所需的头文件
# 使用国内源或添加重试机制可以提高成功率，这里使用默认源并添加清理
RUN apt-get update && apt-get install -y \
    build-essential \
    libnetfilter-queue-dev \
    libmnl-dev \
    libnfnetlink-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. 【关键变更】将当前仓库的所有代码复制到容器中
# 这比在容器里 git clone 更稳定，因为它使用你当前仓库的代码快照
COPY . .

# 4. 执行编译
# 项目根目录有 Makefile，直接 make 即可生成可执行文件 'fakesip'
RUN make


# ==========================================
# 第二阶段：精简运行环境
# ==========================================
FROM debian:bookworm-slim

# 1. 安装运行时依赖
# 这些是动态链接库 (.so)，程序运行所必须
# iptables/nftables/iproute2: 程序内部需要调用这些命令来设置防火墙规则
RUN apt-get update && apt-get install -y \
    libnetfilter-queue1 \
    libmnl0 \
    libnfnetlink0 \
    iptables \
    nftables \
    iproute2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. 从构建阶段复制编译好的二进制文件到路径中
COPY --from=builder /app/fakesip /usr/local/bin/fakesip

# 3. 赋予可执行权限 (通常 COPY 后就有，但为了保险)
RUN chmod +x /usr/local/bin/fakesip

# 4. 设置容器入口点
# 这样 docker run <镜像> 后面直接跟参数即可
ENTRYPOINT ["fakesip"]

# 5. 默认参数 (显示帮助)
CMD ["-h"]
