class ProteinFeature < ApplicationRecord
  belongs_to :protein

  validates :feature_type, :start_pos, :end_pos, presence: true
end
