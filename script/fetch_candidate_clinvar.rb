require "net/http"
require "uri"
require "json"

VARIANTS = %w[
  p.Val143Leu
  p.Arg181Asn
  p.Arg290Pro
  p.Leu299Ser
  p.Met1Asn
].freeze

ESEARCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
ESUMMARY_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"


def fetch_json(base_url, params)
  uri = URI(base_url)
  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
    http.request(Net::HTTP::Get.new(uri.request_uri))
  end

  raise "HTTP #{response.code} #{response.message} for #{uri}" unless response.is_a?(Net::HTTPSuccess)

  parsed = JSON.parse(response.body)
  sleep 0.4
  parsed
end

def first_clinvar_id_for(hgvs_pro)
  term = "TP53[gene] AND #{hgvs_pro}[variant name]"
  data = fetch_json(ESEARCH_URL, { db: "clinvar", term: term, retmode: "json" })
  data.dig("esearchresult", "idlist", 0)
end

def summary_for(clinvar_id)
  fetch_json(ESUMMARY_URL, { db: "clinvar", id: clinvar_id, retmode: "json" })
end

def extract_classification_and_review(summary, clinvar_id)
  record = summary.dig("result", clinvar_id.to_s) || {}

  germline = record["germline_classification"]
  if germline.is_a?(Hash)
    classification = germline["description"]
    review_status = germline["review_status"]
  else
    clinical = record["clinical_significance"]
    classification = clinical.is_a?(Hash) ? clinical["description"] : clinical
    review_status = record["review_status"]
  end

  [classification || "-", review_status || "-"]
end

VARIANTS.each do |hgvs_pro|
  clinvar_id = first_clinvar_id_for(hgvs_pro)

  if clinvar_id.nil? || clinvar_id.empty?
    puts "#{hgvs_pro} | NOT_FOUND | - | -"
    next
  end

  summary = summary_for(clinvar_id)
  classification, review_status = extract_classification_and_review(summary, clinvar_id)

  puts "#{hgvs_pro} | #{clinvar_id} | #{classification} | #{review_status}"
end
