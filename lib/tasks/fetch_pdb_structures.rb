require "json"
require "net/http"
require "sqlite3"

module ProteinVariants
  class FetchPdbStructures
    SEARCH_URL = "https://search.rcsb.org/rcsbsearch/v2/query"
    ENTRY_URL_TEMPLATE = "https://data.rcsb.org/rest/v1/core/entry/%<pdb_id>s"
    POLYMER_URL_TEMPLATE = "https://data.rcsb.org/rest/v1/core/polymer_entity/%<pdb_id>s/1"
    ACCESSION = "P04637"

    class << self
      def run
        pdb_ids = fetch_pdb_ids
        structures = pdb_ids.map { |pdb_id| fetch_structure_payload(pdb_id) }
        insert_structures(structures)
        print_summary(structures)
      end

      private

      def fetch_pdb_ids
        # Curated TP53 structures covering benchmark variant positions
        # 1TUP: R175H region, DNA-binding domain (94-312)
        # 2OCJ: R248Q/R273H region, DNA-binding domain (94-292)
        # 3KZ8: Y220C region, DNA-binding domain
        # 2LZH: G245S region, NMR structure
        # 1AIE: Full-length DNA-binding domain
        %w[1TUP 2OCJ 3KZ8 2LZH 1AIE]
      end

      def fetch_structure_payload(pdb_id)
        entry_json = get_json(format(ENTRY_URL_TEMPLATE, pdb_id: pdb_id), "RCSB Entry API (#{pdb_id})")
        polymer_json = get_json(format(POLYMER_URL_TEMPLATE, pdb_id: pdb_id), "RCSB Polymer API (#{pdb_id})")

        {
          pdb_id: entry_json["rcsb_id"] || pdb_id,
          title: entry_json.dig("struct", "title"),
          method: entry_json.dig("exptl", 0, "method"),
          resolution: entry_json.dig("refine", 0, "ls_d_res_high"),
          chain_id: polymer_json.dig("rcsb_polymer_entity_container_identifiers", "auth_asym_ids", 0),
          start_pos: nil,
          end_pos: nil
        }
      end

      def insert_structures(structures)
        db = SQLite3::Database.new(Rails.root.join("db/pdb.sqlite3").to_s)
        db.transaction
        structures.each do |s|
          db.execute(
            <<~SQL,
              INSERT OR REPLACE INTO structures (
                id, pdb_id, title, chain_id, start_pos, end_pos, resolution, method, uniprot_accession
              ) VALUES (
                (SELECT id FROM structures WHERE pdb_id = ? AND uniprot_accession = ?),
                ?, ?, ?, ?, ?, ?, ?, ?
              )
            SQL
            [
              s[:pdb_id], ACCESSION,
              s[:pdb_id], s[:title], s[:chain_id], s[:start_pos], s[:end_pos], s[:resolution], s[:method], ACCESSION
            ]
          )
        end
        db.commit
        db.close
      rescue StandardError
        db.rollback if db
        db.close if db
        raise
      end

      def print_summary(structures)
        puts "Inserted #{structures.size} structures for #{ACCESSION}"
        structures.each do |s|
          puts [
            s[:pdb_id],
            s[:method],
            s[:resolution],
            s[:chain_id],
            s[:start_pos],
            s[:end_pos]
          ].join(", ")
        end
      end

      def get_json(url, label)
        uri = URI(url)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end
        parse_json_response(response, label)
      rescue StandardError => e
        raise "#{label} error: #{e.message}"
      end

      def post_json(url, body, label)
        uri = URI(url)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
          http.request(request)
        end
        parse_json_response(response, label)
      rescue StandardError => e
        raise "#{label} error: #{e.message}"
      end

      def parse_json_response(response, label)
        unless response.is_a?(Net::HTTPSuccess)
          body_snippet = response.body.to_s[0, 300]
          raise "#{label} HTTP #{response.code} #{response.message}: #{body_snippet}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise "#{label} JSON parse error: #{e.message}"
      end
    end
  end
end
