FROM almalinux:10.1-minimal
RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y net-tools git curl python3 python3-pip && dnf clean all
# 安装 Node.js
RUN curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - && \
    dnf install -y nodejs && \
    node --version && npm --version
# 安装 pnpm
RUN npm install -g pnpm
# Git 配置
# 配置git全局设置
RUN git config --global --add url."https://github.com/".insteadOf git@github.com: \
    && git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ \
    && git config --global --add url."https://github.com/".insteadOf git@github.com:/ \
    && git config --global --add safe.directory "*"

WORKDIR /app

RUN git clone https://github.com/QVerisAI/QVerisBot.git .
# 安装依赖
RUN pnpm install && pnpm ui:build && pnpm build && pnpm openclaw setup
# 安装 Python 依赖
RUN pip install matplotlib reportlab
# 暴露端口
EXPOSE 18789
# 使用入口脚本启动（关键修改）
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
