# AI4Bharat Speech Docker PoC

Dockerized offline-friendly PoC for:

- TTS: `ai4bharat/indic-parler-tts`
- Diarization: `pyannote/speaker-diarization-community-1`
- API: FastAPI
- GPU: NVIDIA CUDA container runtime

## Why this version differs from the simple sample

Indic Parler-TTS uses two tokenizers: one tokenizer for the transcript and one `description_tokenizer` from `model.config.text_encoder._name_or_path`. The app implements that pattern.

pyannote Community-1 can run offline from a cloned local model directory, and GPU must be enabled with `pipeline.to(torch.device("cuda"))`.

## Directory Layout

```text
ai4b_speech/
  app/
  input/
  models/
  output/
  scripts/
  wheels/
  Dockerfile
  requirements.txt
```

Create runtime folders if they do not exist:

```bash
mkdir -p input models output wheels
```

## One-Time Download On An Internet Machine

Both Hugging Face repos are gated. First accept the terms on Hugging Face for:

- `ai4bharat/indic-parler-tts`
- `pyannote/speaker-diarization-community-1`

Then:

```bash
pip install "huggingface_hub[cli]"
huggingface-cli login
bash scripts/download_assets.sh
```

Copy the full `ai4b_speech` directory to the offline Ubuntu GPU server.

## Build On Offline Ubuntu GPU Machine

```bash
docker build --build-arg INSTALL_MODE=offline -t ai4b-speech:latest .
```

If the machine has internet, you can build without the local wheelhouse:

```bash
docker build -t ai4b-speech:latest .
```

## Run

```bash
bash scripts/run_docker.sh
```

Manual equivalent:

```bash
docker run --rm \
  --gpus all \
  --ipc=host \
  -p 8000:8000 \
  -v "$(pwd)/models:/app/models:ro" \
  -v "$(pwd)/input:/app/input:ro" \
  -v "$(pwd)/output:/app/output" \
  ai4b-speech:latest
```

## Verify

```bash
curl http://localhost:8000/health
```

Generate TTS:

```bash
curl -X POST http://localhost:8000/tts \
  -H "Content-Type: application/json" \
  --data-binary @- <<'JSON'
{"text":"\u0928\u092e\u0938\u094d\u0924\u0947 \u0906\u092a\u0915\u093e \u0938\u094d\u0935\u093e\u0917\u0924 \u0939\u0948","output_name":"hindi_test.wav"}
JSON
```

The file appears at:

```text
output/hindi_test.wav
```

Diarize your own audio:

```bash
curl -X POST http://localhost:8000/diarize \
  -F "audio=@input/sample.wav" \
  -F "min_speakers=1" \
  -F "max_speakers=5"
```

Or run:

```bash
bash scripts/smoke_test.sh input/sample.wav
```

## B300 Notes

For NVIDIA B300/Blackwell-class GPUs, use a recent NVIDIA host driver and NVIDIA Container Toolkit. This project uses a CUDA 12.8 runtime image and PyTorch CUDA 12.8 wheels. Check on the host:

```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04 nvidia-smi
```

## Production Next Steps

- Put diarization and TTS behind separate worker queues.
- Chunk long audio before TTS/diarization jobs.
- Add request IDs and structured JSON logging.
- Add Prometheus metrics.
- Add model warmup endpoint or startup warmup.
- Add persistent object storage for input/output audio.
- Add batching only after measuring GPU memory and latency.
