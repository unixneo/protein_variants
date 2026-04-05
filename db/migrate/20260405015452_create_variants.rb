class CreateVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :variants do |t|
      t.references :protein, null: false, foreign_key: true
      t.string :hgvs_protein, null: false
      t.integer :residue_position, null: false
      t.string :ref_aa, null: false
      t.string :alt_aa, null: false

      t.timestamps
    end

    add_index :variants, [ :protein_id, :residue_position ]
  end
end
