# Windows 本地源码运行（不使用 EXE）

源码目录：`E:\voicebox-dev`。原有 `E:\Voicebox` 安装和用户数据不变。

## 启动

先保持 Clash Verge 运行（本机已确认的代理端口：7897）。打开两个 PowerShell 终端：

```powershell
# 终端 1：后端，使用项目独立 Python 环境
cd E:\voicebox-dev
.\backend\venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 17493 --env-file .env
```

```powershell
# 终端 2：前端（需要已安装的 Bun）
cd E:\voicebox-dev
npm run dev:web -- --host 127.0.0.1
```

浏览器打开 http://127.0.0.1:5173 。后端健康检查：http://127.0.0.1:17493/health 。
关闭时在两个终端分别按 Ctrl+C。这里使用已有的网页前端，不启动 Tauri，也不需要 Rust。

## 下载配置

项目根目录的 `.env` 由 `uvicorn --env-file .env` 在导入后端前读取；只创建文件而不传入这个参数不会生效。
本机配置如下，不含账号或令牌，不修改全局环境变量：

```dotenv
HF_ENDPOINT=https://huggingface.co
VOICEBOX_MODELS_DIR=E:/voicebox-dev/data/models
HF_HUB_ETAG_TIMEOUT=30
HF_HUB_DOWNLOAD_TIMEOUT=60
HF_HUB_OFFLINE=0
TRANSFORMERS_OFFLINE=0
HTTP_PROXY=http://127.0.0.1:7897
HTTPS_PROXY=http://127.0.0.1:7897
NO_PROXY=localhost,127.0.0.1,::1
```

Windows 系统代理不一定被所有下载组件读取，因此显式设置 HTTP(S)_PROXY；NO_PROXY 保证本地前后端通信不经过代理。
端口改变时同步修改 `.env`；能直接访问 Hugging Face 时可移除两行代理设置。
环境中已存在的同名变量优先于 `.env`。这里不默认使用第三方镜像，也不关闭 TLS 证书校验。

模型缓存在 E 盘，开发版数据库、声音档案和音频在项目 `data` 中，不会自动导入 EXE 版数据。
本次验证目标是 **Qwen 0.6B Base**；界面中请选择这个模型。其他模型仍需单独下载。

## 可重复的模型检查

```powershell
cd E:\voicebox-dev
# 使用真正的 Voicebox 后端加载模型，缺失文件时允许下载
.\backend\venv\Scripts\python.exe -m scripts.check_qwen_model
# 下载后验证缓存可离线加载（不会修改 .env）
.\backend\venv\Scripts\python.exe -m scripts.check_qwen_model --offline
```

独立环境使用 CUDA 12.8 的 PyTorch/torchaudio 2.8.0 和 torchvision 0.23.0；不要单独升级其中一个。
前端依赖可用 `bun install --frozen-lockfile --filter @voicebox/web --filter @voicebox/app` 重装；无需安装官网 landing 页面依赖。

## 本次验证与范围

Qwen 0.6B 的 13 个文件已完整下载，实际后端已通过离线 CUDA 加载检查；在线 API 加载和网页连接也通过。尚未使用声音样本验证语音生成，其他引擎未验证。

本机缺少 MSVC/nmake，`misaki[ja]` 的 pyopenjtalk 构建失败。因此本地安装清单 `data/requirements-local.txt` 仅将 `misaki[en,ja,zh]` 改为 `misaki[en,zh]`，未修改上游 requirements；这不影响 Qwen。需要 Kokoro 日语时再安装 C++ 构建工具并补齐日语依赖。独立环境已安装 hf-xet 下载组件。
