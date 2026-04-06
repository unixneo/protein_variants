require "json"
require "net/http"
require "uri"

TAU_ACCESSION = "P10636"
APP_ACCESSION = "P05067"

TAU_PDB_IDS = %w[6CVJ 6CVN 7PQC].freeze
APP_PDB_IDS = %w[1IYT 2LMN].freeze

TAU_OUTPUT_PATH = "tmp/phase4_pdb_tau.txt"
APP_OUTPUT_PATH = "tmp/phase4_pdb_app.txt"

def fetch_json(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
    http.request(Net::HTTP::Get.new(uri))
  end
  raise "HTTP #{response.code} #{response.message} for #{url}" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

def post_json(url, payload)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(payload)
    http.request(req)
  end
  raise "HTTP #{response.code} #{response.message} for #{url}" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

def fetch_coverage(accession)
  payload = {
    query: "{ alignments(from: UNIPROT, to: PDB_ENTITY, queryId: \"#{accession}\") { target_alignments { target_id aligned_regions { query_begin query_end } } } }"
  }
  response = post_json("https://sequence-coordinates.rcsb.org/graphql", payload)
  response.dig("data", "alignments", "target_alignments") || []
end

def coverage_for_pdb(target_alignments, pdb_id)
  match = target_alignments.find do |alignment|
    alignment["target_id"].to_s.upcase.start_with?("#{pdb_id.upcase}_")
  end

  region = match&.dig("aligned_regions", 0)
  [region&.dig("query_begin"), region&.dig("query_end")]
end

def fetch_structure_line(pdb_id, target_alignments)
  entry_json = fetch_json("https://data.rcsb.org/rest/v1/core/entry/#{pdb_id}")
  polymer_json = fetch_json("https://data.rcsb.org/rest/v1/core/polymer_entity/#{pdb_id}/1")

  method = entry_json.dig("exptl", 0, "method")
  resolution = entry_json.dig("rcsb_entry_info", "resolution_combined", 0)
  chain = polymer_json.dig("rcsb_polymer_entity_container_identifiers", "auth_asym_ids", 0)

  start_pos, end_pos = coverage_for_pdb(target_alignments, pdb_id)
  coverage_text = if start_pos && end_pos
    "#{start_pos}..#{end_pos}"
  else
    "nil..nil"
  end
  note = start_pos && end_pos ? "" : " [no alignment]"

  resolution_text = resolution.nil? ? "NMR" : format("%.2f", resolution.to_f)

  "#{(entry_json["rcsb_id"] || pdb_id).upcase} | #{method} | #{resolution_text} | chain=#{chain} | #{coverage_text}#{note}"
end

def build_lines(pdb_ids, accession)
  alignments = fetch_coverage(accession)
  pdb_ids.map { |pdb_id| fetch_structure_line(pdb_id, alignments) }
end

def write_lines(path, lines)
  File.write(path, lines.join("\n") + "\n")
end

Dir.mkdir("tmp") unless Dir.exist?("tmp")

tau_lines = build_lines(TAU_PDB_IDS, TAU_ACCESSION)
app_lines = build_lines(APP_PDB_IDS, APP_ACCESSION)

write_lines(TAU_OUTPUT_PATH, tau_lines)
write_lines(APP_OUTPUT_PATH, app_lines)

tau_lines.each { |line| puts line }
app_lines.each { |line| puts line }

puts "#{TAU_OUTPUT_PATH}: #{tau_lines.length} lines"
puts "#{APP_OUTPUT_PATH}: #{app_lines.length} lines"
