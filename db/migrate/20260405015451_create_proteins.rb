class CreateProteins < ActiveRecord::Migration[7.2]
  def change
    create_table :proteins do |t|
      t.string :uniprot_accession, null: false
      t.string :gene_symbol
      t.string :recommended_name
      t.string :organism
      t.text :sequence
      t.integer :sequence_length

      t.timestamps
    end

    add_index :proteins, :uniprot_accession, unique: true
  end
end
