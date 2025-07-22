
# 繁體中文即時語音聊天系統 (STT專用版)

> **🎯 專為語音輸入、文字輸出而優化，移除TTS功能以節省CUDA記憶體**

這是一個針對繁體中文優化的即時語音聊天系統，專注於語音轉文字（STT）功能。系統已移除所有文字轉語音（TTS）組件以大幅減少CUDA記憶體使用並提高穩定性。

## ✨ 主要特色

- 🎤 **高品質繁體中文語音識別** - 基於Whisper多語言模型
- 💬 **即時語音轉文字** - 支援實時語音輸入轉換
- 🚀 **記憶體優化** - 移除TTS相關組件，大幅減少CUDA記憶體需求
- 🧠 **智能對話** - 整合LLM提供智能文字回覆
- 🌐 **Web介面** - 現代化的瀏覽器介面
- 🐳 **Docker支援** - 容器化部署，易於管理

## 🔧 系統需求

### 硬體需求
- **記憶體**: 建議16GB+ RAM
- **GPU**: NVIDIA GPU（支援CUDA 12.4）
- **CUDA記憶體**: 4-8GB（相較原版大幅減少）

### 軟體需求
- Docker & Docker Compose
- NVIDIA Container Toolkit

## 🚀 快速開始

### 1. 環境準備
```bash
# 確保Docker有適當權限
sudo usermod -aG docker $USER
# 重新登入或使用newgrp docker

# 確認NVIDIA Docker支援
nvidia-docker --version
```

### 2. 構建與運行
```bash
# 克隆專案
git clone <repository-url>
cd RealtimeVoiceChat

# 使用Docker Compose構建並啟動
sudo docker compose up --build

# 或者手動構建（如果需要）
sudo docker build -t realtime-voice-chat-stt:latest .
```

### 3. 存取系統
- 開啟瀏覽器訪問: `http://localhost:8000`
- 允許麥克風權限
- 開始語音輸入，系統將輸出文字回覆

## ⚙️ 配置選項

### 環境變數
```bash
# 音頻隊列大小（預設50）
MAX_AUDIO_QUEUE_SIZE=50

# 日誌級別
LOG_LEVEL=INFO

# STT語言設定
STT_LANGUAGE=zh-TW

# Whisper模型大小（tiny, base, small, medium, large）
STT_MODEL=base
```
