class SchoolsDistance
  attr_reader :school_1_id, :school_2_id
  attr_accessor :time_in_seconds

  def initialize(attributes = {})
    @school_1_id = attributes[:school_1_id].to_i
    @school_2_id = attributes[:school_2_id].to_i
    @time_in_seconds = attributes[:time_in_seconds].to_i
  end

  # retrieve the school 1
  def school_1(schools)
    schools.find { |school| school.id == @school_1_id }
  end

  # retrieve the school 2
  def school_2(schools)
    schools.find { |school| school.id == @school_2_id }
  end

  # method to find out the distance between to school with their ids
  def self.distance(schools_distances, school_1_id, school_2_id)
    a = [school_1_id, school_2_id].sort
    schools_distances.find { |sd| (sd.school_1_id == a[0]) && (sd.school_2_id == a[1]) }.time_in_seconds
  end
end
