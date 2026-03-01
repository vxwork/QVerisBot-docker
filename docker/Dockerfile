FROM almalinux:10.1-minimal
RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y net-tools git curl python3 python3-pip tar && dnf clean all

# 安装中文字体支持并刷新缓存
# install fontconfig and unzip, then download Noto CJK fonts directly
# from GitHub using the "latest" redirect so we don’t pin a release
# version (avoids 404/HTTP 22 errors).
RUN dnf install -y fontconfig unzip && \
    dnf clean all && \
    \
    curl -fsSL -o /tmp/NotoSansSC.zip \
        https://github.com/googlefonts/noto-cjk/releases/latest/download/Noto_Sans_CJK_sc.zip && \
    unzip -q /tmp/NotoSansSC.zip -d /usr/share/fonts/ && \
    rm -f /tmp/NotoSansSC.zip && \
    fc-cache -fv

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
RUN pip install matplotlib numpy reportlab

# 预配置 matplotlib 使用中文（镜像构建时生成，容器运行时由 entrypoint 进一步确认）
RUN mkdir -p /root/.config/matplotlib && \
    printf "font.family: sans-serif\nfont.sans-serif: Noto Sans CJK SC, DejaVu Sans\naxes.unicode_minus: False\n" \
        > /root/.config/matplotlib/matplotlibrc
# 暴露端口
EXPOSE 18789
# 使用入口脚本启动（关键修改）
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
