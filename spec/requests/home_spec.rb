require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    it 'renders the landing page' do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Protein Variant Inspection')
      expect(response.body).to include('Browse Proteins')
      expect(response.body).to include('Import TP53 Fixture')
    end
  end
end
