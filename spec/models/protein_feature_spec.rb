require 'rails_helper'

RSpec.describe ProteinFeature, type: :model do
  let(:protein) { Protein.create!(uniprot_accession: 'P12345') }

  describe 'associations' do
    it 'belongs to protein' do
      association = described_class.reflect_on_association(:protein)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with required attributes' do
      protein_feature = described_class.new(
        protein: protein,
        feature_type: 'domain',
        start_pos: 10,
        end_pos: 50,
        description: 'Functional domain',
        source_db: 'UniProt'
      )

      expect(protein_feature).to be_valid
    end

    it 'is invalid without feature_type' do
      protein_feature = described_class.new(
        protein: protein,
        feature_type: nil,
        start_pos: 10,
        end_pos: 50
      )

      expect(protein_feature).not_to be_valid
      expect(protein_feature.errors[:feature_type]).to include("can't be blank")
    end

    it 'is invalid without start_pos' do
      protein_feature = described_class.new(
        protein: protein,
        feature_type: 'domain',
        start_pos: nil,
        end_pos: 50
      )

      expect(protein_feature).not_to be_valid
      expect(protein_feature.errors[:start_pos]).to include("can't be blank")
    end

    it 'is invalid without end_pos' do
      protein_feature = described_class.new(
        protein: protein,
        feature_type: 'domain',
        start_pos: 10,
        end_pos: nil
      )

      expect(protein_feature).not_to be_valid
      expect(protein_feature.errors[:end_pos]).to include("can't be blank")
    end
  end
end
