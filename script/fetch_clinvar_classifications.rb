require "net/http"
require "uri"
require "json"
require "sqlite3"

VARIANTS = {
  "p.Arg175His" => "12374",
  "p.Gly245Ser" => "12385",
  "p.Arg248Gln" => "12386",
  "p.Arg273His" => "12392",
  "p.Tyr220Cys" => "12375",
  "p.Val143Leu" => "2687704",
  "p.Arg290Pro" => "458572"
}.freeze

DB_PATH = "db/clinvar.sqlite3"

def fetch_summary(variation_id)
  url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=clinvar&id=#{variation_id}&retmode=json"
  uri = URI(url)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "HTTP #{response.code} #{response.message} for variation_id=#{variation_id}"
  end

  JSON.parse(response.body)
end

db = SQLite3::Database.new(DB_PATH)
db.execute("DELETE FROM classifications")

inserted = 0

VARIANTS.each do |hgvs_pro, variation_id|
  summary = fetch_summary(variation_id)
  record = summary.dig("result", variation_id) || {}
  germline = record["germline_classification"] || {}

  clinical_significance = germline["description"]
  review_status = germline["review_status"]
  last_evaluated = germline["last_evaluated"]

  db.execute(
    "INSERT INTO classifications (hgvs_pro, variation_id, clinical_significance, review_status, last_evaluated) VALUES (?, ?, ?, ?, ?)",
    [ hgvs_pro, variation_id, clinical_significance, review_status, last_evaluated ]
  )

  inserted += 1
  puts "#{hgvs_pro} | #{clinical_significance} | #{review_status}"
end

puts "Done: #{inserted} classifications inserted"
