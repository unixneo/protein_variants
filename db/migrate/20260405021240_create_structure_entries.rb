class CreateStructureEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :structure_entries do |t|
      t.references :protein, null: false, foreign_key: true
      t.string :pdb_id, null: false
      t.string :method, null: false
      t.decimal :resolution
      t.string :chain_id
      t.integer :start_pos
      t.integer :end_pos

      t.timestamps
    end

    add_index :structure_entries, [ :protein_id, :pdb_id ]
    add_index :structure_entries, :method
  end
end
