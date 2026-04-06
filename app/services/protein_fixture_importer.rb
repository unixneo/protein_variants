require "json"

class ProteinFixtureImporter
  def initialize(fixture_path)
    @fixture_path = fixture_path
  end

  def self.call(fixture_path)
    new(fixture_path).call
  end

  def call
    payload = JSON.parse(File.read(@fixture_path))

    ActiveRecord::Base.transaction do
      protein = upsert_protein(payload.fetch("protein"))
      protein_features_count = replace_protein_features(protein, payload.fetch("protein_features", []))
      structure_entries_count = replace_structure_entries(protein, payload.fetch("structure_entries", []))
      variants_count = upsert_variants(protein, payload.fetch("variants", []))

      {
        protein_created_or_updated: 1,
        protein_features_loaded: protein_features_count,
        structure_entries_loaded: structure_entries_count,
        variants_loaded: variants_count
      }
    end
  end

  private

  def upsert_protein(attributes)
    protein = Protein.find_or_initialize_by(uniprot_accession: attributes.fetch("uniprot_accession"))
    protein.assign_attributes(attributes.slice("gene_symbol", "recommended_name", "organism", "sequence", "sequence_length"))
    protein.save!
    protein
  end

  def replace_protein_features(protein, items)
    protein.protein_features.destroy_all
    items.each { |attrs| protein.protein_features.create!(attrs) }
    items.size
  end

  def replace_structure_entries(protein, items)
    protein.structure_entries.destroy_all
    items.each { |attrs| protein.structure_entries.create!(attrs) }
    items.size
  end

  def upsert_variants(protein, items)
    items.each do |attrs|
      variant = protein.variants.find_or_initialize_by(hgvs_protein: attrs.fetch("hgvs_protein"))
      variant.assign_attributes(attrs.slice("residue_position", "ref_aa", "alt_aa"))
      variant.save!
    end
    items.size
  end
end
