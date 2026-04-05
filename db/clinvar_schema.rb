ActiveRecord::Schema[7.2].define do
  create_table "classifications", force: :cascade do |t|
    t.string "hgvs_pro"
    t.string "variation_id"
    t.string "clinical_significance"
    t.string "review_status"
    t.string "last_evaluated"
  end
end
