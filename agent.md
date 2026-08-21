# agent.md

## Project

Build a GitHub-ready repository for preparing an external drive with the large assets needed to run the NVIDIA NemoClaw + OpenClaw + OpenShell stack with local inference on a DGX Spark / GB10.

The purpose of this repository is to help hackathon participants or developers avoid downloading large models, container images, and runtime assets over slow venue Wi-Fi.

The repository must contain only scripts, configuration, documentation, and checksums. Do not commit model weights, Docker image tarballs, API keys, tokens, or other large/generated assets.

Suggested repository name:

`gb10-hackathon-kit`

## Goal

A user should be able to:

1. Clone this repository on macOS or Linux.
2. Connect an external SSD, USB drive, or WD Passport.
3. Run a small number of scripts.
4. Have the drive populated with:
   - NemoClaw installer/source
   - OpenShell ARM64 release assets
   - Qwen model weights
   - DGX Spark ARM64 vLLM Docker image
   - NemoClaw sandbox base image
   - required Node 22 ARM64 build images
5. Run a verification script that confirms the offline kit is complete.

The target runtime machine is NVIDIA DGX Spark / GB10 running Linux ARM64.

## Current Known Versions

Centralize all version information in `config/versions.env`.

Use these values initially:

```bash
NEMOCLAW_COMMIT=15ea6333a3eb8f905ec6063d4ffc98123f8a9232

MODEL_ID=nvidia/Qwen3.6-35B-A3B-NVFP4
MODEL_DIR_NAME=Qwen3.6-35B-A3B-NVFP4

OPENSHELL_VERSION=v0.0.101
OPENSHELL_ARM64_ASSET=openshell-aarch64-unknown-linux-musl.tar.gz
OPENSHELL_SHA256=b553d3bfc08e9354b990a10fb8abd976e039afeec2d3947f8a112018be40d296

VLLM_IMAGE=nvcr.io/nvidia/vllm:26.05.post1-py3@sha256:9204569b17ee4c0eff75194b8e6e458479c8aee18953b5ab9cf359fcdac659e2

NEMOCLAW_SANDBOX_IMAGE=ghcr.io/nvidia/nemoclaw/sandbox-base:latest

NODE_TRIXIE_IMAGE=node:22-trixie@sha256:a566dd560283ae5615c8bb86b58fa8a1b6f3c82b492473a061672416266625da
NODE_TRIXIE_SLIM_IMAGE=node:22-trixie-slim@sha256:db8a96a63e5264607ada2d206758876ebbed6a12be2ada7517793cbfb0c2a29c
```

Keep the implementation easy to update because these upstream versions may change.

## Repository Structure

Create:

```text
gb10-hackathon-kit/
├── README.md
├── LICENSE
├── .gitignore
├── config/
│   └── versions.env
├── scripts/
│   ├── prepare-drive.sh
│   ├── download-model.sh
│   ├── cache-containers.sh
│   ├── download-nemoclaw.sh
│   ├── download-openshell.sh
│   ├── verify-kit.sh
│   └── prepare-all.sh
├── docs/
│   ├── architecture.md
│   ├── troubleshooting.md
│   └── hackathon-day.md
└── checksums/
    └── README.md
```

Use POSIX-friendly Bash where practical. Bash-specific features are acceptable when they improve reliability.

All scripts should begin with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

## External Drive Layout

The scripts should create this structure on the user's external drive:

```text
HACKATHON/
├── models/
│   └── Qwen3.6-35B-A3B-NVFP4/
├── docker/
│   ├── nvidia-vllm-dgx-spark.tar
│   ├── nemoclaw-sandbox-base-arm64.tar
│   └── node22-arm64-build-images.tar
├── installers/
│   ├── nemoclaw.sh
│   └── openshell/
│       ├── install.sh
│       ├── openshell-aarch64-unknown-linux-musl.tar.gz
│       └── openshell-checksums-sha256.txt
├── repos/
│   └── NemoClaw/
└── docs/
```

Do not assume the drive is named `HACKATHON`.

Every script must accept the drive path as its first argument.

Example:

```bash
./scripts/prepare-drive.sh /Volumes/HACKATHON
```

If the path is omitted, print clear usage instructions and exit non-zero rather than guessing.

## Script Requirements

### `prepare-drive.sh`

Responsibilities:

- Validate that the supplied path exists.
- Create the required directory structure.
- Verify there is sufficient free disk space.
- Warn if available capacity is below 100 GB.
- Print a summary of created directories.
- Never format or erase the drive.

Example:

```bash
./scripts/prepare-drive.sh /Volumes/HACKATHON
```

### `download-model.sh`

Responsibilities:

- Source `config/versions.env`.
- Verify that the `hf` CLI exists.
- Explain that the user may need to run `hf auth login`.
- Download:

```text
nvidia/Qwen3.6-35B-A3B-NVFP4
```

into:

```text
<drive>/models/Qwen3.6-35B-A3B-NVFP4
```

Use:

```bash
hf download "$MODEL_ID" --local-dir "$DESTINATION"
```

