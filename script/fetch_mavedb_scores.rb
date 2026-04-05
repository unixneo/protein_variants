require "net/http"
require "uri"
require "csv"
require "sqlite3"

URL = "https://api.mavedb.org/api/v1/score-sets/urn:mavedb:00000068-0-1/scores"
SCORE_SET_URN = "urn:mavedb:00000068-0-1"
SOURCE = "Giacomelli2018"
DB_PATH = "db/mavedb.sqlite3"
TARGET_HGVS = [
  "p.Arg175His",
  "p.Gly245Ser",
  "p.Arg248Gln",
  "p.Arg273His",
  "p.Tyr220Cys"
].freeze

uri = URI(URL)
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
  request = Net::HTTP::Get.new(uri)
  http.request(request)
end

unless response.is_a?(Net::HTTPSuccess)
  raise "HTTP #{response.code} #{response.message}"
end

rows = CSV.parse(response.body, headers: true)
matching_rows = rows.select { |row| TARGET_HGVS.include?(row["hgvs_pro"]) }

db = SQLite3::Database.new(DB_PATH)
db.execute("DELETE FROM scores")

matching_rows.each do |row|
  hgvs_pro = row["hgvs_pro"]
  score = Float(row["score"])

  db.execute(
    "INSERT INTO scores (hgvs_pro, score, score_set_urn, source) VALUES (?, ?, ?, ?)",
    [ hgvs_pro, score, SCORE_SET_URN, SOURCE ]
  )

  puts "#{hgvs_pro} | #{score} | #{SOURCE}"
end

puts "Done: #{matching_rows.size} scores inserted"
