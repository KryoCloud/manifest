enum ApiType
  PaperMc
  Purpur
  McJars
  LeafMc
  BungeeCord
end

record ApiConfig, api_type : ApiType, project : String

REGISTRY = {
  "paper"      => ApiConfig.new(ApiType::PaperMc, "paper"),
  "folia"      => ApiConfig.new(ApiType::PaperMc, "folia"),
  "velocity"   => ApiConfig.new(ApiType::PaperMc, "velocity"),
  "purpur"     => ApiConfig.new(ApiType::Purpur, "purpur"),
  "spigot"     => ApiConfig.new(ApiType::McJars, "SPIGOT"),
  "leaf"       => ApiConfig.new(ApiType::LeafMc, "leaf"),
  "bungeecord" => ApiConfig.new(ApiType::BungeeCord, "BungeeCord"),
}
