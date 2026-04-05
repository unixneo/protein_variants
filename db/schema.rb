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

ActiveRecord::Schema[7.2].define(version: 2026_04_05_015452) do
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

  add_foreign_key "variants", "proteins"
end
