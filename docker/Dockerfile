FROM almalinux:10.1-minimal
RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y net-tools git curl python3 python3-pip tar glibc-langpack-zh && dnf clean all && \
    # generate Chinese locale to avoid locale warnings during `docker exec`
    localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 || true

# 安装中文字体支持并刷新缓存
# EPEL provides a packaged set of Noto CJK fonts; install that instead of
# downloading manually.  (Note: the package name is `google-noto-sans-cjk-fonts`.)
RUN dnf install -y fontconfig epel-release && \
    # enable CRB to satisfy some EPEL dependencies if needed
    dnf config-manager --set-enabled crb || true && \
    dnf makecache && \
    dnf install -y \
        wqy-zenhei-fonts \
        # microhei is not available in AlmaLinux/EPEL; zenhei provides Chinese support
        google-noto-sans-cjk-fonts \
        # pick a DejaVu family package, not "fonts-dejavu"
        dejavu-sans-fonts \
        # include all Noto fonts for completeness
        google-noto-fonts-all && \
    dnf clean all && \
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
# add package to pnpms allowlist so git-hosted deps with build scripts can run
# pnpm reads onlyBuiltDependencies from pnpm-workspace.yaml
RUN grep -q "@tloncorp/api" pnpm-workspace.yaml || sed -i '/^onlyBuiltDependencies:/a\  - "@tloncorp/api"' pnpm-workspace.yaml
RUN echo "=== pnpm-workspace.yaml after patch ===" && head -20 pnpm-workspace.yaml
# 安装依赖
RUN pnpm install && pnpm ui:build && pnpm build && pnpm openclaw setup
# 安装 Python 依赖
RUN pip install matplotlib numpy reportlab

# 预配置 matplotlib 使用中文（镜像构建时生成，容器运行时由 entrypoint 进一步确认）
RUN mkdir -p /root/.config/matplotlib && \
    printf "font.family: sans-serif\nfont.sans-serif: WenQuanYi Zen Hei, Noto Sans CJK SC, DejaVu Sans\naxes.unicode_minus: False\n" \
        > /root/.config/matplotlib/matplotlibrc
# 暴露端口
EXPOSE 18789
# 设置环境变量
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
# ensure locale is available at runtime (should already be generated above)

# 使用入口脚本启动（关键修改）
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
