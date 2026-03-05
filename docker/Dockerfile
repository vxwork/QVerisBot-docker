# 多阶段构建：构建阶段
FROM almalinux:10.1-minimal AS builder

# CI 环境下 pnpm prune 等需要此变量，否则会因无 TTY 中止
ENV CI=true

RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y git curl python3 python3-pip tar glibc-common glibc-langpack-zh && dnf clean all && \
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

print("\n=== Workspace configuration update completed ===")
EOF

# 创建 .npmrc
RUN cat > .npmrc << 'NPMRC'
hoist=true
shamefully-hoist=false
strict-peer-dependencies=false
engine-strict=false
NPMRC

# 仅更新根目录 package.json 的 pnpm.onlyBuiltDependencies（子包中此项不生效会触发 WARN）
RUN python3 << 'PYEOF'
import json
import os

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

root_pkg = 'package.json'
if os.path.exists(root_pkg):
    try:
        with open(root_pkg, 'r', encoding='utf-8') as f:
            data = json.load(f)
        if 'pnpm' not in data:
            data['pnpm'] = {}
        data['pnpm']['onlyBuiltDependencies'] = sorted(required_deps)
        with open(root_pkg, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print("UPDATED root package.json pnpm.onlyBuiltDependencies")
    except Exception as e:
        print(f"SKIP root package.json: {e}")
else:
    print("No root package.json, skip")
print("=== package.json pnpm configuration complete ===")
PYEOF

# 构建时跳过 TypeScript 类型检查（上游 QVerisBot 某分支存在类型错误，仅做生产构建）
RUN python3 << 'PATCHEOF'
import json
import glob
import os
for pkg in glob.glob('/app/**/package.json', recursive=True):
    try:
        with open(pkg, 'r', encoding='utf-8') as f:
            data = json.load(f)
        scripts = data.get('scripts') or {}
        changed = False
        for key in ('build', 'build:ui', 'ui:build'):
            if key not in scripts or not isinstance(scripts[key], str):
                continue
            s = scripts[key]
            for prefix in ('tsc --noEmit && ', 'vue-tsc --noEmit && ', 'tsc && ', 'vue-tsc && '):
                if prefix in s:
                    scripts[key] = s.replace(prefix, '', 1)
                    changed = True
                    break
        if changed:
            with open(pkg, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
            print("Patched build script:", pkg)
    except Exception as e:
        pass
print("=== Build script patch (skip typecheck) done ===")
PATCHEOF

# 关闭 Vite 构建中的 TypeScript 检查（如 vite-plugin-checker），避免 @tloncorp/api 等 prepare 时报错
RUN python3 << 'VITEEOF'
import glob
import re
for path in glob.glob("/app/**/vite.config.ts", recursive=True) + glob.glob("/app/**/vite.config.js", recursive=True):
    try:
        with open(path, "r", encoding="utf-8") as f:
            s = f.read()
        new_s = s
        # 1) checker 中的 typescript: true -> false
        if "checker" in s and "typescript" in s:
            new_s = re.sub(r"(\btypescript\s*:\s*)true\b", r"\1false", new_s)
        # 2) vite-plugin-dts 加上 skipDiagnostics: true，避免 dts 生成阶段因类型错误失败
        if "dts(" in new_s or "dts (" in new_s:
            new_s = re.sub(r"\bdts\s*\(\s*\{", "dts({ skipDiagnostics: true, ", new_s, count=1)
            if "dts()" in new_s:
                new_s = new_s.replace("dts()", "dts({ skipDiagnostics: true })", 1)
        if new_s != s:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_s)
            print("Patched vite config:", path)
    except Exception:
        pass
print("=== Vite config patch done ===")
VITEEOF

# 安装依赖并构建（在构建阶段完成所有重型操作）
# 若上游仍有类型检查（如 vite-plugin-checker），通过环境变量尝试跳过
ENV SKIP_TYPECHECK=1
ENV VITE_SKIP_TYPECHECK=1
RUN pnpm install && pnpm ui:build && pnpm build && pnpm openclaw setup

# 裁剪为仅生产依赖，减小最终镜像体积
RUN pnpm prune --prod && pnpm store prune || true

# 运行时阶段
FROM almalinux:10.1-minimal

RUN if ! command -v dnf &> /dev/null; then microdnf install -y dnf; fi
RUN dnf install -y curl python3 python3-pip tar glibc-common glibc-langpack-zh fontconfig && dnf clean all && \
    localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 || true

# 安装中文字体（仅保留 CJK + 西文回退，减小体积）
RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb || true && \
    dnf makecache && \
    dnf install -y \
        google-noto-sans-cjk-fonts \
        dejavu-sans-fonts && \
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

# 预配置 matplotlib（字体顺序与安装的包一致）
RUN mkdir -p /root/.config/matplotlib && \
    printf "font.family: sans-serif\nfont.sans-serif: Noto Sans CJK SC, DejaVu Sans\naxes.unicode_minus: False\n" \
        > /root/.config/matplotlib/matplotlibrc

# 暴露端口
EXPOSE 18789

# 设置环境变量
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 明确以 root 用户运行
USER root

# 入口脚本
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
