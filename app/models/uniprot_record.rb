class UniprotRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :uniprot }
end
