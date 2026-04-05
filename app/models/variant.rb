class Variant < ApplicationRecord
  belongs_to :protein

  validates :hgvs_protein, :residue_position, :ref_aa, :alt_aa, presence: true
end
