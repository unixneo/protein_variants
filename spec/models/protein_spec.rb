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

  describe '#pdb_structures' do
    before do
      connection = Pdb::Structure.connection
      next if connection.table_exists?(:structures)

      connection.create_table :structures do |t|
        t.string :pdb_id
        t.string :title
        t.string :chain_id
        t.integer :start_pos
        t.integer :end_pos
        t.float :resolution
        t.string :method
        t.string :uniprot_accession
      end
    end

    it 'returns only matching pdb structures ordered by start_pos' do
      Pdb::Structure.delete_all
      protein = described_class.create!(uniprot_accession: 'P04637')

      matching_late = Pdb::Structure.create!(pdb_id: '2OCJ', start_pos: 90, uniprot_accession: 'P04637')
      matching_early = Pdb::Structure.create!(pdb_id: '1TUP', start_pos: 50, uniprot_accession: 'P04637')
      non_matching = Pdb::Structure.create!(pdb_id: '9XYZ', start_pos: 10, uniprot_accession: 'Q99999')

      result = protein.pdb_structures.to_a

      expect(result).to eq([matching_early, matching_late])
      expect(result).not_to include(non_matching)
    end
  end
end
