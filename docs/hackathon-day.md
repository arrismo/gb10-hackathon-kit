# Hackathon Day

1. Connect the prepared external drive to the DGX Spark / GB10.
2. Confirm the target machine is healthy:

```bash
nvidia-smi
docker info
```

3. Load cached container images:

```bash
docker load -i <drive>/docker/nvidia-vllm-dgx-spark.tar
docker load -i <drive>/docker/nemoclaw-sandbox-base-arm64.tar
docker load -i <drive>/docker/node22-arm64-build-images.tar
```

4. Copy `<drive>/models/Qwen3.6-35B-A3B-NVFP4` to fast internal storage before inference.
5. Run `<drive>/installers/nemoclaw.sh` and choose the DGX Spark / local inference path where offered.
6. Use cached OpenShell assets if the official installer would otherwise perform a large download.

The cache is a fallback to reduce network dependence, not a replacement for upstream documentation.
