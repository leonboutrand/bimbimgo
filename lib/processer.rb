require 'csv'
require 'date'
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

    delivery_man_id = @orders_set * 1000
    a = dispatch_orders(@orders)
    until a[:orders_to_assign].empty?
      puts "\n\n\n"
      puts delivery_man_id
      puts a[:assigned_orders].length
      p delivery_man = DeliveryMan.new(
        id: delivery_man_id,
        starting_school_id: a[:assigned_orders].first[:order].id
      )
      @delivery_men << delivery_man
      a = dispatch_orders(a[:orders_to_assign])
      delivery_man_id += 1
    end
    puts "\n\n\n"
    puts "Processed in #{Time.now - t} seconds"
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

  # returns array where array[0] is a route for delivery guy and array[1] are missing orders
  def dispatch_orders(orders)
    puts 'starting'
    orders_to_assign = []
    orders_to_process = path_with_times(orders)
    orders.map(&:delivery_datetime).uniq.sort.each do |slot|
      puts "slot: #{slot}"
      orders_on_slot = orders_to_process.select { |order| order[:delivery_datetime] == slot }
      orders_on_slot.each_with_index do |order, i|
        # keep the order if its on time
        next if order[:delivery_datetime] + 60 * 5 >= order[:expected_time]

        # TODO: keep a condition for same school

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

  def path_with_times(orders)
    calculate_expected_times(shortest_path(orders))
  end

  # calculate the expected_times for an ordered set of orders
  def calculate_expected_times(orders)
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

  # for each set it sorts with shortest path
  def shortest_path(orders)
    grouped_orders = group_orders(orders)
    # cas ou c'est dans le meme slot
    schools_and_slots = grouped_orders.map do |group|
      puts "group length #{group.length}"
      {
        school_id: group.first.school_id,
        slot: group.first.delivery_datetime
      }
    end
    puts schools_and_slots
    # cas ou il y en a plus
    orders
    # returns ordered order list that is the more efficient
  end

  def group_orders(orders)
    orders_clone = orders.clone
    grouped_orders = []
    until orders_clone.empty?
      group = []
      orders_clone.each do |order|
        break unless (order.school_id == orders_clone.first.school_id) && (order.delivery_datetime == orders_clone.first.delivery_datetime)

        group << order
        orders_clone.delete(order)
      end
      grouped_orders << group
    end
    grouped_orders
  end

  # returns the closest school of origin_school
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
end
