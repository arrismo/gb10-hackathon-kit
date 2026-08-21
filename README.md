# nemoclaw-offline-kit

Prepare an external SSD/USB drive with the large assets needed for a DGX Spark / GB10 NemoClaw + OpenClaw + OpenShell local inference setup.

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

The goal is to avoid downloading tens of gigabytes over slow venue Wi‑Fi.

## What this project does not do

It does not build or include an agent, ship model weights or NVIDIA container images through Git, store credentials, modify/format drives, or guarantee a fully air-gapped install. Official upstream installers may still fetch small dependencies.

## Requirements

Preparation machine: macOS or Linux, Bash, Git, curl, Docker, Hugging Face CLI (`hf`), and NVIDIA NGC access for `nvcr.io`.

Target machine: NVIDIA DGX Spark / GB10, Linux ARM64, NVIDIA drivers, Docker.

## Quick start

```bash
git clone https://github.com/arrismo/gb10-hackathon-kit.git
cd gb10-hackathon-kit
./scripts/prepare-all.sh /Volumes/HACKATHON
```

Replace `/Volumes/HACKATHON` with your actual external drive path. Every script requires the drive path as its first argument. The scripts never format or erase the drive.

To only initialize the drive layout and check status without downloading large assets:

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

Do not put tokens or API keys into this repository or on the external drive.

## Why Qwen3.6

This kit pins `nvidia/Qwen3.6-35B-A3B-NVFP4` because it is the configured local DGX Spark / GB10 model target and its NVFP4 format keeps offline inference practical on NVIDIA hardware.

## Disk usage

The current prepared kit is approximately 33 GB, but use a drive with at least 100 GB free because images and models may change.

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

Copy the model to the GB10 internal SSD before inference. Run the saved NemoClaw installer and prefer the DGX Spark/local inference path. Cached assets are primarily a fallback if the official installer would otherwise perform a large download.

See `docs/` for architecture and troubleshooting notes.
