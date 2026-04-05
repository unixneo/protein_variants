require 'rails_helper'

RSpec.describe 'variants/show.html.erb', type: :view do
  it 'renders interpretation sections' do
    protein = Protein.create!(uniprot_accession: 'P04637')
    variant = protein.variants.create!(
      hgvs_protein: 'p.Arg175His',
      residue_position: 175,
      ref_aa: 'R',
      alt_aa: 'H'
    )
    assign(:variant, variant)
    assign(
      :interpretation,
      {
        preliminary_mechanism: 'structured functional region',
        confidence: 'medium',
        domain_hit: true,
        structure_hit: true,
        matching_features: [],
        matching_structures: []
      }
    )
    assign(
      :evidence,
      {
        system_mechanism: 'structured functional region',
        system_confidence: 'medium',
        mavedb: { agreement: :agree, note: 'ok' },
        clinvar: { agreement: :agree, note: 'ok' },
        overall_agreement: :agree
      }
    )

    render

    expect(rendered).to include('Interpretation')
    expect(rendered).to include('structured functional region')
  end
end
