class Variant < ApplicationRecord
  belongs_to :protein

  validates :hgvs_protein, :residue_position, :ref_aa, :alt_aa, presence: true

  def mavedb_score
    Mavedb::Score.find_by(hgvs_pro: hgvs_protein)
  end

  def clinvar_classification
    Clinvar::Classification.find_by(hgvs_pro: hgvs_protein)
  end
end
