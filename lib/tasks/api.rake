require "json"
require "net/http"

namespace :api do
  def api_fetch_json(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    return [ nil, "HTTP #{response.code} #{response.message}" ] unless response.is_a?(Net::HTTPSuccess)

    begin
      [ JSON.parse(response.body), nil ]
    rescue JSON::ParserError => e
      [ nil, "JSON parse error: #{e.message}" ]
    end
  rescue StandardError => e
    [ nil, e.message ]
  end

  def api_post_json(url, body)
    uri = URI(url)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
    return [ nil, "HTTP #{response.code} #{response.message}" ] unless response.is_a?(Net::HTTPSuccess)

    begin
      [ JSON.parse(response.body), nil ]
    rescue JSON::ParserError => e
      [ nil, "JSON parse error: #{e.message}" ]
    end
  rescue StandardError => e
    [ nil, e.message ]
  end

  desc "Verify external APIs and validate key fields"
  task verify: :environment do
    uniprot_json, uniprot_error = api_fetch_json("https://rest.uniprot.org/uniprotkb/P04637.json")
    if uniprot_error
      puts "UniProt: FAILED (#{uniprot_error})"
    else
      accession = uniprot_json["primaryAccession"]
      length = uniprot_json.dig("sequence", "length")
      if accession == "P04637" && length.present?
        puts "UniProt: OK (#{accession}, length=#{length})"
      else
        puts "UniProt: FAILED (unexpected accession or missing sequence length)"
      end
    end

    pdb_query = {
      query: {
        type: "terminal",
        service: "text",
        parameters: {
          attribute: "rcsb_polymer_entity_container_identifiers.reference_sequence_identifiers.database_accession",
          operator: "exact_match",
          value: "P04637"
        }
      },
      return_type: "entry"
    }
    pdb_json, pdb_error = api_post_json("https://search.rcsb.org/rcsbsearch/v2/query", pdb_query)
    if pdb_error
      puts "PDB: FAILED (#{pdb_error})"
    else
      result_set = pdb_json["result_set"]
      if result_set.is_a?(Array) && result_set.size.positive?
        puts "PDB: OK (results=#{result_set.size})"
      else
        puts "PDB: FAILED (missing or empty result_set)"
      end
    end

    mavedb_json, mavedb_error = api_fetch_json("https://api.mavedb.org/api/v1/score-sets/?urns=urn:mavedb:00000001-a-1")
    if mavedb_error
      puts "MaveDB: FAILED (#{mavedb_error})"
    else
      results = if mavedb_json.is_a?(Hash)
        mavedb_json["results"]
      elsif mavedb_json.is_a?(Array)
        mavedb_json
      end
      if results.is_a?(Array) && results.size.positive?
        first_urn = results.first&.dig("urn")
        puts "MaveDB: OK (first_urn=#{first_urn || 'n/a'})"
      else
        puts "MaveDB: FAILED (missing or empty results)"
      end
    end

    clinvar_json, clinvar_error = api_fetch_json("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=clinvar&term=TP53[gene]&retmode=json")
    if clinvar_error
      puts "ClinVar: FAILED (#{clinvar_error})"
    else
      count_raw = clinvar_json.dig("esearchresult", "count")
      count = Integer(count_raw, exception: false)
      if count && count > 0
        puts "ClinVar: OK (count=#{count})"
      else
        puts "ClinVar: FAILED (missing or non-positive count)"
      end
    end
  end
end
