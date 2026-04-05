require "rails_helper"

RSpec.describe "Scoring" do
  describe VariantInterpretationService do
    let(:protein) { Protein.create!(uniprot_accession: "P04637") }
    let(:variant) do
      Variant.create!(
        protein: protein,
        hgvs_protein: "p.Arg175His",
        residue_position: 175,
        ref_aa: "R",
        alt_aa: "H"
      )
    end
    subject(:service) { described_class.new(variant) }

    it "returns structural_confidence_score 60 when domain and structure hit with best resolution <= 2.0" do
      structure_matches = [Struct.new(:resolution).new(1.8)]

      score = service.send(
        :structural_confidence_score,
        domain_hit: true,
        structure_hit: true,
        structure_matches: structure_matches
      )

      expect(score).to eq(60)
    end

    it "returns structural_confidence_score 50 when domain and structure hit with best resolution > 2.0" do
      structure_matches = [Struct.new(:resolution).new(2.5)]

      score = service.send(
        :structural_confidence_score,
        domain_hit: true,
        structure_hit: true,
        structure_matches: structure_matches
      )

      expect(score).to eq(50)
    end

    it "returns :high for structural_confidence_level with score >= 45" do
      expect(service.send(:structural_confidence_level, 45)).to eq(:high)
      expect(service.send(:structural_confidence_level, 60)).to eq(:high)
    end

    it "returns :moderate for structural_confidence_level with score >= 25 and < 45" do
      expect(service.send(:structural_confidence_level, 25)).to eq(:moderate)
      expect(service.send(:structural_confidence_level, 44)).to eq(:moderate)
    end

    it "returns :low for structural_confidence_level with score < 25" do
      expect(service.send(:structural_confidence_level, 24)).to eq(:low)
      expect(service.send(:structural_confidence_level, 0)).to eq(:low)
    end
  end

  describe EvidenceValidatorService do
    let(:protein) { Protein.create!(uniprot_accession: "P04637") }
    let(:variant) do
      Variant.create!(
        protein: protein,
        hgvs_protein: "p.Arg175His",
        residue_position: 175,
        ref_aa: "R",
        alt_aa: "H"
      )
    end

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

    it "returns evidence_confidence_score 20 for mavedb score >= 0.7" do
      service = described_class.new(variant, { structural_confidence_score: 0, domain_hit: false, structure_hit: false })
      mavedb = Mavedb::Score.new(hgvs_pro: "p.Arg175His", score: 0.7)

      expect(service.send(:evidence_confidence_score, mavedb, nil)).to eq(20)
    end

    it "returns evidence_confidence_score 10 for mavedb score >= 0.5 and < 0.7" do
      service = described_class.new(variant, { structural_confidence_score: 0, domain_hit: false, structure_hit: false })
      mavedb = Mavedb::Score.new(hgvs_pro: "p.Arg175His", score: 0.6)

      expect(service.send(:evidence_confidence_score, mavedb, nil)).to eq(10)
    end

    it "returns clinvar_axis_score 15 for expert panel review status" do
      service = described_class.new(variant, { structural_confidence_score: 0, domain_hit: false, structure_hit: false })
      clinvar = Clinvar::Classification.new(
        hgvs_pro: "p.Arg175His",
        clinical_significance: "Pathogenic",
        review_status: "reviewed by expert panel"
      )

      expect(service.send(:clinvar_axis_score, clinvar)).to eq(15)
    end

    it "returns clinvar_axis_score 5 for pathogenic classification without expert panel" do
      service = described_class.new(variant, { structural_confidence_score: 0, domain_hit: false, structure_hit: false })
      clinvar = Clinvar::Classification.new(
        hgvs_pro: "p.Arg175His",
        clinical_significance: "Pathogenic",
        review_status: "criteria provided"
      )

      expect(service.send(:clinvar_axis_score, clinvar)).to eq(5)
    end

    it "returns :high for combined_confidence_level when combined score >= 70" do
      service = described_class.new(variant, { structural_confidence_score: 50, domain_hit: false, structure_hit: false })

      expect(service.send(:combined_confidence_level, 20)).to eq(:high)
    end

    it "returns :moderate for combined_confidence_level when combined score >= 40 and < 70" do
      service = described_class.new(variant, { structural_confidence_score: 30, domain_hit: false, structure_hit: false })

      expect(service.send(:combined_confidence_level, 10)).to eq(:moderate)
    end

    it "returns :low for combined_confidence_level when combined score < 40" do
      service = described_class.new(variant, { structural_confidence_score: 20, domain_hit: false, structure_hit: false })

      expect(service.send(:combined_confidence_level, 10)).to eq(:low)
    end
  end
end
