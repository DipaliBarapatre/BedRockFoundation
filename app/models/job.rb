# encoding: utf-8
class Job < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  belongs_to :job_type
  belongs_to :truck
  belongs_to :contact
  belongs_to :foundation
  belongs_to :pad_size
  belongs_to :location
  belongs_to :foundation_calculator
  has_many :statuses, :dependent => :destroy
  has_many :estimates
  has_many :job_additions
  
  after_create :create_initial_status
  before_create :geocode_address
  before_save :geocode_address
  before_save :calculate_pad_costs
  
  scope :by_recent, :order => "updated_at DESC"
  
  def name
    return id if contact.nil?
    return "#{contact.name} - ##{self.location.abbreviation rescue ""}-#{self.estimates.select{|e| e.sold?}.first.invoice_number }" if !self.estimates.select{|e| e.sold? }.empty?
    return "#{contact.name} - ##{id}"
    return "#{id}"
  end
  
  def estimate_or_contract
    estimate? ? "Est" : "Cont"
  end
  
  def creator=(user)
    @creator = user
  end
  
  def estimate?
    current_scheduled_at.nil?
  end

  def contract?
    !current_scheduled_at.nil? && current_scheduled_at > Time.now
  end

  def completed?
    !current_scheduled_at.nil? && current_scheduled_at < Time.now
  end
  
  def referencing
    return "#{self.estimate_or_contract} - #{self.width} × #{self.length} - #{self.job_type.kind}"
  end
  
  def address_oneline
    [address_1,address_2,city,province,zip].reject{|f| f.blank? }.join(", ")
  end

  def city_state
    [city,province].reject{|f| f.blank? }.join(", ")
  end
  
  def latitude
    self.lat
  end
  
  def foundation_calc
    @foundation_calc ||= self.foundation_calculator.kind.downcase rescue ""
  end
  
  def longitude
    self.lng
  end
  
  def extras
    str = []
    str << "Accessible with machine: #{accessible_with_machine}" if !accessible_with_machine.blank? 
    str << "Additional fill dirt needed: #{additional_fill_dirt}" if !additional_fill_dirt.blank? 
    str << "Build up timbers: #{build_up_timbers}" if !build_up_timbers.blank? 
    str << "Timber wall: #{timber_wall}" if !timber_wall.blank? 
    str
  end
  
  def job_calc_type
    if foundation_kind.downcase.include?("concrete")
      @job_calc_type ||= foundation_kind.downcase.to_slug      
    else
      @job_calc_type ||= "pad"
    end
  end
  
  def pad_job
    @padjob ||= RockPadCalculator.new(self.distance, self.width, self.length, (self.job_type.kind rescue "Standard"), self.border_sixbysix, (self.off_level_amount_in_inches.to_f/12), self.off_level_fill_type, self.erosion_control_lft)
  end
  
  def adhoc_job
    @adhocjob ||= AdhocJobCalculator.new(self.distance, self.width, self.length, (self.off_level_amount_in_inches.to_f/12))
  end
  
  def pad_job_with_options
    @padjob ||= RockPadCalculator.new(self.distance, self.width, self.length, (self.job_type.kind rescue "Standard"), self.border_sixbysix, (self.off_level_amount_in_inches.to_f/12), self.off_level_fill_type, self.erosion_control_lft)
  end
  
  def pad_job_type_offset
    buildup_econ_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 0, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_econ_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 1, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_econ_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 1.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_econ_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 2, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_econ_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 2.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_econ_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 3, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 0, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 1, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 1.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 2, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 2.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_stan_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 3, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 0, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 1, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 1.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 2, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 2.5, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    buildup_elite_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 3, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 0, "Build-Up", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 1, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 1.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 2, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 2.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_econ_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Economy", self.border_sixbysix, 3, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 0, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 1, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 1.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 2, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 2.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_stan_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Standard", self.border_sixbysix, 3, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_0 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 0, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_12 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 1, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_18 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 1.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_24 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 2, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_30 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 2.5, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    excavate_elite_36 = RockPadCalculator.new(self.distance, self.width, self.length,"Elite", self.border_sixbysix, 3, "Excavate", self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    
    return {
      buildup_economy: {zero: buildup_econ_0, twelve: buildup_econ_12, eighteen: buildup_econ_18, twentyfour: buildup_econ_24, thirty: buildup_econ_30, thirtysix: buildup_econ_36},
      buildup_standard: {zero: buildup_stan_0, twelve: buildup_stan_12, eighteen: buildup_stan_18, twentyfour: buildup_stan_24, thirty: buildup_stan_30, thirtysix: buildup_stan_36},
      buildup_elite: {zero: buildup_elite_0, twelve: buildup_elite_12, eighteen: buildup_elite_18, twentyfour: buildup_elite_24, thirty: buildup_elite_30, thirtysix: buildup_elite_36},
      excavate_economy: {zero: excavate_econ_0, twelve: excavate_econ_12, eighteen: excavate_econ_18, twentyfour: excavate_econ_24, thirty: excavate_econ_30, thirtysix: excavate_econ_36},
      excavate_standard: {zero: excavate_stan_0, twelve: excavate_stan_12, eighteen: excavate_stan_18, twentyfour: excavate_stan_24, thirty: excavate_stan_30, thirtysix: excavate_stan_36},
      excavate_elite: {zero: excavate_elite_0, twelve: excavate_elite_12, eighteen: excavate_elite_18, twentyfour: excavate_elite_24, thirty: excavate_elite_30, thirtysix: excavate_elite_36}
    }
  end
  
  def specific_offlevel(kind)
    kind_0 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 0, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    kind_12 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 1, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    kind_18 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 1.5, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    kind_24 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 2, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    kind_30 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 2.5, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    kind_36 = RockPadCalculator.new(self.distance, self.width, self.length, kind.capitalize, self.border_sixbysix, 3, self.off_level_fill_type, self.erosion_control_lft).total_price + (self.additional_price * 100) - (self.discount * 100)
    return {
      zero: [kind_0, 0], twelve: [kind_12, 12], eighteen: [kind_18, 18], twentyfour: [kind_24, 24], thirty: [kind_30, 30], thirtysix: [kind_36, 36]
    }
  end
  
  def money_from_cents(cents)
    return "$0" if cents == 0 || cents.nil?
    number_to_currency (cents.to_f / 100)
  end
  
  def job_description_for_flash(kind)
    str = ""
    kind = kind.capitalize
    if kind == "Economy"
      str = ContentDatum.find_by_key("rockpad_estimate_economy").value
    elsif kind == "Standard"
      str = ContentDatum.find_by_key("rockpad_estimate_standard").value
    elsif kind == "Elite"
      str = ContentDatum.find_by_key("rockpad_estimate_elite").value
    elsif kind == "Custom"
      str = ContentDatum.find_by_key("rockpad_estimate_custom").value
    end
    return str.gsub("4\"× 6\" pressure", "6\"× 6\" pressure") if self.border_sixbysix
    return str
  end
  
  def options_for_print(kind="Standard")
    pad_job = RockPadCalculator.new(self.distance, self.width, self.length, kind, self.border_sixbysix, ((self.off_level_amount_in_inches / 12) rescue 0), self.off_level_fill_type, self.erosion_control_lft)
    logger.debug("Pad Job: #{pad_job.total_price}")
    if self.contact
      return { 
    		contact_name: "#{ self.contact.first_name rescue ""} #{ self.contact.last_name rescue "" }",
    		contact_address: "#{ self.contact.address_1 rescue "" }",
    		contact_address2: "#{ self.contact.city rescue "" }, #{ self.contact.province rescue ""}   #{self.contact.zip rescue ""}",
    		contact_phone_home: "#{ self.contact.phone rescue "" }",
    		contact_phone_cell: "#{ self.contact.phone_alt rescue "" }",
    		contact_phone_work: "#{ self.contact.phone_work rescue "" }",
    		contact_email: "#{ self.contact.email rescue "" }",
    		shed_company: "#{ self.contact.campaign.name rescue "None" }",
    		job_location_abbr: "#{ self.location.abbreviation rescue 'ERR' }",
    		job_location_phone: "#{ self.location.phone rescue '- no location assigned' }",
    		job_quality: "#{ kind rescue "" }",
    		job_quality_alt: "#{ self.description rescue "" }",
    		job_description: "#{ job_description_for_flash(kind) }",
    		job_extras: "#{ self.extras.join('\n') rescue "" }",
    		job_price: "#{money_from_cents pad_job.total_price + (self.additional_price * 100) - (self.discount * 100)}",
    		additional_price: "#{money_from_cents(self.additional_price * 100)}",
    		job_total_price: "#{money_from_cents(pad_job.total_price + (self.additional_price * 100) - (self.discount * 100))}",
    		job_width: "#{self.width}",
    		job_length: "#{self.length}",
    		job_inches: "#{self.off_level_amount_in_inches}",
    		job_kind: "#{kind}",
    		foundation_kind: "#{self.foundation.kind rescue ''} Foundation",
    		job_date: "#{ self.updated_at.strftime('%m/%d/%Y') || '' }",
    		estimate_date: "#{ self.updated_at.strftime('%m/%d/%Y') || ""}"
    	}
    else
      return {}
    end
  end
  
  def has_erosion_control_lft?
    return true if self.erosion_control_lft != nil && self.erosion_control_lft != 0
    return false
  end
  
  def foundation_kind
    return self.foundation_calculator.kind rescue ""
  end
  
  protected
  
    def create_initial_status
      statuses.create({:notes => "Created new Estimate", :assigned_by => @creator.id, :assigned_to => @creator.id, :done => true})
    end
    def geocode_address
      if !self.address_1.blank?
        geo = Geokit::Geocoders::MultiGeocoder.geocode (address_oneline)
        base = Geokit::Geocoders::MultiGeocoder.geocode "461 Old Wilmington Rd, Coatesville, PA"
        errors.add(:address_1, "Could not Geocode address") if !geo.success
        if geo.success
          self.lat, self.lng = geo.lat,geo.lng 
          self.distance = geo.distance_from(base, :units=>:miles)
        end
      else
        # reuse the contact's current geodata
        cont = Contact.find(self.contact_id)
        self.lat, self.lng, self.distance = cont.lat, cont.lng, cont.distance
        self.address_1, self.address_2, self.city, self.province, self.zip = cont.address_1, cont.address_2, cont.city, cont.province, cont.zip
      end
    end
    def calculate_pad_costs
      if self.foundation_kind.include?("concrete")
        
      elsif self.foundation_kind.include?("adhoc")
        self.calculate_adhoc_job_costs
      else
        self.calculate_rock_pad_costs
      end
      
      self.job_additions.each do |ja|
        self.price_in_cents = self.price_in_cents + ja.addition_price_in_cents
      end
    end
    
    def calculate_rock_pad_costs
      self.discount = 0.00 if self.discount == nil
      self.price_in_cents = self.pad_job.total_price + (self.additional_price * 100) - (self.discount * 100)
      self.labor_cost_in_cents = self.pad_job.total_labor_cost
      self.material_cost_in_cents = self.pad_job.total_material_cost
    end

    def calculate_adhoc_job_costs
      self.discount = 0.00 if self.discount == nil
      self.price_in_cents = self.adhoc_job.total_price + (self.additional_price * 100) - (self.discount * 100)
      self.labor_cost_in_cents = self.adhoc_job.total_labor_cost
      self.material_cost_in_cents = self.adhoc_job.total_material_cost
    end
    
end
