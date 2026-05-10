{lib}: rec {
  modelsDir = "/var/lib/llama-models";
  hfHome = "${modelsDir}/.huggingface";

  modelFiles = {
    "qwen3-coder:30b-a3b" = {
      repo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
      file = "Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
      contextWindow = 131072;
      extraFlags = ["-ncmoe" "999" "-ctk" "q8_0" "-ctv" "q8_0"];
    };
    "deepseek-r1-qwen3:8b" = {
      repo = "unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF";
      file = "DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf";
    };
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
    "qwen3:8b" = {
      repo = "Qwen/Qwen3-8B-GGUF";
      file = "Qwen3-8B-Q4_K_M.gguf";
    };
    "granite4.1:8b" = {
      repo = "unsloth/granite-4.1-8b-GGUF";
      file = "granite-4.1-8b-Q4_K_M.gguf";
    };
  };

  sanitizeModelDirName = name: lib.replaceStrings ["/" ":" " "] ["--" "-" "-"] name;
  modelRevision = model: model.revision or "main";
  modelDir = model: "${modelsDir}/${sanitizeModelDirName model.repo}";
  modelPath = model: "${modelDir model}/${model.file}";
}
