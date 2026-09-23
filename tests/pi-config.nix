# Run from the repository root: nix eval --impure --json --file tests/pi-config.nix
let
  hm = (builtins.getFlake (toString ../.)).homeConfigurations."zshen@framework-16".config;
  models = (builtins.fromJSON hm.home.file.".pi/agent/models.json".text).providers.cliproxyapi;
  ids = [
    "gpt-5.5"
    "gpt-5.6-luna"
    "gpt-5.6-sol"
    "gpt-5.6-terra"
    "gpt-6-astra"
    "gpt-6-luna"
    "gpt-6-sol"
  ];
in {
  modelLimits =
    if
      builtins.map (model: model.id) models.models
      == ids
      && builtins.all (model: model.contextWindow == 272000 && model.maxTokens == 128000) models.models
      && models.api == "openai-responses"
      && models.baseUrl == "http://127.0.0.1:8317/v1"
    then true
    else throw "Pi CLIProxyAPI model catalog mismatch: ${builtins.toJSON (map (model: {inherit (model) id contextWindow maxTokens;}) models.models)}";
  projectTrust =
    if hm.programs.pi.settings.defaultProjectTrust == "ask"
    then true
    else throw "Pi project trust is ${hm.programs.pi.settings.defaultProjectTrust}, expected ask";
}
