namespace :dbdiag do
  WATCH_FILES = [
    Rails.root.join("db/development.sqlite3"),
    Rails.root.join("db/uniprot.sqlite3"),
    Rails.root.join("db/pdb.sqlite3")
  ].freeze

  EXPECTED_MAIN_MODELS = [ "Protein", "Variant", "ProteinFeature", "StructureEntry" ].freeze

  def dbdiag_models
    {
      "Protein" => Protein,
      "Variant" => Variant,
      "ProteinFeature" => ProteinFeature,
      "StructureEntry" => StructureEntry,
      "Uniprot::Entry" => Uniprot::Entry,
      "Pdb::Structure" => Pdb::Structure
    }
  end

  def dbdiag_stat(pathname)
    return nil unless File.exist?(pathname)

    stat = File.stat(pathname)
    {
      path: pathname.expand_path.to_s,
      size: stat.size,
      mtime: stat.mtime
    }
  end

  def dbdiag_report_file(pathname)
    stat = dbdiag_stat(pathname)
    if stat
      puts "- #{pathname}:"
      puts "  absolute_path: #{stat[:path]}"
      puts "  size: #{stat[:size]}"
      puts "  mtime: #{stat[:mtime]}"
    else
      puts "- #{pathname}: missing"
    end
  end

  def dbdiag_print_main_state(label, stat)
    puts "#{label}:"
    if stat
      puts "- path: #{stat[:path]}"
      puts "- size: #{stat[:size]}"
      puts "- mtime: #{stat[:mtime]}"
    else
      puts "- db/development.sqlite3 is missing"
    end
  end

  def dbdiag_run_and_watch(command)
    main_db = Rails.root.join("db/development.sqlite3")
    before = dbdiag_stat(main_db)
    dbdiag_print_main_state("Before", before)

    puts "Running command: #{command}"
    success = system(command)
    status = $?

    after = dbdiag_stat(main_db)
    dbdiag_print_main_state("After", after)

    changed = before != after
    puts "Command success: #{success}"
    puts "Exit status: #{status&.exitstatus}"
    puts "Main DB changed: #{changed}"
    changed
  end

  task inspect: :environment do
    puts "Model database paths:"
    model_db_paths = {}
    models = dbdiag_models

    models.each do |name, klass|
      db_path = klass.connection_db_config.database
      model_db_paths[name] = db_path
      puts "- #{name}: #{db_path}"
    end

    puts
    puts "Tables by distinct connection:"
    by_db = models.group_by { |_name, klass| klass.connection_db_config.database }
    by_db.each do |db_path, entries|
      names = entries.map(&:first).sort
      tables = entries.first.last.connection.tables.sort
      puts "- #{db_path}"
      puts "  models: #{names.join(', ')}"
      puts "  tables: #{tables.join(', ')}"
    end

    puts
    puts "SQLite file metadata:"
    WATCH_FILES.each { |pathname| dbdiag_report_file(pathname) }

    puts
    puts "Database sharing check:"
    shared = model_db_paths.group_by { |_name, path| path }.transform_values { |pairs| pairs.map(&:first).sort }
    expected_main_models_sorted = EXPECTED_MAIN_MODELS.sort
    unexpected = shared.select do |_path, model_names|
      next false if model_names.sort == expected_main_models_sorted
      model_names.size > 1
    end

    if unexpected.empty?
      puts "- no unexpected shared database files detected"
    else
      unexpected.each do |path, model_names|
        puts "- unexpected sharing on #{path}: #{model_names.join(', ')}"
      end
    end
  end

  task touch_watch: :environment do
    main_db = Rails.root.join("db/development.sqlite3")
    initial = dbdiag_stat(main_db)

    puts "Initial main DB state:"
    if initial
      puts "- path: #{initial[:path]}"
      puts "- size: #{initial[:size]}"
      puts "- mtime: #{initial[:mtime]}"
    else
      puts "- db/development.sqlite3 is missing"
    end

    diagnostic = lambda do
      Protein.connection.tables
      Uniprot::Entry.connection.tables
      Pdb::Structure.connection.tables
    end
    diagnostic.call

    final = dbdiag_stat(main_db)
    puts "Final main DB state:"
    if final
      puts "- path: #{final[:path]}"
      puts "- size: #{final[:size]}"
      puts "- mtime: #{final[:mtime]}"
    else
      puts "- db/development.sqlite3 is missing"
    end

    changed = initial != final
    puts "Main DB changed during touch_watch: #{changed}"
  end

  task watch_command: :environment do
    command = ENV["CMD"].to_s.strip
    if command.empty?
      puts "Usage: CMD=\"<command>\" bin/rake dbdiag:watch_command"
      next
    end

    dbdiag_run_and_watch(command)
  end

  task watch_tasks: :environment do
    commands = [
      "bin/rails db:migrate:status",
      "bundle exec rspec spec/models/pdb/structure_spec.rb",
      "bundle exec rspec spec/models/uniprot/entry_spec.rb"
    ]

    puts "dbdiag:watch_tasks"
    puts
    commands.each do |command|
      puts "---"
      changed = dbdiag_run_and_watch(command)
      puts "Summary: #{command} => main DB changed: #{changed}"
      puts
    end
  end

  task watch_full_suite: :environment do
    puts "dbdiag:watch_full_suite"
    puts
    changed = dbdiag_run_and_watch("bundle exec rspec")
    puts
    puts "Full suite changed main DB: #{changed}"
  end

  task watch_sequence: :environment do
    commands = [
      "bin/rails db:migrate",
      "bin/rails db:migrate:status",
      "bundle exec rspec",
      "bundle exec rspec spec/models/database_selection_spec.rb",
      "bundle exec rspec spec/models/pdb/structure_spec.rb",
      "bundle exec rspec spec/models/uniprot/entry_spec.rb"
    ]

    puts "dbdiag:watch_sequence"
    puts
    commands.each do |command|
      puts "---"
      changed = dbdiag_run_and_watch(command)
      puts "Summary: #{command} => main DB changed: #{changed}"
      if changed
        puts
        puts "First detected writer: #{command}"
        break
      end
      puts
    end
  end
end
