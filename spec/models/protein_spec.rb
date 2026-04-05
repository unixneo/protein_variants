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

  describe '#uniprot_entry' do
    before do
      connection = Uniprot::Entry.connection
      next if connection.table_exists?(:entries)

      connection.create_table :entries do |t|
        t.string :accession
        t.string :name
      end
    end

    it 'returns matching uniprot entry by accession' do
      Uniprot::Entry.delete_all
      protein = described_class.create!(uniprot_accession: 'P04637')
      entry = Uniprot::Entry.create!(accession: 'P04637', name: 'Cellular tumor antigen p53')

      expect(protein.uniprot_entry).to eq(entry)
    end

    it 'returns nil when no uniprot entry matches' do
      Uniprot::Entry.delete_all
      protein = described_class.create!(uniprot_accession: 'Q99999')

      expect(protein.uniprot_entry).to be_nil
    end
  end
end
