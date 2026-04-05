class Protein < ApplicationRecord
  has_many :protein_features, dependent: :destroy
  has_many :structure_entries, dependent: :destroy
  has_many :variants, dependent: :destroy

  validates :uniprot_accession, presence: true, uniqueness: true
end
