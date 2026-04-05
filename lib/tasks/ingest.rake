require "json"
require "net/http"

namespace :ingest do
  desc "Fetch TP53 (P04637) from UniProt and store in uniprot.sqlite3"
  task uniprot_tp53: :environment do
    url = URI("https://rest.uniprot.org/uniprotkb/P04637.json")

    begin
      response = Net::HTTP.get_response(url)
    rescue StandardError => e
      puts "HTTP request failed: #{e.message}"
      next
    end

    unless response.is_a?(Net::HTTPSuccess)
      puts "HTTP request failed: #{response.code} #{response.message}"
      next
    end

    begin
      payload = JSON.parse(response.body)
    rescue JSON::ParserError => e
      puts "JSON parse failed: #{e.message}"
      next
    end

    accession = payload["primaryAccession"]
    gene_symbol = payload.dig("genes", 0, "geneName", "value")
    sequence = payload.dig("sequence", "value")
    sequence_length = payload.dig("sequence", "length")
    name =
      payload.dig("proteinDescription", "recommendedName", "fullName", "value") ||
      payload.dig("proteinDescription", "submissionNames", 0, "fullName", "value") ||
      gene_symbol ||
      accession

    if accession.blank?
      puts "UniProt payload missing primaryAccession"
      next
    end

    entry = Uniprot::Entry.find_or_initialize_by(accession: accession)
    entry.name = name
    entry.save!

    connection = Uniprot::Entry.connection
    unless connection.table_exists?(:features)
      connection.create_table :features do |t|
        t.string :feature_type
        t.integer :start_pos
        t.integer :end_pos
        t.text :description
        t.string :accession
      end
    end

    connection.execute("DELETE FROM features WHERE accession = #{connection.quote(accession)}")

    inserted = 0
    Array(payload["features"]).each do |feature|
      start_value = feature.dig("location", "start", "value")
      end_value = feature.dig("location", "end", "value")
      start_pos = Integer(start_value, exception: false)
      end_pos = Integer(end_value, exception: false)

      connection.execute(
        "INSERT INTO features (feature_type, start_pos, end_pos, description, accession) VALUES " \
          "(#{connection.quote(feature['type'])}, #{connection.quote(start_pos)}, #{connection.quote(end_pos)}, " \
          "#{connection.quote(feature['description'])}, #{connection.quote(accession)})"
      )
      inserted += 1
    end

    puts "accession: #{accession}"
    puts "gene_symbol: #{gene_symbol}"
    puts "sequence_length: #{sequence_length}"
    puts "features_stored: #{inserted}"
    puts "sequence_loaded: #{sequence.present?}"
  end
end
