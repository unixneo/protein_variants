require 'rails_helper'

RSpec.describe 'APP protein fixture', type: :model do
  before do
    ProteinFixtureImporter.call(Rails.root.join('db/fixtures/app.json'))
  end

  subject(:protein) { Protein.find_by!(uniprot_accession: 'P05067') }

  it 'is present' do
    expect(protein).to be_present
  end

  it 'has 4 protein_features' do
    expect(protein.protein_features.count).to eq(4)
  end

  it 'has 2 structure_entries' do
    expect(protein.structure_entries.count).to eq(2)
  end

  it 'has 3 variants' do
    expect(protein.variants.count).to eq(3)
  end
end
