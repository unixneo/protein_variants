ActiveRecord::Schema[7.2].define do
  create_table "entries", force: :cascade do |t|
    t.string "accession"
    t.string "name"
  end
end
