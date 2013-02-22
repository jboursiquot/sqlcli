class Recipient
  attr_reader :name, :email

  def initialize(name, email)
    @name = name
    @email = email
  end

  def to_email
    return "#{@name} <#{@email}>" if @name
    @email
  end

  def to_s
    "<Recipient #{name} | #{email}>"
  end

end
