require "rails_helper"

RSpec.describe "Utilities", type: :request do
  describe "POST /import_tp53_fixture" do
    it "imports fixture data, redirects, and shows summary flash" do
      summary = {
        protein_created_or_updated: 1,
        protein_features_loaded: 2,
        structure_entries_loaded: 2,
        variants_loaded: 3
      }
      allow(Tp53FixtureImporter).to receive(:call).and_return(summary)

      post import_tp53_fixture_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("TP53 fixture imported.")
      expect(response.body).to include("protein_created_or_updated=1")
      expect(response.body).to include("protein_features_loaded=2")
      expect(response.body).to include("structure_entries_loaded=2")
      expect(response.body).to include("variants_loaded=3")
    end

    it "handles importer errors and redirects with error flash" do
      allow(Tp53FixtureImporter).to receive(:call).and_raise(StandardError, "simulated failure")

      post import_tp53_fixture_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("TP53 fixture import failed: simulated failure")
    end
  end
end
