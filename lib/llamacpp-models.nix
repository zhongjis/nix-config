{lib}: rec {
  modelsDir = "/var/lib/llama-models";
  hfHome = "${modelsDir}/.huggingface";

  modelFiles = {
    "qwen2.5-coder:7b" = {
      repo = "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF";
      file = "qwen2.5-coder-7b-instruct-q4_k_m.gguf";
    };
    "qwen2.5-coder:14b" = {
      repo = "Qwen/Qwen2.5-Coder-14B-Instruct-GGUF";
      file = "qwen2.5-coder-14b-instruct-q4_k_m.gguf";
    };
    "gemma4:e4b" = {
      repo = "unsloth/gemma-3n-E4B-it-GGUF";
      file = "gemma-3n-E4B-it-Q4_K_M.gguf";
    };
    "gemma4:26b" = {
      repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      file = "gemma-4-26B-A4B-it-UD-Q4_K_M.gguf";
    };
    "qwen3:8b" = {
      repo = "Qwen/Qwen3-8B-GGUF";
      file = "Qwen3-8B-Q4_K_M.gguf";
    };
    "granite4.1:8b" = {
      repo = "unsloth/granite-4.1-8b-GGUF";
      file = "granite-4.1-8b-Q4_K_M.gguf";
    };
    "qwen3.6:27b" = {
      repo = "unsloth/Qwen3.6-27B-GGUF";
      file = "Qwen3.6-27B-Q4_K_M.gguf";
    };
    "gemma4:31b" = {
      repo = "unsloth/gemma-4-31B-it-GGUF";
      file = "gemma-4-31B-it-Q4_K_M.gguf";
    };
  };

  sanitizeModelDirName = name: lib.replaceStrings ["/" ":" " "] ["--" "-" "-"] name;
  modelRevision = model: model.revision or "main";
  modelDir = model: "${modelsDir}/${sanitizeModelDirName model.repo}";
  modelPath = model: "${modelDir model}/${model.file}";
}
