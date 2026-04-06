require 'rails_helper'

RSpec.describe 'Phase 4 interpretation' do
  before do
    ProteinFixtureImporter.call(Rails.root.join('db/fixtures/tau.json'))
    ProteinFixtureImporter.call(Rails.root.join('db/fixtures/app.json'))
  end

  describe VariantInterpretationService do
    it 'returns expected interpretation for P10636 p.Pro619Leu' do
      variant = Protein.find_by!(uniprot_accession: 'P10636').variants.find_by!(hgvs_protein: 'p.Pro619Leu')

      result = described_class.call(variant)

      expect(result[:domain_hit]).to be(true)
      expect(result[:structure_hit]).to be(true)
      expect(result[:preliminary_mechanism]).to eq('structured functional region')
      expect(result[:structural_confidence_score]).to eq(50)
    end

    it 'returns expected interpretation for P10636 p.Arg724Trp' do
      variant = Protein.find_by!(uniprot_accession: 'P10636').variants.find_by!(hgvs_protein: 'p.Arg724Trp')

      result = described_class.call(variant)

      expect(result[:domain_hit]).to be(false)
      expect(result[:structure_hit]).to be(false)
      expect(result[:preliminary_mechanism]).to eq('unannotated region')
      expect(result[:structural_confidence_score]).to eq(0)
    end

    it 'returns expected interpretation for P05067 p.Ala692Gly' do
      variant = Protein.find_by!(uniprot_accession: 'P05067').variants.find_by!(hgvs_protein: 'p.Ala692Gly')

      result = described_class.call(variant)

      expect(result[:domain_hit]).to be(true)
      expect(result[:structure_hit]).to be(true)
      expect(result[:preliminary_mechanism]).to eq('structured functional region')
      expect(result[:structural_confidence_score]).to eq(50)
    end

    it 'returns expected interpretation for P05067 p.Val717Ile' do
      variant = Protein.find_by!(uniprot_accession: 'P05067').variants.find_by!(hgvs_protein: 'p.Val717Ile')

      result = described_class.call(variant)

      expect(result[:domain_hit]).to be(false)
      expect(result[:structure_hit]).to be(false)
      expect(result[:preliminary_mechanism]).to eq('unannotated region')
      expect(result[:structural_confidence_score]).to eq(0)
    end
  end
end
