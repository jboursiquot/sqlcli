require "sequel"

class Connection

  attr_accessor :name, :host, :port, :username, :password, :schema, :adapter, :encoding, :created_at, :updated_at
  attr_reader :connection_string

  def self.new_from_conn_string conn_string, name, logger=Logger.new($stdout)
    begin
      hash = conn_string_to_hash conn_string
      hash[:name] = name
      hash[:logger] = logger
      Connection.new hash
    rescue => e
      logger.error e.msg
      binding.pry
      raise
    end
  end

  def initialize options = {}
    @name = options[:name]
    @host = options[:host]
    @port = options[:port].to_i
    @username = options[:username]
    @password = options[:password]
    @schema = options[:schema]
    @adapter = options[:adapter]
    @encoding = options.fetch :encoding, 'utf8'
    @logger = options.fetch :logger, Logger.new($stdout)
    @connection_string = options.fetch :connection_string, to_connection_string(options)

    @db = Sequel.connect(host:@host,
                         port:@port,
                         database:@schema,
                         username:@username,
                         password:@password,
                         adapter:@adapter,
                         encoding:@encoding)
  end

  def valid?
   @db.test_connection
  end

  def to_s
    "<Connection name='#{@name}', host='#{@host}', port=#{@port}, username='#{@username}', password='******', database='#{@schema}', adapter='#{@adapter}', encoding='#{@encoding}'>"
  end

  private

  def to_connection_string hash
    "#{hash[:adapter]}://#{hash[:username]}:#{hash[:password]}@#{hash[:host]}:#{hash[:port]}/#{hash[:schema]}"
  end

  def self.conn_string_to_hash conn_string
    begin
      hash = {}
      hash[:adapter] = conn_string.split(/:/).first
      hash[:username] = conn_string.split(/\/\//).last.split(/:/).first
      hash[:password] = conn_string.split(/\/\//).last.split(/:/)[1].split(/@/).first
      hash[:host] = conn_string.split(/\/\//).last.split(/@/).last.split(/:/).first
      hash[:port] = conn_string.split(/\/\//).last.split(/@/).last.split(/:/).last.split(/\//).first.to_i
      hash[:schema] = conn_string.split(/\/\//).last.split(/@/).last.split(/:/).last.split(/\//).last
      hash[:connection_string] = conn_string
      hash
    rescue => e
      raise
    end
  end

end
