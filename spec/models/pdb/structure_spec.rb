require "rails_helper"
require "securerandom"

RSpec.describe Pdb::Structure, type: :model do
  before do
    connection = described_class.connection
    next if connection.table_exists?(:structures)

    connection.create_table :structures do |t|
      t.string :pdb_id
      t.string :title
    end
  end

  it "uses the pdb database and is separate from main and uniprot databases in development" do
    skip "This spec validates development database paths." unless Rails.env.development?

    pdb_db = Pathname.new(described_class.connection_db_config.database).cleanpath.to_s
    protein_db = Pathname.new(Protein.connection_db_config.database).cleanpath.to_s
    uniprot_db = Pathname.new(Uniprot::Entry.connection_db_config.database).cleanpath.to_s

    expect(pdb_db).to eq("db/pdb.sqlite3")
    expect(pdb_db).not_to eq(protein_db)
    expect(pdb_db).not_to eq(uniprot_db)
  end

  it "creates and reads a structure row" do
    described_class.delete_all
    pdb_id = "1#{SecureRandom.hex(3).upcase}"
    title = "Test structure #{SecureRandom.hex(3)}"

    created = described_class.create!(pdb_id: pdb_id, title: title)
    found = described_class.find_by!(pdb_id: pdb_id)

    expect(found.id).to eq(created.id)
    expect(found.title).to eq(title)
  end
end
