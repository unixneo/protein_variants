# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_05_021240) do
  create_table "entries", force: :cascade do |t|
    t.string "accession"
    t.string "name"
  end

  create_table "protein_features", force: :cascade do |t|
    t.integer "protein_id", null: false
    t.string "feature_type", null: false
    t.integer "start_pos", null: false
    t.integer "end_pos", null: false
    t.text "description"
    t.string "source_db"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["protein_id", "feature_type"], name: "index_protein_features_on_protein_id_and_feature_type"
    t.index ["protein_id", "source_db"], name: "index_protein_features_on_protein_id_and_source_db"
    t.index ["protein_id"], name: "index_protein_features_on_protein_id"
  end

  create_table "proteins", force: :cascade do |t|
    t.string "uniprot_accession", null: false
    t.string "gene_symbol"
    t.string "recommended_name"
    t.string "organism"
    t.text "sequence"
    t.integer "sequence_length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uniprot_accession"], name: "index_proteins_on_uniprot_accession", unique: true
  end

  create_table "structure_entries", force: :cascade do |t|
    t.integer "protein_id", null: false
    t.string "pdb_id", null: false
    t.string "method", null: false
    t.decimal "resolution"
    t.string "chain_id"
    t.integer "start_pos"
    t.integer "end_pos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["method"], name: "index_structure_entries_on_method"
    t.index ["protein_id", "pdb_id"], name: "index_structure_entries_on_protein_id_and_pdb_id"
    t.index ["protein_id"], name: "index_structure_entries_on_protein_id"
  end

  create_table "variants", force: :cascade do |t|
    t.integer "protein_id", null: false
    t.string "hgvs_protein", null: false
    t.integer "residue_position", null: false
    t.string "ref_aa", null: false
    t.string "alt_aa", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["protein_id", "residue_position"], name: "index_variants_on_protein_id_and_residue_position"
    t.index ["protein_id"], name: "index_variants_on_protein_id"
  end

  add_foreign_key "protein_features", "proteins"
  add_foreign_key "structure_entries", "proteins"
  add_foreign_key "variants", "proteins"
end
