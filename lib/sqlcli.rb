require "thor"
require "logger"
require "yaml"
require "sequel"
require "terminal-table"
require "pry"

Dir[File.join(File.dirname(__FILE__), 'sqlcli', '*')].each { |file| require file }

module Sqlcli
  class CLI < Thor

    @@log_file_name = Dir.home + '/.sqlcli.log'
    @@db_file_name = Dir.home + '/.sqlcli.db'

    desc 'bookmarks', 'Lists bookmarked connections'
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def bookmarks
      init_logger options[:verbose]
      init_connection_db
      begin
        ds = @@db[:connections].order(:name, :created_at).all
        rows = []
        ds.each {|r| rows << [r[:id], r[:name], r[:connection_string]]}
        table = Terminal::Table.new(
          headings: ["ID","Name", "Connection String"],
          rows: rows
        )
        $stdout.puts table
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    desc 'bookmark connection name', 'Adds a new connection and a name for use in other commands'
    method_option :force, aliases: '-f', desc: 'Replaces existing connection by the same name', default: false
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def bookmark connection, name
      init_logger options[:verbose]
      init_connection_db
      begin
        raise ValidationError, "Invalid connection string" unless connection_string_valid? connection
        info "Create connection"
        conn = Connection.new_from_conn_string connection, name, @@logger
        info "Connection valid? #{conn.valid?}"
        if connection_exists? conn
          if options[:force]
            save_connection conn, true
          else
            raise ValidationError, "Connection '#{conn.name}' already exists. Use -f to force replacement."
          end
        else
          save_connection conn
        end
        $stdout.puts 'Done'
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    desc 'do sql', 'Performs a SQL operation through the given bookmark'
    method_option :bookmark, aliases: '-b', desc: 'Bookmark', default: nil
    method_option :uri, aliases: '-u', desc: 'Connection string URI', default: nil
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def do sql
      init_logger options[:verbose]
      init_connection_db
      begin
        if options[:bookmark].nil? && !options[:uri].nil?
          conn_string = options[:uri] if connection_string_valid? options[:uri]
        else
          conn_string = @@db[:connections].where(name: options[:bookmark]).first[:connection_string]
        end

        db = Sequel.connect(conn_string)
        raise ValidationError, "Can't connect using #{conn_string}" unless db.test_connection

        if sql.downcase.include? 'select'
          ds = db[sql]
          if ds.empty?
            $stdout.puts 'No records found'
          else
            table = Terminal::Table.new(
              headings: ds.columns.map {|c| c.to_s},
              rows: ds.map {|r| r.values}
            )
            $stdout.puts table
          end
        else
          db.run sql
          $stdout.puts 'Done'
        end
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        binding.pry
        fatal "Error: #{e.message}"
      end
    end

    desc 'tables', 'Lists the tables available'
    method_option :bookmark, aliases: '-b', desc: 'Bookmark', required: true
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def tables
      init_logger options[:verbose]
      init_connection_db
      begin
        conn_string = @@db[:connections].where(name: options[:bookmark]).first[:connection_string]
        db = Sequel.connect(conn_string)
        raise ValidationError, "Can't connect using #{conn_string}" unless db.test_connection
        rows = []
        ds = db.tables
        ds.each {|t| rows << [t]}
        table = Terminal::Table.new(headings: ["Tables"], rows: rows)
        $stdout.puts table
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    private

    def connection_string_valid? conn_string
      begin
        Sequel.connect(conn_string).test_connection
      rescue => e
        error e.message
        false
      end
    end

    def init_connection_db
      begin
        info "Initializing connections database at #{File.expand_path(@@db_file_name)}"
        @@db = Sequel.sqlite(Dir.home + '/.sqlcli.db')
        @@db.create_table? :connections do
          primary_key :id
          String :name, unique: true, null: false
          String :connection_string, null: false
          DateTime :created_at
          DateTime :updated_at
          index :name
        end
      rescue => e
        error e.message
      end
    end

    def connection_exists? conn
      return false if @@db[:connections].where(name: conn.name).empty?
      return true
    end

    def save_connection conn, replace=false
      info "Saving connection #{conn}"
      begin
        raise ValidationError, "Connection is not valid" unless conn.valid?
        if connection_exists? conn
          if replace
            @@db[:connections].where(name: conn.name).update(
              connection_string: conn.connection_string,
              updated_at: DateTime.now
            )
          else
            warn "No update performed, connection '#{conn.name}' already exists"
          end
        else
          @@db[:connections].insert(
            name: conn.name,
            connection_string: conn.connection_string,
            created_at: DateTime.now
          )
        end
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        error e.message
      end
    end

    def init_logger(verbose)
      if verbose
        @@logger = Logger.new(MultiIO.new(STDOUT, File.open(@@log_file_name,'w+')))
      else
        @@logger = Logger.new(@@log_file_name)
      end
      @@logger.formatter = proc {|severity, datetime, progname, msg| "#{datetime} #{severity}: #{msg}\n"}
    end

    def info(msg); @@logger.info msg; end
    def warn(msg); @@logger.warn $stdout.puts msg; end
    def error(msg); @@logger.error msg; abort msg; end
    def fatal(msg); @@logger.fatal msg; abort msg; end

    def load_config(mailer_path)
      info "Load #{File.expand_path(mailer_path)}"
      config = YAML.load(File.open(File.expand_path(mailer_path)))
      info "Validate configuration"
      #Validator.validate_config config
      config
    end

  end
end
