require 'rails_helper'

RSpec.describe Mavedb::Score, type: :model do
  before do
    connection = described_class.connection
    next if connection.table_exists?(:scores)

    connection.create_table :scores do |t|
      t.string :hgvs_pro
      t.float :score
      t.string :score_set_urn
      t.string :source
    end
  end

  describe 'table mapping' do
    it 'uses the correct table name' do
      expect(described_class.table_name).to eq('scores')
    end
  end

  describe 'persistence' do
    it 'can be created and persisted with hgvs_pro, score, source, and score_set_urn' do
      described_class.delete_all

      record = described_class.create!(
        hgvs_pro: 'p.Arg175His',
        score: 1.025,
        source: 'Giacomelli2018',
        score_set_urn: 'urn:mavedb:00000068-0-1'
      )

      expect(record).to be_persisted
      expect(record.hgvs_pro).to eq('p.Arg175His')
      expect(record.source).to eq('Giacomelli2018')
      expect(record.score_set_urn).to eq('urn:mavedb:00000068-0-1')
      expect(record.score).to be_a(Float)
      expect(record.score).to eq(1.025)
    end

    it 'keeps a second record with different hgvs_pro independent' do
      described_class.delete_all

      first = described_class.create!(
        hgvs_pro: 'p.Arg175His',
        score: 1.025,
        source: 'Giacomelli2018',
        score_set_urn: 'urn:mavedb:00000068-0-1'
      )
      second = described_class.create!(
        hgvs_pro: 'p.Arg273His',
        score: 0.612,
        source: 'Kotler2018',
        score_set_urn: 'urn:mavedb:00000068-a-1'
      )

      expect(described_class.where(hgvs_pro: first.hgvs_pro)).to contain_exactly(first)
      expect(described_class.where(hgvs_pro: second.hgvs_pro)).to contain_exactly(second)
    end
  end
end
