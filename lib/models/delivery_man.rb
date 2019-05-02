class DeliveryMan
  attr_reader :id, :starting_school_id

  def initialize(attributes = {})
    @id = attributes[:id].to_i
    @starting_school_id = attributes[:starting_school_id].to_i
  end

  # retrieves the instance of School associated with delivery man
  def starting_school(schools)
    schools.find { |school| school.id == @starting_school_id }
  end
end
