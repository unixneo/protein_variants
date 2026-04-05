require "sqlite3"

namespace :db do
  desc "Rebuild db/uniprot.sqlite3 with only the entries table"
  task :rebuild_uniprot do
    path = Rails.root.join("db/uniprot.sqlite3")
    File.delete(path) if File.exist?(path)

    db = SQLite3::Database.new(path.to_s)
    db.execute <<~SQL
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY,
        accession varchar,
        name varchar
      );
    SQL
    db.close

    puts "Rebuilt #{path}"
  end

  desc "Rebuild db/pdb.sqlite3 with only the structures table"
  task :rebuild_pdb do
    path = Rails.root.join("db/pdb.sqlite3")
    File.delete(path) if File.exist?(path)

    db = SQLite3::Database.new(path.to_s)
    db.execute <<~SQL
      CREATE TABLE structures (
        id INTEGER PRIMARY KEY,
        pdb_id varchar,
        title varchar,
        chain_id varchar,
        start_pos integer,
        end_pos integer,
        resolution real,
        method varchar,
        uniprot_accession varchar
      );
    SQL
    db.close

    puts "Rebuilt #{path}"
  end

  desc "Rebuild db/mavedb.sqlite3 with only the scores table"
  task :rebuild_mavedb do
    path = Rails.root.join("db/mavedb.sqlite3")
    File.delete(path) if File.exist?(path)

    db = SQLite3::Database.new(path.to_s)
    db.execute <<~SQL
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY,
        hgvs_pro varchar,
        score real,
        score_set_urn varchar,
        source varchar
      );
    SQL
    db.close

    puts "Rebuilt #{path}"
  end

  desc "Rebuild db/clinvar.sqlite3 with only the classifications table"
  task :rebuild_clinvar do
    path = Rails.root.join("db/clinvar.sqlite3")
    File.delete(path) if File.exist?(path)

    db = SQLite3::Database.new(path.to_s)
    db.execute <<~SQL
      CREATE TABLE classifications (
        id INTEGER PRIMARY KEY,
        hgvs_pro varchar,
        variation_id varchar,
        clinical_significance varchar,
        review_status varchar,
        last_evaluated varchar
      );
    SQL
    db.close

    puts "Rebuilt #{path}"
  end
end
