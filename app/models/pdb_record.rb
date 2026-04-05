class PdbRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :pdb }
end
