# Troubleshooting

## Docker daemon not running

Typical error:

```text
failed to connect to the docker API
```

Fix: start Docker Desktop or the Docker daemon and verify:

```bash
docker info
```

## NGC authentication failure

Authenticate with NVIDIA NGC before caching `nvcr.io` images:

```bash
docker login nvcr.io
```

Never paste API keys into project files.

## External drive path

macOS often uses:

```text
/Volumes/<name>
```

Linux often uses:

```text
/media/$USER/<name>
```

Do not assume either location; pass the real path to each script.

## Wrong architecture

All DGX Spark container pulls must use:

```text
--platform linux/arm64
```

The cache script does this even when run from macOS.

## Model already downloaded

`download-model.sh` checks for an existing non-empty model directory and avoids redownloading when it appears complete.

## Large venue downloads

This repository exists specifically to avoid downloading the model and large containers on-site. Prepare and verify the drive before arriving.
