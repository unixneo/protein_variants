require 'rails_helper'

RSpec.describe 'Intermediate TP53 variants integration' do
  before do
    Tp53FixtureImporter.call
    protein = Protein.find_by!(uniprot_accession: 'P04637')
    protein.protein_features.where.not(feature_type: 'domain').delete_all

    mavedb_connection = Mavedb::Score.connection
    unless mavedb_connection.table_exists?(:scores)
      mavedb_connection.create_table :scores do |t|
        t.string :hgvs_pro
        t.float :score
        t.string :score_set_urn
        t.string :source
      end
    end

    clinvar_connection = Clinvar::Classification.connection
    unless clinvar_connection.table_exists?(:classifications)
      clinvar_connection.create_table :classifications do |t|
        t.string :hgvs_pro
        t.string :variation_id
        t.string :clinical_significance
        t.string :review_status
        t.string :last_evaluated
      end
    end

    Mavedb::Score.delete_all
    Clinvar::Classification.delete_all

    Mavedb::Score.create!(hgvs_pro: 'p.Val143Leu', score: 0.327538, score_set_urn: 'urn:mavedb:00000068-0-1', source: 'Giacomelli2018')
    Mavedb::Score.create!(hgvs_pro: 'p.Arg181Asn', score: 0.580554, score_set_urn: 'urn:mavedb:00000068-0-1', source: 'Giacomelli2018')
    Mavedb::Score.create!(hgvs_pro: 'p.Arg290Pro', score: 0.248813, score_set_urn: 'urn:mavedb:00000068-0-1', source: 'Giacomelli2018')
    Mavedb::Score.create!(hgvs_pro: 'p.Leu299Ser', score: 0.357154, score_set_urn: 'urn:mavedb:00000068-0-1', source: 'Giacomelli2018')

    Clinvar::Classification.create!(
      hgvs_pro: 'p.Val143Leu',
      variation_id: '2687704',
      clinical_significance: 'Uncertain significance',
      review_status: 'no assertion criteria provided'
    )
    Clinvar::Classification.create!(
      hgvs_pro: 'p.Arg290Pro',
      variation_id: '458572',
      clinical_significance: 'Uncertain significance',
      review_status: 'criteria provided, single submitter'
    )
  end

  let(:protein) { Protein.find_by!(uniprot_accession: 'P04637') }

  def run_pipeline(hgvs)
    variant = protein.variants.find_by!(hgvs_protein: hgvs)
    interpretation = VariantInterpretationService.call(variant)
    evidence = EvidenceValidatorService.call(variant, interpretation)
    [interpretation, evidence]
  end

  describe 'VariantInterpretationService' do
    it 'interprets p.Val143Leu as structured functional region' do
      interpretation, = run_pipeline('p.Val143Leu')

      expect(interpretation[:domain_hit]).to be(true)
      expect(interpretation[:structure_hit]).to be(true)
      expect(interpretation[:preliminary_mechanism]).to eq('structured functional region')
    end

    it 'interprets p.Arg181Asn as structured functional region' do
      interpretation, = run_pipeline('p.Arg181Asn')

      expect(interpretation[:domain_hit]).to be(true)
      expect(interpretation[:structure_hit]).to be(true)
      expect(interpretation[:preliminary_mechanism]).to eq('structured functional region')
    end

    it 'interprets p.Arg290Pro as structured region' do
      interpretation, = run_pipeline('p.Arg290Pro')

      expect(interpretation[:domain_hit]).to be(false)
      expect(interpretation[:structure_hit]).to be(true)
      expect(interpretation[:preliminary_mechanism]).to eq('structured region')
    end

    it 'interprets p.Leu299Ser as structured region' do
      interpretation, = run_pipeline('p.Leu299Ser')

      expect(interpretation[:domain_hit]).to be(false)
      expect(interpretation[:structure_hit]).to be(true)
      expect(interpretation[:preliminary_mechanism]).to eq('structured region')
    end

    it 'interprets p.Met1Asn as unannotated region' do
      interpretation, = run_pipeline('p.Met1Asn')

      expect(interpretation[:domain_hit]).to be(false)
      expect(interpretation[:structure_hit]).to be(false)
      expect(interpretation[:preliminary_mechanism]).to eq('unannotated region')
    end
  end

  describe 'EvidenceValidatorService' do
    it 'returns deterministic disagree outcomes for p.Val143Leu' do
      _, evidence = run_pipeline('p.Val143Leu')

      expect(evidence.dig(:clinvar, :agreement)).to eq(:disagree)
      expect(evidence[:overall_agreement]).to eq(:disagree)
      expect(evidence[:overall_agreement]).not_to eq(:no_data)
    end

    it 'returns mavedb data and no clinvar data for p.Arg181Asn' do
      _, evidence = run_pipeline('p.Arg181Asn')

      expect(evidence.dig(:mavedb, :agreement)).not_to eq(:no_data)
      expect(evidence.dig(:clinvar, :agreement)).to eq(:no_data)
      expect(evidence[:overall_agreement]).not_to eq(:no_data)
    end

    it 'returns clinvar disagree for p.Arg290Pro' do
      _, evidence = run_pipeline('p.Arg290Pro')

      expect(evidence.dig(:clinvar, :agreement)).to eq(:disagree)
      expect(evidence[:overall_agreement]).to eq(:disagree)
    end

    it 'returns mavedb data and no clinvar data for p.Leu299Ser' do
      _, evidence = run_pipeline('p.Leu299Ser')

      expect(evidence.dig(:mavedb, :agreement)).not_to eq(:no_data)
      expect(evidence.dig(:clinvar, :agreement)).to eq(:no_data)
    end

    it 'handles p.Met1Asn with no clinvar and unflagged interpretation' do
      interpretation, evidence = run_pipeline('p.Met1Asn')

      expect(interpretation[:domain_hit]).to be(false)
      expect(interpretation[:structure_hit]).to be(false)
      expect(evidence.dig(:clinvar, :agreement)).to eq(:no_data)
      expect([:no_data, :disagree]).to include(evidence[:overall_agreement])
    end
  end
end