- If the destination already appears complete, do not redownload unnecessarily.
- Print resulting directory size.

Do not store Hugging Face tokens anywhere in the repository or on the external drive.

### `cache-containers.sh`

Responsibilities:

- Verify Docker CLI is installed.
- Verify the Docker daemon is running.
- Pull Linux ARM64 images even when the preparation machine is macOS.
- Cache these images:

1. NVIDIA vLLM for DGX Spark:

```text
nvcr.io/nvidia/vllm:26.05.post1-py3@sha256:9204569b17ee4c0eff75194b8e6e458479c8aee18953b5ab9cf359fcdac659e2
```

2. NemoClaw sandbox base:

```text
ghcr.io/nvidia/nemoclaw/sandbox-base:latest
```

3. Node build images:

```text
node:22-trixie@sha256:a566dd560283ae5615c8bb86b58fa8a1b6f3c82b492473a061672416266625da

node:22-trixie-slim@sha256:db8a96a63e5264607ada2d206758876ebbed6a12be2ada7517793cbfb0c2a29c
```

Use:

```bash
docker pull --platform linux/arm64 ...
```

Save the images to:

```text
<drive>/docker/nvidia-vllm-dgx-spark.tar
<drive>/docker/nemoclaw-sandbox-base-arm64.tar
<drive>/docker/node22-arm64-build-images.tar
```

The two Node images should be saved into the same tar archive.

Print image and archive sizes after completion.

Do not run the ARM64 containers on the preparation machine.

For `nvcr.io`, detect authentication failures and print a clear explanation that the user needs NVIDIA NGC credentials and should run:

```bash
docker login nvcr.io
```

Do not request, capture, log, or store the user's NGC API key.

### `download-nemoclaw.sh`

Responsibilities:

- Download the official NemoClaw installer into:

```text
<drive>/installers/nemoclaw.sh
```

- Make it executable.
- Clone the official NVIDIA NemoClaw Git repository into:

```text
<drive>/repos/NemoClaw
```

- Checkout `NEMOCLAW_COMMIT`.
- Verify the checked-out commit.
- Save the commit hash into:

```text
<drive>/docs/nemoclaw-commit.txt
```

If the repository already exists, safely fetch and checkout the pinned commit rather than deleting it.

### `download-openshell.sh`

Responsibilities:

- Download the official OpenShell installer into:

```text
<drive>/installers/openshell/install.sh
```

- Download the pinned ARM64 release:

```text
openshell-aarch64-unknown-linux-musl.tar.gz
```

for:

```text
v0.0.101
```

- Download:

```text
openshell-checksums-sha256.txt
```

- Verify the archive against both the official checksum file and the pinned checksum in `versions.env`.

Expected checksum:

```text
b553d3bfc08e9354b990a10fb8abd976e039afeec2d3947f8a112018be40d296
```

Fail loudly if checksum verification fails.

### `verify-kit.sh`

This is an important part of the project.

It should inspect the external drive and produce a clear status report.

Example output:

```text
NemoClaw Offline Kit Verification

[✓] Qwen3.6 model found
    Size: 22G

[✓] NVIDIA vLLM image archive
    Size: 8.9G

[✓] NemoClaw sandbox archive
    Size: 429M

[✓] Node 22 ARM64 build image archive
    Size: 506M

[✓] NemoClaw installer
[✓] NemoClaw repository
[✓] NemoClaw commit matches configured version

[✓] OpenShell ARM64 archive
[✓] OpenShell checksum verified

Total kit size: 33G

READY
```

Do not hardcode the exact sizes as pass/fail requirements because upstream packaging may change.

Verification should include:

- required file existence
- non-empty files
- model directory existence
- OpenShell SHA256
- NemoClaw Git commit
- available drive capacity
- Docker tar readability where practical

Exit:

- `0` if required assets pass
- non-zero if required assets are missing or invalid

### `prepare-all.sh`

Provide one convenience entry point:

```bash
./scripts/prepare-all.sh /Volumes/HACKATHON
```

It should run:

1. `prepare-drive.sh`
2. `download-nemoclaw.sh`
3. `download-openshell.sh`
4. `download-model.sh`
5. `cache-containers.sh`
6. `verify-kit.sh`

Print progress between stages.

If one stage fails, stop and tell the user which stage failed.

Do not swallow errors.

## README

Write a clear README aimed at hackathon participants.

Include:

### What this project does

Explain that the project prepares an external drive with large dependencies for running:

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

The purpose is to avoid downloading tens of gigabytes over slow venue Wi-Fi.

### What this project does not do

Make clear:

- It does not build an agent.
- It does not include a pre-built agent.
- It does not ship model weights.
- It does not ship NVIDIA container images.
- It does not store user credentials.
- It does not modify or format external drives.
- It does not guarantee completely air-gapped installation because upstream installers may introduce new dependencies.

### Requirements

Preparation machine:

- macOS or Linux
- Bash
- Git
- curl
- Docker
- Hugging Face CLI
- NVIDIA NGC access for NVIDIA container registry

