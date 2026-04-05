require 'rails_helper'

RSpec.describe 'Variants', type: :request do
  describe 'GET /variants/:id' do
    it 'renders variant interpretation details' do
      protein = Protein.create!(
        uniprot_accession: 'P04637',
        gene_symbol: 'TP53'
      )
      protein.protein_features.create!(
        feature_type: 'domain',
        start_pos: 100,
        end_pos: 200,
        description: 'DNA-binding'
      )
      protein.structure_entries.create!(
        pdb_id: '1TUP',
        method: 'X-ray diffraction',
        chain_id: 'A',
        start_pos: 90,
        end_pos: 210
      )
      variant = protein.variants.create!(
        hgvs_protein: 'p.Arg175His',
        residue_position: 175,
        ref_aa: 'R',
        alt_aa: 'H'
      )

      get variant_path(variant)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Variant Summary')
      expect(response.body).to include('Interpretation')
      expect(response.body).to include('structured functional region')
      expect(response.body).to include('high')
      expect(response.body).to include('Matching Features')
      expect(response.body).to include('DNA-binding')
      expect(response.body).to include('Matching Structures')
      expect(response.body).to include('1TUP')
    end
  end
end
