require 'csv'
require_relative 'school'
require_relative 'schools_distance'
require_relative 'order'
require_relative 'delivery_man'

def import_data_from_csv(schools, schools_distances, orders)
  csv_options = { headers: :first_row, header_converters: :symbol }
  CSV.foreach(File.join(__dir__, 'db/schools.csv'), csv_options) { |row| schools << School.new(row) }
  CSV.foreach(File.join(__dir__, 'db/schools_distances.csv'), csv_options) { |row| schools_distances << SchoolsDistance.new(row) }
  CSV.foreach(File.join(__dir__, 'db/orders_1.csv'), csv_options) { |row| orders << Order.new(row) }
end

schools, schools_distances, orders, delivery_men = [], [], [], []
import_data_from_csv(schools, schools_distances, orders)
