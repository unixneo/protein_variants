class Protein < ApplicationRecord
  has_many :variants, dependent: :destroy

  validates :uniprot_accession, presence: true, uniqueness: true
end
