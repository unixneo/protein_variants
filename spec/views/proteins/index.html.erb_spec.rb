require 'rails_helper'

RSpec.describe 'proteins/index.html.erb', type: :view do
  it 'renders proteins' do
    protein = Protein.create!(uniprot_accession: 'P04637', gene_symbol: 'TP53')
    assign(:proteins, [ protein ])

    render

    expect(rendered).to include('P04637')
    expect(rendered).to include('TP53')
  end
end
