# Stage 1: Builder Stage - 僅安裝STT所需依賴，移除TTS相關組件以節省CUDA記憶體
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS builder

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 安裝Python 3.10, pip, 建構工具，和STT所需的系統依賴
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3.10-dev \
    python3.10-venv \
    build-essential \
    git \
    libsndfile1 \
    libportaudio2 \
    ffmpeg \
    portaudio19-dev \
    python3-setuptools \
    python3.10-distutils \
    # 添加音頻處理所需的額外套件
    libasound2-dev \
    pulseaudio \
    alsa-utils \
    # 移除ninja-build，因為我們不再使用DeepSpeed
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Make python3.10 the default python/pip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Set working directory
WORKDIR /app

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# 安裝正確版本的PyTorch for CUDA 12.4
RUN pip install --no-cache-dir \
    torch==2.6.0 \
    torchvision==0.21.0 \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu124

# 移除DeepSpeed安裝，因為主要用於TTS
# ENV DS_BUILD_TRANSFORMER=1
# ENV DS_BUILD_CPU_ADAM=0
# ENV DS_BUILD_FUSED_ADAM=0
# ENV DS_BUILD_UTILS=0
# ENV DS_BUILD_OPS=0
# RUN echo "已跳過DeepSpeed安裝以節省CUDA記憶體" && \
#     echo "DeepSpeed主要用於TTS，現已禁用"

# Copy requirements file first to leverage Docker cache
COPY --chown=1001:1001 requirements.txt .

# 安裝requirements.txt中的Python依賴（已移除TTS相關套件）
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt \
    || (echo "pip install -r requirements.txt 失敗" && exit 1)

# 移除ctranslate2固定版本，因為主要用於TTS
# RUN pip install --no-cache-dir "ctranslate2<4.5.0"

# Copy the application code
COPY --chown=1001:1001 code/ ./code/

# --- Stage 2: Runtime Stage ---
# 使用較輕量的基礎映像，僅保留STT所需的運行時組件
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# 僅安裝STT應用所需的運行時依賴
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    libsndfile1 \
    ffmpeg \
    libportaudio2 \
    python3-setuptools \
    python3.10-distutils \
    # 移除build-essential, ninja-build, g++，因為運行時不需要編譯
    curl \
    gosu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Make python3.10 the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Set working directory for the application
WORKDIR /app/code

# Copy installed Python packages from the builder stage
RUN mkdir -p /usr/local/lib/python3.10/dist-packages
COPY --chown=1001:1001 --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# Copy the application code from the builder stage
COPY --chown=1001:1001 --from=builder /app/code /app/code

# <<<--- 移除所有TTS模型預下載以節省CUDA記憶體和映像大小 --->>>

# <<<--- 移除Silero VAD預下載 --->>>
# RUN echo "跳過Silero VAD模型預下載以節省記憶體..."
# 注意：如果STT需要VAD功能，可以在運行時按需下載

# <<<--- 移除faster-whisper預下載，改為運行時按需下載 --->>>
# ARG WHISPER_MODEL=base
# ENV WHISPER_MODEL=${WHISPER_MODEL}
# RUN echo "跳過faster_whisper模型預下載，將在運行時按需下載以節省記憶體..."

# <<<--- 移除SentenceFinishedClassification預下載 --->>>
# RUN echo "跳過SentenceFinishedClassification模型預下載以節省記憶體..."

# <<<--- 添加繁體中文語言環境支持 --->>>
RUN echo "設定繁體中文語言環境支持..." && \
    apt-get update && apt-get install -y locales && \
    locale-gen zh_TW.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=zh_TW.UTF-8
ENV LANGUAGE=zh_TW:zh
ENV LC_ALL=zh_TW.UTF-8

# Create a non-root user and group - DO NOT switch to it here
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid 1001 --create-home appuser

# 確保目錄由appuser擁有 - 為volume/cache準備正確的運行時權限
RUN mkdir -p /home/appuser/.cache && \
    chown -R appuser:appgroup /app && \
    chown -R appuser:appgroup /home/appuser && \
    # 移除root快取目錄的chown，因為我們跳過了模型預下載
    echo "跳過root快取目錄的權限設定，因為已移除模型預下載"

# Copy and set permissions for entrypoint script
COPY --chown=1001:1001 entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --- 容器以root身份啟動 ---

# --- 保留基本環境變數 ---
ENV HOME=/home/appuser
ENV CUDA_HOME=/usr/local/cuda
ENV PATH="${CUDA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
ENV PYTHONUNBUFFERED=1
ENV MAX_AUDIO_QUEUE_SIZE=50
ENV LOG_LEVEL=INFO
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV RUNNING_IN_DOCKER=true

# 移除DeepSpeed相關環境變數，因為已禁用TTS
# ENV DS_BUILD_OPS=1
# ENV DS_BUILD_CPU_ADAM=0
# ENV DS_BUILD_FUSED_ADAM=0
# ENV DS_BUILD_UTILS=0
# ENV DS_BUILD_TRANSFORMER=1

# 保留快取目錄設定
ENV HF_HOME=${HOME}/.cache/huggingface
ENV TORCH_HOME=${HOME}/.cache/torch

# 添加繁體中文STT特定環境變數
ENV STT_LANGUAGE=zh-TW
ENV STT_MODEL=base

# Expose the port the FastAPI application runs on
EXPOSE 8000

# Set the entrypoint script - This runs as root
ENTRYPOINT ["/entrypoint.sh"]
# Define the default command - This is passed as "$@" to the entrypoint script
CMD ["python", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
