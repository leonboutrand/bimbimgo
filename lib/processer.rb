require 'csv'
require 'date'
require_relative 'models/school'
require_relative 'models/schools_distance'
require_relative 'models/order'
require_relative 'models/delivery_man'

class Processer
  def initialize(orders_set = 'orders_1')
    @orders_set = orders_set
    @schools, @schools_distances, @orders, @delivery_men = [], [], [], []
    import_data_from_csv
  end

  def process
    puts 'Processing...'
    t = Time.now
    puts calculate_expected_times
    puts "Processed in #{Time.now - t} seconds"
  end

  private

  def import_data_from_csv
    csv_options = { headers: :first_row, header_converters: :symbol }
    CSV.foreach(File.join(__dir__, 'db/schools.csv'), csv_options) { |row| @schools << School.new(row) }
    CSV.foreach(File.join(__dir__, 'db/schools_distances.csv'), csv_options) { |row| @schools_distances << SchoolsDistance.new(row) }
    CSV.foreach(File.join(__dir__, "db/#{@orders_set}.csv"), csv_options) { |row| @orders << Order.new(row) }
    @orders.sort_by! { |order| [order.delivery_datetime, order.school_id, order.priority] }
  end

  def calculate_expected_times(orders = @orders)
    # time is the datetime for first delivery
    time = orders.first.delivery_datetime - 5 * 60 + orders.first.time_to_deliver
    result = [{ order: orders.first.id, expected_time: time }]
    orders[1, orders.length - 1].each_with_index do |order, i|
      time += order.time_to_deliver + (order.school_id == orders[i - 1].school_id ? 0 : SchoolsDistance.distance(@schools_distances, order.school_id, orders[i - 1].school_id) + order.school(@schools).time_to_wait)
      result << { order: order.id, expected_time: time }
    end
    result
  end
    # iterate through each time slot
    # orders.map(&:delivery_datetime).uniq.each do |slot|

    #   schools = orders.select { |order| order.delivery_datetime == slot }.map(&:school_id).uniq
    #   shortest_path = shortest_path(schools)
    # end
    # return [ {order_id: x, expected_time: xx}]

  # calculate_expected_times(orders)
  # p schools_id = orders.map(&:school_id).uniq.sort
  # sd1 = schools_distances.select { |dist| schools_id.include?(dist.school_1_id) && schools_id.include?(dist.school_2_id) }.sort_by!(&:time_in_seconds)
  # sd1.each { |sd| puts "#{sd.school_1_id} - #{sd.school_2_id} : #{sd.time_in_seconds}" }
end

MainTester.new.process
