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
end
