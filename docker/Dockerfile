# 多阶段构建：构建阶段
FROM almalinux:10.1-minimal AS builder

RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y git curl python3 python3-pip tar glibc-langpack-zh && dnf clean all && \
    localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 || true

# 安装 Node.js
RUN curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - && \
    dnf install -y nodejs && \
    node --version && npm --version
# 安装 pnpm
RUN npm install -g pnpm

# 安装 PyYAML 用于处理 pnpm-workspace.yaml
RUN pip install pyyaml

# Git 配置
RUN git config --global --add url."https://github.com/".insteadOf git@github.com: \
    && git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ \
    && git config --global --add url."https://github.com/".insteadOf git@github.com:/ \
    && git config --global --add safe.directory "*"

WORKDIR /app

RUN git clone --branch personal/zht  https://github.com/QVerisAI/QVerisBot.git .

# 处理 pnpm-workspace.yaml 和 package.json 配置
RUN python3 << 'EOF'
import yaml
import os
import glob

# 必需的依赖列表
required_deps = [
    "@tloncorp/api",
    "@tloncorp/api-beta",
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

def update_workspace_yaml(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        if config is None:
            config = {}
        
        if 'onlyBuiltDependencies' not in config:
            config['onlyBuiltDependencies'] = []
        
        current_deps = set(config['onlyBuiltDependencies'])
        added = []
        for dep in required_deps:
            if dep not in current_deps:
                config['onlyBuiltDependencies'].append(dep)
                added.append(dep)
        
        if added or 'onlyBuiltDependencies' not in config:
            config['onlyBuiltDependencies'] = sorted(config['onlyBuiltDependencies'])
            
            with open(filepath, 'w', encoding='utf-8') as f:
                yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
            
            status = "UPDATED" if added else "VERIFIED"
            print(f"{status}: {filepath}")
            if added:
                for dep in added:
                    print(f"  + {dep}")
        else:
            print(f"OK: {filepath}")
        
        return True
    except Exception as e:
        print(f"ERROR in {filepath}: {e}")
        return False

# 更新工作区配置
root_yaml = 'pnpm-workspace.yaml'
if os.path.exists(root_yaml):
    update_workspace_yaml(root_yaml)

for yaml_file in glob.glob('**/pnpm-workspace.yaml', recursive=True):
    if yaml_file != root_yaml:
        update_workspace_yaml(yaml_file)

# 处理 package.json
for pkg_file in glob.glob('**/package.json', recursive=True):
    try:
        with open(pkg_file, 'r', encoding='utf-8') as f:
            import json
            data = json.load(f)
        
        if 'pnpm' in data and 'overrides' in data.get('pnpm', {}):
            if 'onlyBuiltDependencies' not in data.get('pnpm', {}):
                if 'pnpm' not in data:
                    data['pnpm'] = {}
                data['pnpm']['onlyBuiltDependencies'] = sorted(required_deps)
                with open(pkg_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2)
                print(f"UPDATED package.json: {pkg_file}")
    except:
        pass

print("\n=== Workspace configuration update completed ===")
EOF

# 创建 .npmrc
RUN cat > .npmrc << 'NPMRC'
hoist=true
shamefully-hoist=false
strict-peer-dependencies=false
engine-strict=false
NPMRC

# 更新 package.json 中的 pnpm 配置
RUN python3 << 'PYEOF'
import json
import os
import glob

required_deps = [
    "@tloncorp/api",
    "@tloncorp/api-beta",
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

for pkg_file in glob.glob('**/package.json', recursive=True):
    try:
        with open(pkg_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        modified = False
        
        if 'pnpm' not in data:
            data['pnpm'] = {}
        
        if 'onlyBuiltDependencies' not in data['pnpm'] or not data['pnpm']['onlyBuiltDependencies']:
            data['pnpm']['onlyBuiltDependencies'] = sorted(required_deps)
            modified = True
        else:
            current = set(data['pnpm']['onlyBuiltDependencies'])
            for dep in required_deps:
                if dep not in current:
                    data['pnpm']['onlyBuiltDependencies'].append(dep)
                    modified = True
            if modified:
                data['pnpm']['onlyBuiltDependencies'] = sorted(data['pnpm']['onlyBuiltDependencies'])
        
        if modified:
            with open(pkg_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
            print(f"UPDATED: {pkg_file}")
    except Exception as e:
        pass

print("=== package.json pnpm configuration complete ===")
PYEOF

# 安装依赖并构建（在构建阶段完成所有重型操作）
RUN pnpm install --recursive --force
RUN pnpm ui:build
RUN pnpm build
RUN pnpm openclaw setup

# 裁剪为仅生产依赖，减小最终镜像体积
RUN pnpm prune --prod && pnpm store prune || true

# 运行时阶段
FROM almalinux:10.1-minimal

RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y curl python3 python3-pip tar glibc-langpack-zh fontconfig && dnf clean all && \
    localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 || true

# 安装中文字体
RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb || true && \
    dnf makecache && \
    dnf install -y \
        wqy-zenhei-fonts \
        google-noto-sans-cjk-fonts \
        dejavu-sans-fonts \
        google-noto-fonts-all && \
    dnf clean all && \
    fc-cache -fv

# 安装 Node.js 和 pnpm
RUN curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash - && \
    dnf install -y nodejs && \
    npm install -g pnpm

# 安装 Python 依赖
RUN pip install matplotlib numpy reportlab

WORKDIR /app

# 从构建阶段复制构建产物和依赖
COPY --from=builder /app /app

# 预配置 matplotlib
RUN mkdir -p /root/.config/matplotlib && \
    printf "font.family: sans-serif\nfont.sans-serif: WenQuanYi Zen Hei, Noto Sans CJK SC, DejaVu Sans\naxes.unicode_minus: False\n" \
        > /root/.config/matplotlib/matplotlibrc

# 暴露端口
EXPOSE 18789

# 设置环境变量
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 入口脚本
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
