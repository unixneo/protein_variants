require "net/http"
require "uri"
require "csv"
require "sqlite3"

SCORE_SETS = [
  { urn: "urn:mavedb:00000068-0-1", source: "Giacomelli2018" },
  { urn: "urn:mavedb:00000068-a-1", source: "Kotler2018" }
].freeze
DB_PATH = "db/mavedb.sqlite3"
TARGET_HGVS = [
  "p.Arg175His",
  "p.Gly245Ser",
  "p.Arg248Gln",
  "p.Arg273His",
  "p.Tyr220Cys"
].freeze

db = SQLite3::Database.new(DB_PATH)
db.execute("DELETE FROM scores")

inserted = 0

SCORE_SETS.each do |score_set|
  encoded_urn = score_set[:urn].gsub(":", "%3A")
  url = "https://api.mavedb.org/api/v1/score-sets/#{encoded_urn}/scores"

  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    raise "HTTP #{response.code} #{response.message}"
  end

  rows = CSV.parse(response.body, headers: true)
  matching_rows = rows.select { |row| TARGET_HGVS.include?(row["hgvs_pro"]) }

  matching_rows.each do |row|
    hgvs_pro = row["hgvs_pro"]
    score = Float(row["score"])

    db.execute(
      "INSERT INTO scores (hgvs_pro, score, score_set_urn, source) VALUES (?, ?, ?, ?)",
      [ hgvs_pro, score, score_set[:urn], score_set[:source] ]
    )

    puts "#{hgvs_pro} | #{score} | #{score_set[:source]}"
    inserted += 1
  end
end

puts "Done: #{inserted} scores inserted"
