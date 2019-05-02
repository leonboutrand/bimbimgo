
**DATA MODIFICATIONS**

I added school.time_to_wait in schools_distance.time_in_seconds because they are always counted together.

**FILES ORGANIZATION**

All classes are defined in 'models' folder as:
  - Order(id, delivery_datetime, school_id, priority, time_to_deliver) ;
  - School(id, name, time_to_wait) ;
  - SchoolsDistance(school_1_id, school_2_id, time_in_seconds) ;
  - DeliveryMan(id, starting_school_id).

Data is stored in .csv files in 'db' folder.

'processer.rb' contains Processer class where there are all the methods to process the algorithm.

'app.rb' creates an instance of Processer with the orders data we want (1, 2, 3 or 4) as an argument, then calls Processer#process methods with returns the wanted output

*ex: Processer.new(3).process => [{order, estimated_delivery_time, delivery_man_id}]*

**MAIN ALGORITHM: Processer methods**

  #process => loop that calls assign_orders until all orders are assigned to a delivery man.

  #assign_orders(orders) => assign all orders that can be delivered by one man without lateness. Returns array of assigned orders and array of non-assigned orders.

  #shortest_path(orders) => sorts array of orders into the fastest path regarding the delivery hours. Uses #calculate_slot_path and #next_order_id methods.

  #calculate_estimated_delivery_times(orders) => returns all estimated delivery times for an array of orders. This method is used in #assign_orders so that the algorithm can check if one order can be delivered on time.
