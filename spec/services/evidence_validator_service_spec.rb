require "rails_helper"

RSpec.describe EvidenceValidatorService do
  let(:protein) { Protein.create!(uniprot_accession: "P04637") }

  before do
    mavedb_connection = Mavedb::Score.connection
    unless mavedb_connection.table_exists?(:scores)
      mavedb_connection.create_table :scores do |t|
        t.string :hgvs_pro
        t.float :score
        t.string :score_set_urn
        t.string :source
      end
    end

    clinvar_connection = Clinvar::Classification.connection
    unless clinvar_connection.table_exists?(:classifications)
      clinvar_connection.create_table :classifications do |t|
        t.string :hgvs_pro
        t.string :variation_id
        t.string :clinical_significance
        t.string :review_status
        t.string :last_evaluated
      end
    end
  end

  describe ".call" do
    it "returns agree when system, mavedb, and clinvar are aligned" do
      Mavedb::Score.delete_all
      Clinvar::Classification.delete_all

      variant = Variant.create!(
        protein: protein,
        hgvs_protein: "p.Arg175His",
        residue_position: 175,
        ref_aa: "R",
        alt_aa: "H"
      )
      Mavedb::Score.create!(
        hgvs_pro: "p.Arg175His",
        score: 1.025,
        source: "Giacomelli2018",
        score_set_urn: "urn:mavedb:00000068-0-1"
      )
      Clinvar::Classification.create!(
        hgvs_pro: "p.Arg175His",
        clinical_significance: "Pathogenic",
        review_status: "reviewed by expert panel"
      )
      interpretation = {
        preliminary_mechanism: "structured functional region",
        confidence: "medium",
        domain_hit: true,
        structure_hit: true
      }

      result = described_class.call(variant, interpretation)

      expect(result.dig(:mavedb, :agreement)).to eq(:agree)
      expect(result.dig(:clinvar, :agreement)).to eq(:agree)
      expect(result[:overall_agreement]).to eq(:agree)
    end

    it "returns disagree when system is unflagged but mavedb and clinvar indicate impact" do
      Mavedb::Score.delete_all
      Clinvar::Classification.delete_all

      variant = Variant.create!(
        protein: protein,
        hgvs_protein: "p.Arg175His",
        residue_position: 175,
        ref_aa: "R",
        alt_aa: "H"
      )
      Mavedb::Score.create!(
        hgvs_pro: "p.Arg175His",
        score: 1.025,
        source: "Giacomelli2018",
        score_set_urn: "urn:mavedb:00000068-0-1"
      )
      Clinvar::Classification.create!(
        hgvs_pro: "p.Arg175His",
        clinical_significance: "Pathogenic",
        review_status: "reviewed by expert panel"
      )
      interpretation = {
        preliminary_mechanism: "unannotated region",
        confidence: "low",
        domain_hit: false,
        structure_hit: false
      }

      result = described_class.call(variant, interpretation)

      expect(result.dig(:mavedb, :agreement)).to eq(:disagree)
      expect(result.dig(:clinvar, :agreement)).to eq(:disagree)
      expect(result[:overall_agreement]).to eq(:disagree)
    end

    it "returns no_data when mavedb and clinvar evidence is absent" do
      Mavedb::Score.delete_all
      Clinvar::Classification.delete_all

      variant = Variant.create!(
        protein: protein,
        hgvs_protein: "p.Arg175His",
        residue_position: 175,
        ref_aa: "R",
        alt_aa: "H"
      )
      interpretation = {
        preliminary_mechanism: "unannotated region",
        confidence: "low",
        domain_hit: false,
        structure_hit: false
      }

      result = described_class.call(variant, interpretation)

      expect(result.dig(:mavedb, :agreement)).to eq(:no_data)
      expect(result.dig(:clinvar, :agreement)).to eq(:no_data)
      expect(result[:overall_agreement]).to eq(:no_data)
    end
  end
end
