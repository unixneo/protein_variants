require "rails_helper"
require "json"

RSpec.describe Tp53FixtureImporter do
  let(:fixture_path) { Rails.root.join("db/fixtures/tp53.json") }
  let(:fixture_data) { JSON.parse(File.read(fixture_path)) }

  describe ".call" do
    it "loads fixture data and returns counts" do
      summary = described_class.call

      expect(summary).to eq(
        protein_created_or_updated: 1,
        protein_features_loaded: fixture_data.fetch("protein_features").size,
        structure_entries_loaded: fixture_data.fetch("structure_entries").size,
        variants_loaded: fixture_data.fetch("variants").size
      )
    end

    it "is idempotent for protein and variants by key" do
      described_class.call

      protein = Protein.find_by!(uniprot_accession: fixture_data.dig("protein", "uniprot_accession"))
      variant_ids_by_hgvs = protein.variants.order(:hgvs_protein).pluck(:hgvs_protein, :id).to_h

      described_class.call

      protein_after = Protein.find_by!(uniprot_accession: fixture_data.dig("protein", "uniprot_accession"))
      variant_ids_after = protein_after.variants.order(:hgvs_protein).pluck(:hgvs_protein, :id).to_h

      expect(Protein.count).to eq(1)
      expect(Variant.count).to eq(fixture_data.fetch("variants").size)
      expect(protein_after.id).to eq(protein.id)
      expect(variant_ids_after).to eq(variant_ids_by_hgvs)
    end

    it "replaces associated protein_features and structure_entries from fixture data" do
      protein = Protein.create!(uniprot_accession: fixture_data.dig("protein", "uniprot_accession"))
      protein.protein_features.create!(
        feature_type: "legacy",
        start_pos: 1,
        end_pos: 2,
        description: "Old feature",
        source_db: "Legacy"
      )
      protein.structure_entries.create!(
        pdb_id: "9OLD",
        method: "NMR",
        resolution: 9.9,
        chain_id: "Z",
        start_pos: 1,
        end_pos: 2
      )

      described_class.call
      protein.reload

      expect(protein.protein_features.count).to eq(fixture_data.fetch("protein_features").size)
      expect(protein.structure_entries.count).to eq(fixture_data.fetch("structure_entries").size)
      expect(protein.protein_features.where(feature_type: "legacy")).to be_empty
      expect(protein.structure_entries.where(pdb_id: "9OLD")).to be_empty
    end
  end
end
