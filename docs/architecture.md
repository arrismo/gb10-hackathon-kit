# Architecture

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

- **OpenClaw** is the agent layer.
- **NemoClaw** integrates and configures the stack for safer agent operation.
- **OpenShell** provides the sandbox/runtime/security boundary.
- **vLLM** serves the local model through an inference endpoint.
- **Qwen3.6-35B-A3B-NVFP4** is the local LLM cached by this kit.
- **NVIDIA GB10 / DGX Spark** provides the ARM64 NVIDIA compute target.

This repository only prepares portable assets for that stack; it does not create an agent or run inference.
