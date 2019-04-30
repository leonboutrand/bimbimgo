class SchoolsDistance
  attr_reader :school_1_id, :school_2_id, :time_in_seconds

  def initialize(attributes = {})
    @school_1_id = attributes[:school_1_id].to_i
    @school_2_id = attributes[:school_2_id].to_i
    @time_in_seconds = attributes[:time_in_seconds].to_i
  end

  def school_1(schools)
    # retrieve the school 1
    schools.find { |school| school.id == @school_1_id }
  end

  def school_2(schools)
    # retrieve the school 2
    schools.find { |school| school.id == @school_2_id }
  end
end
