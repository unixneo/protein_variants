ActiveRecord::Schema[7.2].define do
  create_table "structures", force: :cascade do |t|
    t.string "pdb_id"
    t.string "title"
    t.string "chain_id"
    t.integer "start_pos"
    t.integer "end_pos"
    t.float "resolution"
    t.string "method"
    t.string "uniprot_accession"
  end
end
