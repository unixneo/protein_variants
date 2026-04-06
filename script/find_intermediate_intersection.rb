require "net/http"
require "uri"
require "csv"

SCORE_SETS = {
  giacomelli: "urn:mavedb:00000068-0-1",
  kotler: "urn:mavedb:00000068-a-1"
}.freeze

MIN_SCORE = 0.2
MAX_SCORE = 0.6
DBD_START = 95
DBD_END = 289


def encoded_urn(urn)
  urn.gsub(":", "%3A")
end

def fetch_csv(urn)
  url = "https://api.mavedb.org/api/v1/score-sets/#{encoded_urn(urn)}/scores"
  uri = URI.parse(url)

  Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    raise "HTTP #{response.code} #{response.message} for #{url}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end
end

def parse_intermediate_scores(csv_text)
  rows = CSV.parse(csv_text, headers: true)

  rows.each_with_object({}) do |row, acc|
    hgvs = row["hgvs_pro"]
    next unless hgvs&.start_with?("p.")

    begin
      score = Float(row["score"])
    rescue StandardError
      next
    end

    next unless score >= MIN_SCORE && score <= MAX_SCORE

    acc[hgvs] = score
  end
end

def extract_position(hgvs)
  match = /p\.[A-Za-z]+(\d+)/.match(hgvs)
  return nil unless match

  match[1].to_i
end

def classify_position(position)
  return "outside_dbd" if position < DBD_START || position > DBD_END

  "inside_dbd"
end

def print_table(title, rows)
  puts "\n=== #{title} ==="
  puts "hgvs_pro | position | giacomelli | kotler | avg"
  rows.each do |r|
    puts [
      r[:hgvs_pro],
      r[:position],
      format("%.6f", r[:giacomelli]),
      format("%.6f", r[:kotler]),
      format("%.6f", r[:avg])
    ].join(" | ")
  end
  puts "count=#{rows.length}"
end

giacomelli_scores = parse_intermediate_scores(fetch_csv(SCORE_SETS[:giacomelli]))
kotler_scores = parse_intermediate_scores(fetch_csv(SCORE_SETS[:kotler]))

intersection = giacomelli_scores.keys & kotler_scores.keys

rows = intersection.filter_map do |hgvs|
  position = extract_position(hgvs)
  next if position.nil?

  g = giacomelli_scores[hgvs]
  k = kotler_scores[hgvs]

  {
    hgvs_pro: hgvs,
    position: position,
    giacomelli: g,
    kotler: k,
    avg: (g + k) / 2.0,
    location: classify_position(position)
  }
end

sorted = rows.sort_by { |r| [r[:position], r[:hgvs_pro]] }
outside = sorted.select { |r| r[:location] == "outside_dbd" }
inside = sorted.select { |r| r[:location] == "inside_dbd" }

print_table("OUTSIDE DNA-BINDING DOMAIN (position < 95 or > 289)", outside)
print_table("INSIDE DNA-BINDING DOMAIN (position 95-289)", inside)
