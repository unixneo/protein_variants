require 'rails_helper'

RSpec.describe Clinvar::Classification, type: :model do
  before do
    connection = described_class.connection
    next if connection.table_exists?(:classifications)

    connection.create_table :classifications do |t|
      t.string :hgvs_pro
      t.string :variation_id
      t.string :clinical_significance
      t.string :review_status
      t.string :last_evaluated
    end
  end

  describe 'table mapping' do
    it 'uses the correct table name' do
      expect(described_class.table_name).to eq('classifications')
    end
  end

  describe 'persistence' do
    it 'can be created and persisted with hgvs_pro, clinical_significance, and review_status' do
      described_class.delete_all

      record = described_class.create!(
        hgvs_pro: 'p.Arg175His',
        clinical_significance: 'Pathogenic',
        review_status: 'reviewed by expert panel'
      )

      expect(record).to be_persisted
      expect(record.hgvs_pro).to eq('p.Arg175His')
      expect(record.clinical_significance).to be_a(String)
      expect(record.review_status).to be_a(String)
      expect(record.clinical_significance).to eq('Pathogenic')
      expect(record.review_status).to eq('reviewed by expert panel')
    end

    it 'keeps a second record with different hgvs_pro independent' do
      described_class.delete_all

      first = described_class.create!(
        hgvs_pro: 'p.Arg175His',
        clinical_significance: 'Pathogenic',
        review_status: 'reviewed by expert panel'
      )
      second = described_class.create!(
        hgvs_pro: 'p.Arg273His',
        clinical_significance: 'Likely pathogenic',
        review_status: 'criteria provided'
      )

      expect(described_class.where(hgvs_pro: first.hgvs_pro)).to contain_exactly(first)
      expect(described_class.where(hgvs_pro: second.hgvs_pro)).to contain_exactly(second)
    end
  end
end
