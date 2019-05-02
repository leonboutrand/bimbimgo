require 'csv'
require 'date'
require 'awesome_print'
require_relative 'models/school'
require_relative 'models/schools_distance'
require_relative 'models/order'
require_relative 'models/delivery_man'

class Processer
  def initialize(orders_set = 1)
    @orders_set = orders_set
    @schools, @schools_distances, @orders, @delivery_men = [], [], [], []
    import_data_from_csv
  end

  def process
    puts 'Processing...'
    t = Time.now

    result = []
    delivery_man_id = @orders_set * 1000 + 1
    a = dispatch_orders(@orders)
    loop do
      @delivery_men << DeliveryMan.new(
        id: delivery_man_id,
        starting_school_id: a[:assigned_orders].first[:order].id
      )
      result += a[:assigned_orders].map do |record|
        record[:order] = record[:order].id
        record[:delivery_man_id] = delivery_man_id
        record
      end
      break if a[:orders_to_assign].empty?

      a = dispatch_orders(a[:orders_to_assign])
      delivery_man_id += 1
    end

    puts "\n\n\n"
    puts "Processed in #{Time.now - t} seconds"
    result
  end

  private

  # load csv data into instance variables
  def import_data_from_csv
    csv_options = { headers: :first_row, header_converters: :symbol }
    CSV.foreach(File.join(__dir__, 'db/schools.csv'), csv_options) { |row| @schools << School.new(row) }
    CSV.foreach(File.join(__dir__, 'db/schools_distances.csv'), csv_options) { |row| @schools_distances << SchoolsDistance.new(row) }
    CSV.foreach(File.join(__dir__, "db/orders_#{@orders_set}.csv"), csv_options) { |row| @orders << Order.new(row) }
    transform_schools_distance_data
    @orders.sort_by! { |order| [order.delivery_datetime, order.school_id, order.priority] }
  end

  # DATA MODIFICATION: directly add waiting time to travelling time
  def transform_schools_distance_data
    @schools_distances.each do |sd|
      sd.time_in_seconds += sd.school_2(@schools).time_to_wait
    end
  end

  # returns hash {array of orders for one delivery guy, array of missing orders}
  def dispatch_orders(orders)
    orders_to_assign = []
    orders_to_process = path_with_times(orders)
    orders.map(&:delivery_datetime).uniq.sort.each do |slot|
      orders_on_slot = orders_to_process.select { |order| order[:order].delivery_datetime == slot }
      orders_on_slot.each_with_index do |order, i|
        # keep the order if its on time
        next if order[:order].delivery_datetime + 60 * 5 >= order[:expected_time]

        # if it's too late to deliver other orders of the slot
        orders_on_slot[i, orders_on_slot.length - i].each do |order_to_assign|
          # store them into orders_to_assign
          orders_to_assign << order_to_assign

          # delete them from orders_to_process
          orders_to_process.delete(order_to_assign)
        end
        orders_to_process = path_with_times(orders_to_process.map { |record| record[:order] })
        break
      end
    end
    {
      assigned_orders: orders_to_process,
      orders_to_assign: orders_to_assign.map { |record| record[:order] }
    }
  end

  # coordinates shorted_path and calculate_expected_times
  # returns [{ order, expected_time }]
  def path_with_times(orders)
    calculate_expected_times(shortest_path(orders))
  end

  # calculates the expected_times for an sorted array of orders
  # returns [{ order, expected_time }]
  def calculate_expected_times(orders)
    # time is initialized with datetime for first delivery
    time = orders.first.delivery_datetime - 300 + orders.first.time_to_deliver

    # initializes result array with the first order
    result = [{ order: orders.first, expected_time: time }]

    # iterate through all the orders
    orders[1, orders.length - 1].each_with_index do |order, i|
      # time is incremented by time_to_deliver plus travelling and waiting times if we change school
      time += order.time_to_deliver + (order.school_id == orders[i - 1].school_id ? 0 : SchoolsDistance.distance(@schools_distances, order.school_id, orders[i - 1].school_id))

      # delivery guy will wait a bit if it's too early for next order
      time = [time, order.delivery_datetime - 5 * 60].max

      # records the expected_time for each order
      result << { order: order, expected_time: time }
    end
    result
  end

  # sorts array of orders to get the shortest path => sorted array of orders
  def shortest_path(orders)
    grouped_orders = group_orders(orders)
    ordered_orders = []
    next_school_id = orders.first.school_id
    # [  [ [order1, order2], [orders from other school] ], [ other slot ]  ]
    grouped_orders.each do |slot_group|
      schools_id = slot_group.map { |school_group| school_group.first.school_id }
      slot_path = calculate_slot_path(next_school_id, schools_id)
      next_school_id = slot_path.last
      slot_path.each do |school_id|
        ordered_orders += slot_group.find { |group| group.first.school_id == school_id }
      end
    end
    ordered_orders
  end

  # groups orders array by slot then by school => [[same slot[same school]]]
  def group_orders(orders)
    grouped_orders = orders.group_by(&:delivery_datetime)
    grouped_orders.values.map { |group| group.group_by(&:school_id).values }
  end

  # returns closest school_id of origin_school
  def next_school_id(origin_school_id, schools_id)
    return origin_school_id if schools_id.include?(origin_school_id)

    distances = schools_id.map do |school_id|
      {
        distance: SchoolsDistance.distance(@schools_distances, school_id, origin_school_id),
        next_school_id: school_id
      }
    end
    distances.min_by { |distance| distance[:distance] }[:next_school_id]
  end

  # sorts array of schools_id to get shortest path depending on origin school
  def calculate_slot_path(origin_school_id, schools_id)
    path = []
    schools_id.length.times do
      school_id = next_school_id(origin_school_id, schools_id)
      path << school_id
      schools_id.delete(school_id)
    end
    path
  end
end
