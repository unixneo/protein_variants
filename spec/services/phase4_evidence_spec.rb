require 'rails_helper'

RSpec.describe 'Phase 4 evidence' do
  before do
    ProteinFixtureImporter.call(Rails.root.join('db/fixtures/tau.json'))
  end

  describe EvidenceValidatorService do
    it 'returns no_data agreements and zero evidence score for p.Pro619Leu' do
      variant = Protein.find_by!(uniprot_accession: 'P10636').variants.find_by!(hgvs_protein: 'p.Pro619Leu')
      interpretation = VariantInterpretationService.call(variant)

      result = described_class.call(variant, interpretation)

      expect(result.dig(:mavedb, :agreement)).to eq(:no_data)
      expect(result.dig(:clinvar, :agreement)).to eq(:no_data)
      expect(result[:overall_agreement]).to eq(:no_data)
      expect(result[:evidence_confidence_score]).to eq(0)
    end
  end
end
