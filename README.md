# gb10-hackathon-kit

Prepare an external drive for DGX Spark / GB10 demos.

It caches large NemoClaw, OpenShell, vLLM, Docker, and Qwen assets before hackathon day.

```text
OpenClaw
    ↓
NemoClaw / OpenShell
    ↓
vLLM
    ↓
Qwen3.6
    ↓
DGX Spark / GB10
```

Use this to avoid large downloads over venue Wi‑Fi.

## What this project does not do

It does not build an agent.
It does not ship model weights.
It does not ship Docker images.
It does not store credentials.
It does not format drives.
It does not guarantee a fully air-gapped install.

## Requirements

Preparation machine:

- macOS or Linux
- Bash
- Git
- curl
- Docker
- Hugging Face CLI (`hf`)
- NVIDIA NGC access for `nvcr.io`

Target machine:

- NVIDIA DGX Spark / GB10
- Linux ARM64
- NVIDIA drivers
- Docker

## Quick start

```bash
git clone https://github.com/arrismo/gb10-hackathon-kit.git
cd gb10-hackathon-kit
./scripts/prepare-all.sh /Volumes/HACKATHON
```

Replace `/Volumes/HACKATHON` with your drive path.

The scripts never format or erase the drive.

To only create folders and check status:

```bash
./scripts/prepare-drive.sh /Volumes/HACKATHON
./scripts/verify-kit.sh /Volumes/HACKATHON
```

Run stages independently:

```bash
./scripts/prepare-drive.sh /path/to/drive
./scripts/download-nemoclaw.sh /path/to/drive
./scripts/download-openshell.sh /path/to/drive
./scripts/download-model.sh /path/to/drive
./scripts/cache-containers.sh /path/to/drive
./scripts/verify-kit.sh /path/to/drive
```

## Credentials

Authenticate with upstream tools only:

```bash
hf auth login
docker login nvcr.io
```

Never put tokens or API keys in this repo.

## Why Qwen3.6

Qwen3.6 NVFP4 is the pinned local model for this DGX Spark / GB10 kit.

## Disk usage

The current kit is about 33 GB.
Use a drive with at least 100 GB free.

## External drive layout

```text
HACKATHON/
├── models/Qwen3.6-35B-A3B-NVFP4/
├── docker/*.tar
├── installers/nemoclaw.sh
├── installers/openshell/
├── repos/NemoClaw/
└── docs/
```

## Hackathon-day use

On the GB10:

```bash
nvidia-smi
docker info
```

Load cached containers:

```bash
docker load -i <drive>/docker/nvidia-vllm-dgx-spark.tar
docker load -i <drive>/docker/nemoclaw-sandbox-base-arm64.tar
docker load -i <drive>/docker/node22-arm64-build-images.tar
```

Copy the model to the GB10 internal SSD.
Run the saved NemoClaw installer.
Choose the DGX Spark / local inference path.

Cached assets are a fallback for large installer downloads.

See `docs/` for more details.
