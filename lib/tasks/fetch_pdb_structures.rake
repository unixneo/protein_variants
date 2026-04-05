require Rails.root.join("lib/tasks/fetch_pdb_structures")

namespace :protein_variants do
  desc "Fetch and store PDB structures for P04637 from RCSB API"
  task fetch_pdb_structures: :environment do
    begin
      ProteinVariants::FetchPdbStructures.run
    rescue StandardError => e
      puts "FAILED: #{e.message}"
      raise
    end
  end
end
