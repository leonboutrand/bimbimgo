class SchoolsDistance
  attr_reader :school_1_id, :school_2_id
  attr_accessor :time_in_seconds

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

  def self.distance(schools_distances, school_1_id, school_2_id)
    # method to find out the distance between to school with their ids
    a = [school_1_id, school_2_id].sort
    schools_distances.find { |sd| (sd.school_1_id == a[0]) && (sd.school_2_id == a[1]) }.time_in_seconds
  end
end
