class School
  attr_reader :id, :name, :time_to_wait

  def initialize(attributes = {})
    @id = attributes[:id].to_i
    @name = attributes[:name]
    @time_to_wait = attributes[:time_to_wait].to_i
  end
end