Target machine:

- NVIDIA DGX Spark / GB10
- Linux ARM64
- NVIDIA drivers
- Docker

### Quick Start

Example:

```bash
git clone <repo-url>
cd gb10-hackathon-kit

./scripts/prepare-all.sh /Volumes/HACKATHON
```

Also document running each stage independently.

### Credentials

Explain how credentials are used without collecting them.

For Hugging Face:

```bash
hf auth login
```

For NVIDIA NGC:

```bash
docker login nvcr.io
```

Never include tokens in examples.

### Disk usage

Explain that the current prepared kit is approximately 33 GB, but recommend at least 100 GB free because versions and models may change.

### Hackathon-day use

Keep this section concise.

Typical flow:

```bash
nvidia-smi
docker info
```

Locate the external drive.

Load cached containers:

```bash
docker load -i <drive>/docker/nvidia-vllm-dgx-spark.tar
docker load -i <drive>/docker/nemoclaw-sandbox-base-arm64.tar
docker load -i <drive>/docker/node22-arm64-build-images.tar
```

Copy the model to the GB10 internal SSD before inference.

Run the saved NemoClaw installer and prefer the DGX Spark/local inference path.

Explain that the cached assets are primarily a fallback if the official installer would otherwise perform a large download.

## `docs/architecture.md`

Describe the relationship among components:

```text
Application / Agent
        ↓
OpenClaw
        ↓
NemoClaw
        ↓
OpenShell sandbox/runtime
        ↓
local inference endpoint
        ↓
vLLM
        ↓
Qwen3.6-35B-A3B-NVFP4
        ↓
NVIDIA GB10
```

Explain:

- OpenClaw is the agent layer.
- NemoClaw integrates/configures the stack.
- OpenShell provides the sandbox/runtime/security boundary.
- vLLM serves the local model.
- Qwen is the local LLM.
- GB10 provides the NVIDIA compute.

## `docs/troubleshooting.md`

Include common issues:

### Docker daemon not running

Typical error:

```text
failed to connect to the docker API
```

Fix:

Start Docker Desktop or the Docker daemon and verify:

```bash
docker info
```

### NGC authentication failure

Tell the user to authenticate:

```bash
docker login nvcr.io
```

Do not instruct users to paste keys into project files.

### External drive path

macOS often uses:

```text
/Volumes/<name>
```

Linux often uses:

```text
/media/$USER/<name>
```

Never assume either location.

### Wrong architecture

All DGX Spark container pulls must use:

```text
--platform linux/arm64
```

### Model already downloaded

Avoid redownloading a complete local model directory.

### Large venue downloads

Explain that the repository exists specifically to avoid downloading the model and large containers on-site.

## `.gitignore`

At minimum:

```gitignore
.env
.env.*
*.tar
*.tar.gz
models/
docker/
downloads/
.DS_Store
ngc-api-key*
*token*
```

Do not accidentally ignore source tarballs that are deliberately part of test fixtures if tests are added later.

## Security Requirements

Never:

- persist passwords
- persist Hugging Face tokens
- persist NVIDIA NGC API keys
- print secrets
- put credentials into command history intentionally
- include credentials in generated files

Do not use `curl` with embedded credentials.

Do not disable TLS verification.

Verify downloaded OpenShell artifacts using SHA256.

Use pinned digests where available.

## Testing

Add lightweight shell tests or a test script where practical.

At minimum test:

- missing drive argument
- nonexistent drive path
- missing Docker daemon
- missing `hf`
- verification with missing artifacts
- checksum mismatch detection
- successful directory creation

Scripts should work from any current working directory. Resolve the repository root relative to the script location instead of assuming the user runs commands from the repo root.

## UX

The scripts should be approachable for developers who are not experts in Docker or NVIDIA infrastructure.

Prefer output like:

```text
[1/6] Preparing drive...
[2/6] Downloading NemoClaw...
[3/6] Downloading OpenShell...
[4/6] Downloading local model...
[5/6] Caching ARM64 containers...
[6/6] Verifying kit...

✓ Offline kit ready
```

Error messages should explain both what failed and what the user should do next.

Avoid excessive abstraction or dependencies.

Use standard shell tools whenever possible.

## Non-Goals

Do not:

- build the hackathon agent
- create OpenClaw agent logic
- create mock HR data
- integrate external APIs
- build a UI
- distribute NVIDIA container images
- distribute Qwen model weights through Git
- add Terraform, Kubernetes, or unnecessary infrastructure

Keep this repository focused entirely on preparing and verifying the portable GB10/NemoClaw offline development kit.

## Definition of Done

The project is complete when a user can clone the repository and run:

```bash
./scripts/prepare-all.sh /path/to/external-drive
```

and the script prepares a drive containing the model, pinned runtime assets, cached ARM64 Docker images, installers, source repositories, and verification metadata needed to substantially reduce network dependency when setting up NemoClaw + OpenClaw + OpenShell + local vLLM on a DGX Spark / GB10.
