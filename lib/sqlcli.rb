require "thor"
require "logger"
require "yaml"
require "sequel"
require "pry"

Dir[File.join(File.dirname(__FILE__), 'sqlcli', '*')].each { |file| require file }

module Sqlcli
  class CLI < Thor

    @@log_file_name = Dir.home + '/.sqlcli.log'

    desc 'list', 'Lists pre-configured connections'
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def list
      init_logger options[:verbose]
      begin
        #raise ValidationError, "File not found: #{mailer_path}" unless File.exists?(File.expand_path(mailer_path))
        #load_config mailer_path
        $stdout.puts 'Nothing'
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    desc 'add connection name', 'Adds a new connection and a name for use in other commands'
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def add connection, name
      init_logger options[:verbose]
      begin
        info 'Creating and validating connection'
        conn = Connection.new connection, name
        #raise ValidationError, "File not found: #{mailer_path}" unless File.exists?(File.expand_path(mailer_path))
        #load_config mailer_path
        $stdout.puts 'Ok'
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    desc 'validate connection', 'Validates connection string'
    method_option :verbose, aliases: '-v', desc: 'Verbose', default: false
    def validate(conn_string)
      init_logger options[:verbose]
      begin
        #raise ValidationError, "File not found: #{mailer_path}" unless File.exists?(File.expand_path(mailer_path))
        #load_config mailer_path
        $stdout.puts 'Ok'
        exit
      rescue ValidationError => e
        error "Validation Error: #{e.message}"
      rescue => e
        fatal "Error: #{e.message}"
      end
    end

    private

    def init_logger(verbose)
      if verbose
        @@logger = Logger.new(MultiIO.new(STDOUT, File.open(@@log_file_name,'w+')))
      else
        @@logger = Logger.new(@@log_file_name)
      end
      @@logger.formatter = proc {|severity, datetime, progname, msg| "#{datetime} #{severity}: #{msg}\n"}
    end

    def info(msg); @@logger.info msg; end
    def error(msg); @@logger.error msg; abort msg; end
    def fatal(msg); @@logger.fatal msg; abort msg; end

  end
end
