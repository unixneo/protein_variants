require 'rails_helper'

RSpec.describe 'Proteins', type: :request do
  describe 'GET /proteins' do
    it 'renders protein cards with counts' do
      protein = Protein.create!(
        uniprot_accession: 'P04637',
        gene_symbol: 'TP53',
        recommended_name: 'Cellular tumor antigen p53',
        organism: 'Homo sapiens'
      )
      protein.variants.create!(
        hgvs_protein: 'p.Arg175His',
        residue_position: 175,
        ref_aa: 'R',
        alt_aa: 'H'
      )
      protein.protein_features.create!(
        feature_type: 'domain',
        start_pos: 95,
        end_pos: 289
      )
      protein.structure_entries.create!(
        pdb_id: '1TUP',
        method: 'X-ray diffraction'
      )

      get proteins_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('P04637')
      expect(response.body).to include('TP53')
      expect(response.body).to include('Variants <strong>1</strong>')
      expect(response.body).to include('Features <strong>1</strong>')
      expect(response.body).to include('Structures <strong>1</strong>')
    end
  end

  describe 'GET /proteins/:id' do
    it 'renders protein sections and variant links' do
      protein = Protein.create!(
        uniprot_accession: 'Q9Y6K9',
        gene_symbol: 'TEST1',
        recommended_name: 'Test Protein',
        organism: 'Homo sapiens',
        sequence: 'ABCDE',
        sequence_length: 5
      )
      protein.protein_features.create!(
        feature_type: 'region',
        start_pos: 1,
        end_pos: 4,
        description: 'Feature row'
      )
      protein.structure_entries.create!(
        pdb_id: '2ABC',
        method: 'NMR',
        chain_id: 'A',
        start_pos: 1,
        end_pos: 5
      )
      variant = protein.variants.create!(
        hgvs_protein: 'p.Ala2Val',
        residue_position: 2,
        ref_aa: 'A',
        alt_aa: 'V'
      )

      get protein_path(protein)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Sequence Metadata')
      expect(response.body).to include('Protein Features')
      expect(response.body).to include('Structure Entries')
      expect(response.body).to include('Variants')
      expect(response.body).to include(variant.hgvs_protein)
      expect(response.body).to include(variant_path(variant))
    end
  end
end
