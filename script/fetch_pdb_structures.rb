require "json"
require "net/http"
require "uri"
require "sqlite3"

PDBIDS = %w[1TUP 2OCJ 3KZ8 2AC0 1AIE].freeze
UNIPROT_ACCESSION = "P04637"
DB_PATH = "db/pdb.sqlite3"

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

def fetch_coverage
  payload = {
    query: "{ alignments(from: UNIPROT, to: PDB_ENTITY, queryId: \"P04637\") { target_alignments { target_id aligned_regions { query_begin query_end } } } }"
  }
  response = post_json("https://sequence-coordinates.rcsb.org/graphql", payload)
  target_alignments = response.dig("data", "alignments", "target_alignments") || []

  coverage = {}
  target_alignments.each do |ta|
    pdb = ta["target_id"].to_s.split("_").first.upcase
    region = ta.dig("aligned_regions", 0)
    next unless region
    coverage[pdb] ||= { start_pos: region["query_begin"], end_pos: region["query_end"] }
  end
  coverage
end

def fetch_structure_payload(pdb_id, coverage)
  entry_json = fetch_json("https://data.rcsb.org/rest/v1/core/entry/#{pdb_id}")
  polymer_json = fetch_json("https://data.rcsb.org/rest/v1/core/polymer_entity/#{pdb_id}/1")

  resolution = (
    entry_json.dig("rcsb_entry_info", "resolution_combined", 0) ||
    entry_json.dig("refine", 0, "ls_d_res_high")
  )&.to_f

  {
    pdb_id: entry_json["rcsb_id"] || pdb_id,
    title: entry_json.dig("struct", "title"),
    method: entry_json.dig("exptl", 0, "method"),
    resolution: resolution,
    chain_id: polymer_json.dig("rcsb_polymer_entity_container_identifiers", "auth_asym_ids", 0),
    start_pos: coverage.dig(pdb_id.upcase, :start_pos),
    end_pos: coverage.dig(pdb_id.upcase, :end_pos)
  }
end

db = SQLite3::Database.new(DB_PATH)
insert_sql = <<~SQL
  INSERT OR REPLACE INTO structures
  (pdb_id, title, chain_id, start_pos, end_pos, resolution, method, uniprot_accession)
  VALUES (?, ?, ?, ?, ?, ?, ?, 'P04637')
SQL

coverage = fetch_coverage
db.execute("DELETE FROM structures")

inserted = 0
PDBIDS.each do |pdb_id|
  s = fetch_structure_payload(pdb_id, coverage)
  db.execute(insert_sql, [s[:pdb_id], s[:title], s[:chain_id], s[:start_pos], s[:end_pos], s[:resolution], s[:method]])
  inserted += 1
  puts "#{s[:pdb_id]} | #{s[:method]} | #{s[:resolution]} | #{s[:chain_id]} | #{s[:start_pos]}..#{s[:end_pos]}"
end

puts "Done: #{inserted} structures inserted"
