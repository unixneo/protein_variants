require "net/http"
require "uri"
require "csv"

SCORE_SETS = [
  { urn: "urn:mavedb:00000068-0-1", label: "Giacomelli2018" },
  { urn: "urn:mavedb:00000068-a-1", label: "Kotler2018" }
].freeze

MIN_SCORE = 0.2
MAX_SCORE = 0.6

def fetch_csv(url)
  uri = URI.parse(url)

  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    raise "HTTP #{response.code} #{response.message} for #{url}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end
end

def encoded_urn(urn)
  urn.gsub(":", "%3A")
end

def parse_intermediate_rows(csv_text)
  rows = CSV.parse(csv_text, headers: true)
  total_rows = rows.size

  intermediate = rows.filter_map do |row|
    hgvs_pro = row["hgvs_pro"]
    next unless hgvs_pro&.start_with?("p.")

    begin
      score = Float(row["score"])
    rescue StandardError
      next
    end

    next unless score >= MIN_SCORE && score <= MAX_SCORE

    { hgvs_pro: hgvs_pro, score: score }
  end

  [total_rows, intermediate.sort_by { |r| r[:score] }]
end

SCORE_SETS.each do |score_set|
  urn = score_set[:urn]
  label = score_set[:label]
  url = "https://api.mavedb.org/api/v1/score-sets/#{encoded_urn(urn)}/scores"

  csv_text = fetch_csv(url)
  total_rows, intermediate = parse_intermediate_rows(csv_text)

  puts "\n=== #{label} (#{urn}) ==="
  puts "total_rows=#{total_rows}"
  puts "intermediate_rows=#{intermediate.size}"
  puts "hgvs_pro | score"
  intermediate.each do |row|
    puts "#{row[:hgvs_pro]} | #{format('%.6f', row[:score])}"
  end
end
