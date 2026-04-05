class CreateProteinFeatures < ActiveRecord::Migration[7.2]
  def change
    create_table :protein_features do |t|
      t.references :protein, null: false, foreign_key: true
      t.string :feature_type, null: false
      t.integer :start_pos, null: false
      t.integer :end_pos, null: false
      t.text :description
      t.string :source_db

      t.timestamps
    end

    add_index :protein_features, [ :protein_id, :feature_type ]
    add_index :protein_features, [ :protein_id, :source_db ]
  end
end
