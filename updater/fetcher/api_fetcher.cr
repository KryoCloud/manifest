require "http/client"
require "json"

record VersionInfo, mc_version : String, link : String

class ApiFetcher
  def fetch_papermc(project : String, versions : Array(String)) : Array(VersionInfo)
    versions.compact_map do |version|
      begin
        data = JSON.parse(get("https://fill.papermc.io/v3/projects/#{project}/versions/#{version}/builds/latest"))
        link = data["downloads"]["server:default"]["url"].as_s
        VersionInfo.new(version, link)
      rescue ex
        STDERR.puts "  [#{project}] #{version} skipped: #{ex.message}"
        nil
      end
    end
  end

  def fetch_purpur(versions : Array(String)) : Array(VersionInfo)
    versions.compact_map do |version|
      begin
        data = JSON.parse(get("https://api.purpurmc.org/v2/purpur/#{version}"))
        build = data["builds"]["latest"].as_s
        link = "https://api.purpurmc.org/v2/purpur/#{version}/#{build}/download"
        VersionInfo.new(version, link)
      rescue ex
        STDERR.puts "  [purpur] #{version} skipped: #{ex.message}"
        nil
      end
    end
  end

  def fetch_mcjars(project : String, versions : Array(String)) : Array(VersionInfo)
    versions.compact_map do |version|
      begin
        data = JSON.parse(get("https://mcjars.app/api/v3/builds/types/#{project}/versions/#{version}/latest"))
        link = data["build"]["installation"][0][0]["url"].as_s
        VersionInfo.new(version, link)
      rescue ex
        STDERR.puts "  [mcjars/#{project}] #{version} skipped: #{ex.message}"
        nil
      end
    end
  end

  def fetch_leaf(versions : Array(String)) : Array(VersionInfo)
    versions.compact_map do |version|
      begin
        builds = JSON.parse(get("https://api.leafmc.one/v2/projects/leaf/versions/#{version}/builds"))["builds"].as_a
        next if builds.empty?

        latest = builds.max_by { |b| b["build"].as_i }
        build = latest["build"].as_i.to_s
        download = latest["downloads"].as_h.first_value
        filename = download["name"].as_s
        link = "https://api.leafmc.one/v2/projects/leaf/versions/#{version}/builds/#{build}/downloads/#{filename}"
        VersionInfo.new(version, link)
      rescue ex
        STDERR.puts "  [leaf] #{version} skipped: #{ex.message}"
        nil
      end
    end
  end

  def fetch_bungeecord : Array(VersionInfo)
    data = JSON.parse(get("https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/api/json"))
    build = data["number"].as_i.to_s
    link = "https://ci.md-5.net/job/BungeeCord/#{build}/artifact/bootstrap/target/BungeeCord.jar"
    [VersionInfo.new("latest", link)]
  end

  private def get(url : String, redirects = 5) : String
    response = HTTP::Client.get(url)

    if response.status_code.in?(301, 302, 303, 307, 308) && redirects > 0
      location = response.headers["Location"]
      return get(location, redirects - 1)
    end

    raise "HTTP #{response.status_code} fetching #{url}" unless response.success?
    response.body
  end
end
