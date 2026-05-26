require "yaml"
require "./fetcher/api_fetcher"
require "./registry/api_registry"

def update_software(name : String, fetcher : ApiFetcher) : Nil
  config_path = "versions/#{name}.yaml"
  raw = File.read(config_path).lstrip('\u{FEFF}')
  data = YAML.parse(raw)

  config = REGISTRY[name]?
  unless config
    puts "  skipping #{name}: no registry entry"
    return
  end

  root_h = data.as_h
  versions_h = root_h[YAML::Any.new("versions")].as_h
  tracked = versions_h.keys.map(&.as_s)

  infos = case config.api_type
  in ApiType::PaperMc    then fetcher.fetch_papermc(config.project, tracked)
  in ApiType::Purpur     then fetcher.fetch_purpur(tracked)
  in ApiType::McJars     then fetcher.fetch_mcjars(config.project, tracked)
  in ApiType::LeafMc     then fetcher.fetch_leaf(tracked)
  in ApiType::BungeeCord then fetcher.fetch_bungeecord
  end

  infos.each do |info|
    key = YAML::Any.new(info.mc_version)
    next unless versions_h.has_key?(key)
    versions_h[key].as_h[YAML::Any.new("link")] = YAML::Any.new(info.link)
  end

  yaml_out = data.to_yaml.sub(/\A---\n/, "")
  File.write(config_path, yaml_out)
  puts "  ✓ #{name} (#{infos.size}/#{tracked.size} updated)"
rescue ex
  puts "  ✗ #{name}: #{ex.message}"
end

fetcher = ApiFetcher.new
available = YAML.parse(File.read("versions.yaml").lstrip('\u{FEFF}'))["available"].as_a.map(&.as_s)

puts "Updating #{available.size} entries..."
available.each { |name| update_software(name, fetcher) }
puts "Done."
