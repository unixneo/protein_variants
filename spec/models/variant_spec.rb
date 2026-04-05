require 'rails_helper'

RSpec.describe Variant, type: :model do
  let(:protein) { Protein.create!(uniprot_accession: 'P12345') }

  describe 'associations' do
    it 'belongs to protein' do
      association = described_class.reflect_on_association(:protein)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with required attributes' do
      variant = described_class.new(
        protein: protein,
        hgvs_protein: 'p.Gly12Asp',
        residue_position: 12,
        ref_aa: 'G',
        alt_aa: 'D'
      )

      expect(variant).to be_valid
    end

    it 'is invalid without hgvs_protein' do
      variant = described_class.new(
        protein: protein,
        hgvs_protein: nil,
        residue_position: 12,
        ref_aa: 'G',
        alt_aa: 'D'
      )

      expect(variant).not_to be_valid
      expect(variant.errors[:hgvs_protein]).to include("can't be blank")
    end

    it 'is invalid without residue_position' do
      variant = described_class.new(
        protein: protein,
        hgvs_protein: 'p.Gly12Asp',
        residue_position: nil,
        ref_aa: 'G',
        alt_aa: 'D'
      )

      expect(variant).not_to be_valid
      expect(variant.errors[:residue_position]).to include("can't be blank")
    end

    it 'is invalid without ref_aa' do
      variant = described_class.new(
        protein: protein,
        hgvs_protein: 'p.Gly12Asp',
        residue_position: 12,
        ref_aa: nil,
        alt_aa: 'D'
      )

      expect(variant).not_to be_valid
      expect(variant.errors[:ref_aa]).to include("can't be blank")
    end

    it 'is invalid without alt_aa' do
      variant = described_class.new(
        protein: protein,
        hgvs_protein: 'p.Gly12Asp',
        residue_position: 12,
        ref_aa: 'G',
        alt_aa: nil
      )

      expect(variant).not_to be_valid
      expect(variant.errors[:alt_aa]).to include("can't be blank")
    end

    it 'is invalid without protein' do
      variant = described_class.new(
        protein: nil,
        hgvs_protein: 'p.Gly12Asp',
        residue_position: 12,
        ref_aa: 'G',
        alt_aa: 'D'
      )

      expect(variant).not_to be_valid
      expect(variant.errors[:protein]).to include('must exist')
    end
  end

  describe '#mavedb_score' do
    before do
      connection = Mavedb::Score.connection
      next if connection.table_exists?(:scores)

      connection.create_table :scores do |t|
        t.string :hgvs_pro
        t.float :score
        t.string :score_set_urn
        t.string :source
      end
    end

    it 'returns the matching mavedb score and excludes non-matching records' do
      Mavedb::Score.delete_all
      variant = described_class.create!(
        protein: protein,
        hgvs_protein: 'p.Arg175His',
        residue_position: 175,
        ref_aa: 'R',
        alt_aa: 'H'
      )
      match = Mavedb::Score.create!(hgvs_pro: 'p.Arg175His', score: 1.025, source: 'Giacomelli2018')
      non_match = Mavedb::Score.create!(hgvs_pro: 'p.Arg999Xxx', score: 0.1, source: 'Giacomelli2018')

      expect(variant.mavedb_score).to eq(match)
      expect(variant.mavedb_score).not_to eq(non_match)
    end
  end

  describe '#clinvar_classification' do
    before do
      connection = Clinvar::Classification.connection
      next if connection.table_exists?(:classifications)

      connection.create_table :classifications do |t|
        t.string :hgvs_pro
        t.string :variation_id
        t.string :clinical_significance
        t.string :review_status
        t.string :last_evaluated
      end
    end

    it 'returns the matching clinvar classification and excludes non-matching records' do
      Clinvar::Classification.delete_all
      variant = described_class.create!(
        protein: protein,
        hgvs_protein: 'p.Arg175His',
        residue_position: 175,
        ref_aa: 'R',
        alt_aa: 'H'
      )
      match = Clinvar::Classification.create!(
        hgvs_pro: 'p.Arg175His',
        clinical_significance: 'Pathogenic',
        review_status: 'reviewed by expert panel'
      )
      non_match = Clinvar::Classification.create!(
        hgvs_pro: 'p.Arg999Xxx',
        clinical_significance: 'Benign',
        review_status: 'no assertion criteria provided'
      )

      expect(variant.clinvar_classification).to eq(match)
      expect(variant.clinvar_classification).not_to eq(non_match)
    end
  end
end
