require "rails_helper"
require "securerandom"

RSpec.describe "Database selection", type: :model do
  it "routes Protein and Uniprot::Entry to their expected sqlite files with separate reads/writes" do
    skip "This spec validates development database paths." unless Rails.env.development?

    protein_db = Pathname.new(Protein.connection_db_config.database).cleanpath.to_s
    uniprot_db = Pathname.new(Uniprot::Entry.connection_db_config.database).cleanpath.to_s

    expect(protein_db).to eq("db/development.sqlite3")
    expect(uniprot_db).to eq("db/uniprot.sqlite3")
    expect(protein_db).not_to eq(uniprot_db)

    expect(Protein.connection.table_exists?(:proteins)).to be(true)
    expect(Uniprot::Entry.connection.table_exists?(:entries)).to be(true)

    protein_count_before = Protein.count
    uniprot_count_before = Uniprot::Entry.count

    protein_accession = "PDBSEL#{SecureRandom.hex(4)}"
    entry_accession = "UDBSEL#{SecureRandom.hex(4)}"

    Protein.create!(uniprot_accession: protein_accession)
    Uniprot::Entry.create!(accession: entry_accession, name: "db-selection-test")

    expect(Protein.count).to eq(protein_count_before + 1)
    expect(Uniprot::Entry.count).to eq(uniprot_count_before + 1)
    expect(Protein.find_by!(uniprot_accession: protein_accession)).to be_present
    expect(Uniprot::Entry.find_by!(accession: entry_accession)).to be_present
  ensure
    Protein.where("uniprot_accession LIKE ?", "PDBSEL%").delete_all
    Uniprot::Entry.where("accession LIKE ?", "UDBSEL%").delete_all
  end
end
