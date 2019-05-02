class DeliveryMan
  attr_reader :id, :starting_school_id

  def initialize(attributes = {})
    @id = attributes[:id].to_i
    @starting_school_id = attributes[:starting_school_id].to_i
  end

  def starting_school(schools)
    # retrieve the 'instance' of School associated with delivery man
    schools.find { |school| school.id == @starting_school_id }
  end
end
