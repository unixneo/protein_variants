require 'rails_helper'

RSpec.describe 'Tau protein fixture', type: :model do
  before do
    ProteinFixtureImporter.call(Rails.root.join('db/fixtures/tau.json'))
  end

  subject(:protein) { Protein.find_by!(uniprot_accession: 'P10636') }

  it 'is present' do
    expect(protein).to be_present
  end

  it 'has 5 protein_features' do
    expect(protein.protein_features.count).to eq(5)
  end

  it 'has 3 structure_entries' do
    expect(protein.structure_entries.count).to eq(3)
  end

  it 'has 3 variants' do
    expect(protein.variants.count).to eq(3)
  end
end
