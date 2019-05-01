require 'csv'
require 'date'
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

orders.sort_by! { |order| [order.delivery_datetime, order.school_id] }
# p orders.map { |order| [order.delivery_datetime.strftime('%H:%M'), order.school_id] }

def main_algo(orders, schools, schools_distances)
  time = orders.first.delivery_datetime - 5 * 60
end

def shortest_path(schools)
  p schools
end

def calculate_expected_times(orders)
  time = orders.first.delivery_datetime - 5 * 60
  # pour chaque creneau
  orders.map(&:delivery_datetime).uniq.each do |slot|
    schools = orders.select { |order| order.delivery_datetime == slot }.map(&:school_id).uniq
    shortest_path = shortest_path(schools)
  end
  # return [ {order_id: x, expected_time: xx}]
end

calculate_expected_times(orders)
