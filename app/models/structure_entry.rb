class StructureEntry < ApplicationRecord
  belongs_to :protein

  validates :pdb_id, :method, presence: true
end
