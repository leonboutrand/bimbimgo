require 'time'
# require_relative 'school'

class Order
  attr_reader :id, :delivery_datetime, :school_id, :priority, :time_to_deliver

  def initialize(attributes = {})
    @id = attributes[:id].to_i
    @delivery_datetime = Time.parse(attributes[:delivery_datetime])
    @school_id = attributes[:school_id].to_i
    @priority = attributes[:priority].to_i
    @time_to_deliver = attributes[:time_to_deliver].to_i
  end

  def school(schools)
    # retrieve the 'instance' of School associated with order
    schools.find { |school| school.id == @id }
  end
end
