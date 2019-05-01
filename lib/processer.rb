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
    # iterate through each time slot
    # orders.map(&:delivery_datetime).uniq.each do |slot|
    puts calculate_expected_times
    puts "Processed in #{Time.now - t} seconds"
  end

  private

  # load csv data into instance variables
  def import_data_from_csv
    csv_options = { headers: :first_row, header_converters: :symbol }
    CSV.foreach(File.join(__dir__, 'db/schools.csv'), csv_options) { |row| @schools << School.new(row) }
    CSV.foreach(File.join(__dir__, 'db/schools_distances.csv'), csv_options) { |row| @schools_distances << SchoolsDistance.new(row) }
    CSV.foreach(File.join(__dir__, "db/#{@orders_set}.csv"), csv_options) { |row| @orders << Order.new(row) }
    transform_schools_distance_data
    @orders.sort_by! { |order| [order.delivery_datetime, order.school_id, order.priority] }
  end

  # DATA MODIFICATION: directly add waiting time to travelling time
  def transform_schools_distance_data
    @schools_distances.each do |sd|
      sd.time_in_seconds += sd.school_2(@schools).time_to_wait
    end
  end

  # calculate the expected_times for an ordered set of orders
  def calculate_expected_times(orders = @orders)
    # time is the datetime for first delivery
    time = orders.first.delivery_datetime - 5 * 60 + orders.first.time_to_deliver

    # initialize result array with the first order
    result = [{ order: orders.first, expected_time: time, delivery_datetime: orders.first.delivery_datetime }]

    # iterate through all the orders and returns the expected_time for each
    orders[1, orders.length - 1].each_with_index do |order, i|
      # time is incremented by time_to_deliver plus travelling and waiting times if we change school
      time += order.time_to_deliver + (order.school_id == orders[i - 1].school_id ? 0 : SchoolsDistance.distance(@schools_distances, order.school_id, orders[i - 1].school_id))

      # delivery guy will wait a bit if it's too early for next order
      time = [time, order.delivery_datetime - 5 * 60].max
      result << { order: order, expected_time: time, delivery_datetime: order.delivery_datetime }
    end
    result
  end

  # returns the closest school of origin_school
  def next_school_id(schools_id, origin_school_id)
    return origin_school_id if schools_id.include?(origin_school_id)

    distances = schools_id.map do |school_id|
      {
        distance: SchoolsDistance.distance(@schools_distances, school_id, origin_school_id),
        next_school_id: school_id
      }
    end
    distances.min_by { |distance| distance[:distance] }[:next_school_id]
  end


    #   schools = orders.select { |order| order.delivery_datetime == slot }.map(&:school_id).uniq
    #   shortest_path = shortest_path(schools)
    # end
    # return [ {order_id: x, expected_time: xx}]

  # calculate_expected_times(orders)
  # p schools_id = orders.map(&:school_id).uniq.sort
  # sd1 = schools_distances.select { |dist| schools_id.include?(dist.school_1_id) && schools_id.include?(dist.school_2_id) }.sort_by!(&:time_in_seconds)
  # sd1.each { |sd| puts "#{sd.school_1_id} - #{sd.school_2_id} : #{sd.time_in_seconds}" }
end
