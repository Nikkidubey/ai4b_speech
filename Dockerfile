FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04

ARG INSTALL_MODE=online

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HUB_OFFLINE=1 \
    TRANSFORMERS_OFFLINE=1 \
    HF_HOME=/app/models/.cache \
    TTS_MODEL_PATH=/app/models/indic-parler-tts \
    DIARIZATION_MODEL_PATH=/app/models/pyannote-speaker-diarization-community-1 \
    DEVICE=cuda

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    ffmpeg \
    git \
    git-lfs \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
COPY wheels/ /wheels/

RUN python3 -m pip install --upgrade pip setuptools wheel && \
    if [ "$INSTALL_MODE" = "offline" ]; then \
      python3 -m pip install --no-index --find-links=/wheels torch torchaudio && \
      python3 -m pip install --no-index --find-links=/wheels -r requirements.txt parler-tts ; \
    else \
      python3 -m pip install --index-url https://download.pytorch.org/whl/cu128 torch torchaudio && \
      python3 -m pip install git+https://github.com/huggingface/parler-tts.git && \
      python3 -m pip install -r requirements.txt ; \
    fi

COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
