require "json"
require "net/http"
require "uri"
require "sqlite3"

PDB_IDS = %w[1TUP 2OCJ 3KZ8 2LZH 1AIE].freeze
UNIPROT_ACCESSION = "P04637"
DB_PATH = "db/pdb.sqlite3"

def fetch_json(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "HTTP #{response.code} #{response.message} for #{url}"
  end

  JSON.parse(response.body)
end

db = SQLite3::Database.new(DB_PATH)
insert_sql = <<~SQL
  INSERT OR REPLACE INTO structures
  (pdb_id, title, chain_id, start_pos, end_pos, resolution, method, uniprot_accession)
  VALUES (?, ?, ?, ?, ?, ?, ?, 'P04637')
SQL

inserted = 0

PDB_IDS.each do |pdb_id|
  entry = fetch_json("https://data.rcsb.org/rest/v1/core/entry/#{pdb_id}")
  polymer = fetch_json("https://data.rcsb.org/rest/v1/core/polymer_entity/#{pdb_id}/1")

  resolved_pdb_id = entry["rcsb_id"] || pdb_id
  title = entry.dig("struct", "title")
  method = entry.dig("exptl", 0, "method")
  resolution = entry.dig("refine", 0, "ls_d_res_high")
  chain_id = polymer.dig("rcsb_polymer_entity_container_identifiers", "auth_asym_ids", 0)
  start_pos = nil
  end_pos = nil

  db.execute(insert_sql, [ resolved_pdb_id, title, chain_id, start_pos, end_pos, resolution, method ])
  inserted += 1

  puts "#{resolved_pdb_id} | #{method} | #{resolution} | #{chain_id}"
end

puts "Done: #{inserted} structures inserted"
