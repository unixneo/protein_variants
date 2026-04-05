class Protein < ApplicationRecord
  has_many :protein_features, dependent: :destroy
  has_many :structure_entries, dependent: :destroy
  has_many :variants, dependent: :destroy

  validates :uniprot_accession, presence: true, uniqueness: true

  def uniprot_entry
    Uniprot::Entry.find_by(accession: uniprot_accession)
  end
end
