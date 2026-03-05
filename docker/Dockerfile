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

# 安装 PyYAML 用于处理 pnpm-workspace.yaml
RUN pip install pyyaml

# Git 配置
# 配置git全局设置
RUN git config --global --add url."https://github.com/".insteadOf git@github.com: \
    && git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ \
    && git config --global --add url."https://github.com/".insteadOf git@github.com:/ \
    && git config --global --add safe.directory "*"

WORKDIR /app

RUN git clone https://github.com/QVerisAI/QVerisBot.git .

# 确保 pnpm-workspace.yaml 中 onlyBuiltDependencies 包含所有必需的包
RUN python3 << 'EOF'
import yaml
import sys
import os

# 读取pnpm-workspace.yaml
with open('pnpm-workspace.yaml', 'r', encoding='utf-8') as f:
    config = yaml.safe_load(f)

# 确保onlyBuiltDependencies存在
if 'onlyBuiltDependencies' not in config:
    config['onlyBuiltDependencies'] = []

# 必需的依赖列表（包含所有可能的构建依赖）
required_deps = [
    "@tloncorp/api",
    "@tloncorp/api-beta",  # 添加完整的github URL变体
    "@lydell/node-pty",
    "@matrix-org/matrix-sdk-crypto-nodejs",
    "@napi-rs/canvas",
    "@whiskeysockets/baileys",
    "authenticate-pam",
    "esbuild",
    "node-llama-cpp",
    "protobufjs",
    "sharp"
]

# 添加缺失的依赖
current_deps = set(config['onlyBuiltDependencies'])
for dep in required_deps:
    if dep not in current_deps:
        config['onlyBuiltDependencies'].append(dep)
        print(f"Added: {dep}")

# 排序依赖列表（保持一致性）
config['onlyBuiltDependencies'] = sorted(config['onlyBuiltDependencies'])

# 写回pnpm-workspace.yaml
with open('pnpm-workspace.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)

print(f"Total dependencies in onlyBuiltDependencies: {len(config['onlyBuiltDependencies'])}")
EOF

# 显示修改后的配置以供验证
RUN echo "=== Final pnpm-workspace.yaml ===" && cat pnpm-workspace.yaml

# 创建 .npmrc 配置文件，强制允许git依赖的脚本执行
RUN cat > .npmrc << 'NPMRC'
# 允许git包的脚本执行
hoist=true
shamefully-hoist=false
# 严格的peer依赖检查
strict-peer-dependencies=false
# Node.js版本管理
engine-strict=false
NPMRC

# 清理相关缓存以确保pnpm重新读取配置
RUN rm -rf node_modules .pnpm-debug.log pnpm-lock.yaml 2>/dev/null || true

# 使用--force标志强制安装，跳过某些检查
RUN pnpm install --force && pnpm ui:build && pnpm build && pnpm openclaw setup
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
