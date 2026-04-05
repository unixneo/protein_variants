require 'rails_helper'

RSpec.describe 'proteins/show.html.erb', type: :view do
  it 'renders protein sections' do
    protein = Protein.create!(
      uniprot_accession: 'P04637',
      gene_symbol: 'TP53',
      sequence_length: 10
    )
    protein.variants.create!(
      hgvs_protein: 'p.Arg175His',
      residue_position: 175,
      ref_aa: 'R',
      alt_aa: 'H'
    )
    assign(:protein, protein)

    render

    expect(rendered).to include('Sequence Metadata')
    expect(rendered).to include('p.Arg175His')
  end
end
