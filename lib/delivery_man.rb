class DeliveryMan
  attr_reader :id, :starting_school_id

  def initialize(id, starting_school_id = nil)
    @id = id
    @starting_school_id = starting_school_id
  end

  def starting_school(schools)
    # retrieve the 'instance' of School associated with delivery man
    schools.find { |school| school.id == @starting_school_id }
  end
end
