require "rails_helper"

RSpec.describe Uniprot::Entry, type: :model do
  before do
    connection = described_class.connection
    next if connection.table_exists?(:entries)

    connection.create_table :entries do |t|
      t.string :accession
      t.string :name
    end
  end

  it "creates and reads an entry from the uniprot database" do
    described_class.delete_all

    created = described_class.create!(accession: "P04637", name: "Cellular tumor antigen p53")
    found = described_class.find_by!(accession: "P04637")

    expect(found.id).to eq(created.id)
    expect(found.name).to eq("Cellular tumor antigen p53")
  end
end
