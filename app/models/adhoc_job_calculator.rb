# encoding: utf-8
class AdhocJobCalculator
  
  def findVar(key)
    # return RockPadVariable.find_by_key(key).value
    @vars = RockPadVariable.all if @vars.nil?
    return @vars.select{|v| v.key == key}.first.value rescue 0
  end
  
  def initialize(dist=30, w=0, l=0, d=0.5)
    @vars = RockPadVariable.all
    @length = l
    @width = w
    @depth = d
    # @ec_lft = ec_lft
    @distance = dist
    @laborers = (findVar("rockpad_laborers") || 2)
    @laborer_rate = (findVar("rockpad_laborer_rate") * 100) || 2000
    @gas_cost = (findVar("rockpad_gas_cost") * 100) || 400
    @truck_cost_per_mile = (findVar("rockpad_truck_cost_per_mile") * 100) || 200
    @truck_mileage_per_gallon = findVar("rockpad_truck_mileage_per_gallon") || 9
    # @board_cost_per_foot = (findVar("rockpad_board_cost_per_foot") * 100) || 200
    # @board_cost_per_foot = (findVar("rockpad_board_cost_per_foot_gt_16") * 100) || 400 if @width >= 16
    # @board_cost_per_foot = (findVar("rockpad_board_cost_per_foot_6x6") * 100) || 500 if sixbysix
    @rock_per_ton = (findVar("rockpad_rock_per_ton") * 100) || 2000
    # @trex_price_per_foot = (findVar("rockpad_trex_price_per_foot") * 100) || 500
    # @weed_fabric_per_roll = (findVar("rockpad_weed_fabric_per_roll") * 100) || 36500
    @rebar_piece = (findVar("rockpad_rebar_piece") * 100) || 100
    # @erosion_control_per_lft = (findVar("rockpad_erosion_control_wire_price")) || 2.50
    # @kind = kind.capitalize
    # @fill_type = fill_type
  end
  
  def excavation_labor
    if square_footage > 200
      @excavation_labor = square_footage / 2 * 100
    else
      @excavation_labor = square_footage * 100
    end
    
    per_inch = @excavation_labor / 12
    @excavation_labor = per_inch * (@depth * 12)

    return @excavation_labor if @fill_type == "Excavate"
    return 0
  end
  
  
  def square_footage
    @length * @width
  end
  
  def cubic_footage
    @length * @width * @depth
  end
  
  def perimeter
    (@length + @width) * 2
  end
  

  
  def vapor_barrier_cost
    vapor_barrier_per_foot * perimeter * 2
  end
  
  def rebar_quantity
    (perimeter / findVar("rockpad_spacing_for_rebar") || 8)
  end 
  
  def rebar_cost
    @rebar_piece * rebar_quantity
  end
  
  def board_cost_pf
    @board_cost_per_foot
  end
  
  def my_depth
    @depth
  end
  
  def rock_tonage
    rock_depth = @depth / 2
    rock_depth < 0.5 ? rock_depth = 0.5 : rock_depth
    
    footage_per_ton = findVar("rockpad_square_footage_per_ton") rescue 36
    cubic_footage_per_ton = footage_per_ton * 0.5
    
    total_cubic_of_pad = @length * @width * rock_depth
    total_cubic_tonnage = total_cubic_of_pad / cubic_footage_per_ton
    
    total_tonnage = (@length * @width / footage_per_ton)
    return total_tonnage if @fill_type == "Excavate" || @depth <= 0.5
    return total_cubic_tonnage
  end
  
  def rock_cost
    rock_tonage * @rock_per_ton
  end
  
  def round_trip_distance
    @distance rescue 0
  end
  
  def driving_hours
    speed = findVar("rockpad_speed_for_hour_calculation") rescue 50
    return (round_trip_distance.to_f / speed.to_f).to_f
  end
  
  def truck_gas_cost
    (@gas_cost / @truck_mileage_per_gallon) * round_trip_distance
  end
    
  def truck_maintenance_cost
    @truck_cost_per_mile * round_trip_distance
  end
  
  def truck_cost
    truck_gas_cost + truck_maintenance_cost
  end
  
  def driving_labor_cost
    time_on_road = driving_hours.to_f
    number_of_laborers = @laborers.to_f
    laborer_rate = @laborer_rate.to_f
    driving_labor_cost = number_of_laborers * time_on_road * laborer_rate

    return driving_labor_cost
  end
  
  def working_labor_hours
    hours = case square_footage
    when 0..199
      findVar("rockpad_hours_less_than_200") || 2
    when 200..299
      findVar("rockpad_hours_200_to_300") || 2.5
    when 300..399
      findVar("rockpad_hours_300_to_400") || 3
    when 400..499
      findVar("rockpad_hours_400_to_500") || 4
    when 500..599
      findVar("rockpad_hours_500_to_600") || 5
    when 600..699
      findVar("rockpad_hours_600_to_700") || 6
    when 700.799
      findVar("rockpad_hours_700_to_800") || 7
    else
      0
    end
    hours = hours / 2 if @kind == "Economy"
    hours
  end
  
  def working_labor_cost
    working_labor_hours * @laborers * @laborer_rate
  end
  
  def total_labor_cost
    working_labor_cost + driving_labor_cost + truck_cost + excavation_labor
  end
  
  def total_material_cost
    rock_cost + rebar_cost 
  end
  
  def total_cost
    total_labor_cost + total_material_cost
  end
  
  def total_labor_price
    markup_percentage = (findVar("rockpad_labor_cost_markup")+100).to_f / 100 rescue 1.25
    total_labor_cost * markup_percentage
  end
  
  def total_material_price
    markup_percentage = (findVar("rockpad_material_cost_markup")+100).to_f / 100 || 1.15
    total_material_cost * markup_percentage
  end
  
  def total_labor_markup
    total_labor_price - total_labor_cost
  end
  
  def total_material_markup
    total_material_price - total_material_cost
  end
  
  def total_price
    puts "Total Price : #{total_labor_cost} * #{(findVar("rockpad_labor_cost_markup")+100) / 100} + #{total_material_cost} * #{(findVar("rockpad_material_cost_markup")+100) / 100}"
    (total_labor_cost * (findVar("rockpad_labor_cost_markup")+100) / 100 || 1.25) + (total_material_cost * (findVar("rockpad_material_cost_markup")+100) / 100 || 1.15)
  end
  
  def my_cost
    "$#{total_cost.to_f / 100}"
  end

  def their_price
    "$#{total_price.to_f / 100}"
  end
  
end