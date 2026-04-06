# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

TARGETS = [
  { accession: "P10636", output_path: "tmp/uniprot_p10636_features.txt" },
  { accession: "P05067", output_path: "tmp/uniprot_p05067_features.txt" }
].freeze

FEATURE_TYPES = %w[domain region repeat chain].freeze


def get_json(url)
  uri = URI.parse(url)

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP #{response.code} for #{url}"
    end

    JSON.parse(response.body)
  end
end

def extract_required_fields(data)
  accession = data["primaryAccession"]
  gene_symbol = data.dig("genes", 0, "geneName", "value")
  recommended_name = data.dig("proteinDescription", "recommendedName", "fullName", "value")
  sequence_length = data.dig("sequence", "length")
  sequence = data.dig("sequence", "value")

  {
    accession: accession,
    gene_symbol: gene_symbol,
    recommended_name: recommended_name,
    sequence_length: sequence_length,
    sequence_first_100: sequence ? sequence[0, 100] : nil
  }
end

def extract_features(data)
  raw_features = data["features"] || []

  raw_features.filter_map do |feature|
    feature_type = (feature["featureType"] || feature["type"]).to_s.downcase
    next unless FEATURE_TYPES.include?(feature_type)
    raw_description = feature["description"]
    description = raw_description.is_a?(Hash) ? raw_description["value"] : raw_description

    {
      type: feature["featureType"] || feature["type"],
      start_pos: feature.dig("location", "start", "value"),
      end_pos: feature.dig("location", "end", "value"),
      description: description
    }
  end
end

def print_top_level_keys_if_missing(data, fields, accession)
  missing = []
  missing << "primaryAccession" if fields[:accession].nil?
  missing << "genes[0].geneName.value" if fields[:gene_symbol].nil?
  missing << "proteinDescription.recommendedName.fullName.value" if fields[:recommended_name].nil?
  missing << "sequence.length" if fields[:sequence_length].nil?
  missing << "sequence.value" if fields[:sequence_first_100].nil?

  return if missing.empty?

  puts "[#{accession}] Missing fields: #{missing.join(", ")}"
  puts "[#{accession}] Top-level JSON keys: #{data.keys.sort.join(", ")}"
end

def write_output_file(path, fields, features)
  lines = []
  lines << "uniprot_accession: #{fields[:accession]}"
  lines << "gene_symbol: #{fields[:gene_symbol]}"
  lines << "recommended_name: #{fields[:recommended_name]}"
  lines << "sequence_length: #{fields[:sequence_length]}"
  lines << "sequence_first_100: #{fields[:sequence_first_100]}"
  lines << ""
  lines << "features:"

  if features.empty?
    lines << "  (none found for domain/region/repeat/chain)"
  else
    features.each do |feature|
      lines << "  - type: #{feature[:type]} | start: #{feature[:start_pos]} | end: #{feature[:end_pos]} | description: #{feature[:description]}"
    end
  end

  File.write(path, lines.join("\n") + "\n")
end

Dir.mkdir("tmp") unless Dir.exist?("tmp")

TARGETS.each do |target|
  accession = target[:accession]
  output_path = target[:output_path]
  url = "https://rest.uniprot.org/uniprotkb/#{accession}.json"

  data = get_json(url)
  fields = extract_required_fields(data)
  features = extract_features(data)

  print_top_level_keys_if_missing(data, fields, accession)
  write_output_file(output_path, fields, features)

  puts "#{output_path}"
  puts "#{accession}: #{features.length} features found"
end
