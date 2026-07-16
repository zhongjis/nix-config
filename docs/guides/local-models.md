# Local models

`modules/nixos/features/llamacpp.nix` runs local GGUF models with three pieces:

- `hf` downloads model files from Hugging Face.
- `llama-server` runs one GGUF model.
- `llama-swap` routes OpenAI-compatible requests to the right `llama-server`.

The model catalog lives in `lib/llamacpp-models.nix`. Model files live under `/var/lib/llama-models`. The Hugging Face cache for this setup lives under `/var/lib/llama-models/.huggingface`.

## Install models

Apply the NixOS feature first:

```bash
nh os switch .
```

Download every configured model:

```bash
sudo nix run .#download-llamacpp-models
```

The command runs `hf download` for each model in `lib/llamacpp-models.nix`:

```bash
hf download <repo> <file> --revision <revision> --local-dir <model-dir> --quiet
```

Check files:

```bash
sudo ls -lah /var/lib/llama-models
```

For gated Hugging Face repos, pass a token in the environment when running the download command.

## Manage models

Add, remove, or change models in `lib/llamacpp-models.nix`:

```nix
"new-model:id" = {
  repo = "org/model-GGUF";
  file = "model-q4_k_m.gguf";
  revision = "main";
  extraFlags = ["-c" "65536"];
};
```

Use `hf` before adding a model:

```bash
hf models list --search 'model name' --limit 5
hf download org/model-GGUF model-q4_k_m.gguf --dry-run --quiet
```

After editing the catalog:

```bash
nh os switch .
sudo nix run .#download-llamacpp-models
```

If Pi should use the model, add the same ID to `localLlamaModels` in `modules/home-manager/features/ai-tools/pi/default.nix`.

Current model IDs:

```text
qwen2.5-coder:7b
qwen2.5-coder:14b
gemma4:e4b
gemma4:26b
qwen3:8b
granite4.1:8b
qwen3.6:27b
gemma4:31b
```

## Run and test

`llama-swap` listens at:

```text
http://127.0.0.1:9292/v1
```

Check the router:

```bash
systemctl status llama-swap.service
```

List models:

```bash
curl http://127.0.0.1:9292/v1/models
```

Send a request:

```bash
curl http://127.0.0.1:9292/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder:14b",
    "messages": [{"role": "user", "content": "hi"}],
    "max_tokens": 64
  }'
```

Unload running models:

```bash
curl -X POST http://127.0.0.1:9292/api/models/unload
```
