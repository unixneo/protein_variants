require 'rails_helper'

RSpec.describe Protein, type: :model do
  describe 'associations' do
    it 'has many variants' do
      association = described_class.reflect_on_association(:variants)

      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'is valid with a uniprot_accession' do
      protein = described_class.new(uniprot_accession: 'P12345')

      expect(protein).to be_valid
    end

    it 'is invalid without a uniprot_accession' do
      protein = described_class.new(uniprot_accession: nil)

      expect(protein).not_to be_valid
      expect(protein.errors[:uniprot_accession]).to include("can't be blank")
    end

    it 'enforces unique uniprot_accession' do
      described_class.create!(uniprot_accession: 'P12345')
      duplicate = described_class.new(uniprot_accession: 'P12345')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uniprot_accession]).to include('has already been taken')
    end
  end
end
