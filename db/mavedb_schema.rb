ActiveRecord::Schema[7.2].define do
  create_table "scores", force: :cascade do |t|
    t.string "hgvs_pro"
    t.float  "score"
    t.string "score_set_urn"
    t.string "source"
  end
end
