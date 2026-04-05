require 'rails_helper'

RSpec.describe StructureEntry, type: :model do
  let(:protein) { Protein.create!(uniprot_accession: 'P12345') }

  describe 'associations' do
    it 'belongs to protein' do
      association = described_class.reflect_on_association(:protein)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with required attributes' do
      structure_entry = described_class.new(
        protein: protein,
        pdb_id: '1ABC',
        method: 'X-ray diffraction',
        resolution: 1.8,
        chain_id: 'A',
        start_pos: 5,
        end_pos: 120
      )

      expect(structure_entry).to be_valid
    end

    it 'is invalid without pdb_id' do
      structure_entry = described_class.new(
        protein: protein,
        pdb_id: nil,
        method: 'X-ray diffraction'
      )

      expect(structure_entry).not_to be_valid
      expect(structure_entry.errors[:pdb_id]).to include("can't be blank")
    end

    it 'is invalid without method' do
      structure_entry = described_class.new(
        protein: protein,
        pdb_id: '1ABC',
        method: nil
      )

      expect(structure_entry).not_to be_valid
      expect(structure_entry.errors[:method]).to include("can't be blank")
    end
  end
end
