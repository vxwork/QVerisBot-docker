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

# 确保 pnpm-workspace.yaml 中 onlyBuiltDependencies 包含所有必需的包（包括嵌套工作区）
RUN python3 << 'EOF'
import yaml
import os
import glob

# 必需的依赖列表（包含所有可能的构建依赖）
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
    """更新单个pnpm-workspace.yaml文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        
        if config is None:
            config = {}
        
        # 确保onlyBuiltDependencies存在
        if 'onlyBuiltDependencies' not in config:
            config['onlyBuiltDependencies'] = []
        
        # 添加缺失的依赖
        current_deps = set(config['onlyBuiltDependencies'])
        added = []
        for dep in required_deps:
            if dep not in current_deps:
                config['onlyBuiltDependencies'].append(dep)
                added.append(dep)
        
        if added or 'onlyBuiltDependencies' not in config:
            # 排序依赖列表
            config['onlyBuiltDependencies'] = sorted(config['onlyBuiltDependencies'])
            
            # 写回pnpm-workspace.yaml
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

# 找到所有的pnpm-workspace.yaml或package.json文件
root_yaml = 'pnpm-workspace.yaml'
if os.path.exists(root_yaml):
    update_workspace_yaml(root_yaml)

# 递归查找所有子目录中的pnpm-workspace.yaml
for yaml_file in glob.glob('**/pnpm-workspace.yaml', recursive=True):
    if yaml_file != root_yaml:
        update_workspace_yaml(yaml_file)

# 同时处理package.json中可能包含的workspaces配置
for pkg_file in glob.glob('**/package.json', recursive=True):
    try:
        with open(pkg_file, 'r', encoding='utf-8') as f:
            import json
            data = json.load(f)
        
        # 检查是否是工作区package.json
        if 'pnpm' in data and 'overrides' in data.get('pnpm', {}):
            # 某些项目在package.json中配置pnpm
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

# 显示修改后的主配置以供验证
RUN echo "=== Root pnpm-workspace.yaml ===" && cat pnpm-workspace.yaml && \
    echo -e "\n=== All YAML files found ===" && find . -name "pnpm-workspace.yaml" -type f 2>/dev/null | head -10

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

# 递归搜索所有package.json并更新pnpm配置
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

# 处理所有package.json
for pkg_file in glob.glob('**/package.json', recursive=True):
    try:
        with open(pkg_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        modified = False
        
        # 确保pnpm配置存在
        if 'pnpm' not in data:
            data['pnpm'] = {}
        
        # 设置或更新onlyBuiltDependencies
        if 'onlyBuiltDependencies' not in data['pnpm'] or not data['pnpm']['onlyBuiltDependencies']:
            data['pnpm']['onlyBuiltDependencies'] = sorted(required_deps)
            modified = True
        else:
            # 合并依赖
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

# 清理相关缓存以确保pnpm重新读取配置
RUN rm -rf node_modules .pnpm-debug.log pnpm-lock.yaml 2>/dev/null || true

# 使用递归标志安装依赖
RUN pnpm install --recursive --force && pnpm ui:build && pnpm build && pnpm openclaw setup
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
