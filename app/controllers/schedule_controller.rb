class ScheduleController < ApplicationController
  
  before_filter :authenticate_user!
  layout "application"
  
  
  def index
    @num_weeks = 4
    @query_start_date = parse_date_until(params[:until])
    @crews = Crew.find(:all, :include => [:contracts, {:contracts => [:estimate, {:estimate => :job}]}], :order => "ordering ASC")
    @contracts = Contract.where("scheduled_date > ? and scheduled_date < ?", @query_start_date, (@query_start_date + @num_weeks.weeks + 1.day)).includes(:estimate, :crew, {:estimate => [:job, {:job => :estimates, :job => :location, :job => :contact}] }).order("scheduled_date ASC")
    @queued_contracts = Contract.where(:scheduled_date => nil).includes(:estimate, :crew, {:estimate => [:job, {:job => :contact, :job => :estimates, :job => :location}] }).sort{|x,y| x.estimate.invoice_number <=> y.estimate.invoice_number}
    @daycrewblocks = DayCrewBlock.where("day > ? and day < ?", @query_start_date, @query_start_date + @num_weeks.weeks)
  end

  def fast
    # Using AngularJS and Firebase to get mah Estimates
    @crews = Crew.order("ordering ASC")

    render :layout => 'schedule'
  end
  
  def with_maps
    index
  end
  
  def get_queued_for_dropdown
    val = []
    Contract.where(:scheduled_date => nil).each do |c|
      val << [c.id, c.estimate.job.name]
    end
    render :json => val.to_json
  end
  
  def persist_assignment
    logger.debug(params.inspect)
    contract = Contract.find(params[:contract_id])
    
    if contract
      day = params[:day]
      if day.to_i.to_s != day
        scheduled_day = Time.local(*day.split('-').each{|d| d.to_i})
      else
        scheduled_day = Time.at(day.to_i)
      end
      # if Contract.find(:all, :conditions => { crew_id: params[:crew_id], position_in_day})
      if contract.update_attributes({ crew_id: params[:crew_id], arrival_range_id: params[:arrival_id], position_in_day: params[:position], scheduled_date: scheduled_day })
        render :json => { conId: contract.id, contactId: contract.estimate.job.contact_id, conName: contract.name, location: contract.location, size: "#{contract.estimate.job.size_and_type}", fill_type: (contract.estimate.job.off_level_fill_type rescue "Excavate"), arrival_time: "#{contract.arrival_range.early rescue ""} to #{contract.arrival_range.late rescue ""}" }
      else
        render :text => false
      end
    else
      render :text => false
    end
  end

  def remove_assignment
    contract = Contract.find(params[:id])
    if contract
      if contract.update_attributes({ crew_id: nil, position_in_day: nil, scheduled_date: nil })
        render :text => true
      else
        render :text => false
      end
    else
      render :text => false
    end
  end
  
  def remove_from_schedule_entirely
    contract = Contract.find(params[:id])
    if contract
      estimate = contract.estimate
      estimate.update_attribute(:sold, 0)
      estimate.job.update_attribute "current_scheduled_at", nil
      contract.destroy
      render :text => true
    else
      render :text => false
    end
  end

  def mark_as_done
    contract = Contract.find(params[:id])
    if contract && contract.update_attributes({marked_as_done_at: Time.now, marked_as_done_by: current_user.id})
      render :text => true
    else
      render :text => false
    end
  end
  
  def redirect_to_contact
    contract = Contract.find(params[:id])
    if contract && contract.estimate.job.contact
      redirect_to "/estimates/view_estimate/#{contract.estimate.token}?type=#{contract.estimate.job.job_type.kind}"
    else
      redirect_to "/schedule", error: "The contact was not found"
    end
  end

  def printable
    @query_future_date = parse_date_until(params[:until]) || (Time.current.beginning_of_day + 4.weeks)
    @quarries = Quarry.all
    @crews = if params[:crew].nil?
      Crew.find(:all, :include => [:contracts, {:contracts => :estimate}], :order => "ordering ASC")
    else
      Crew.find(:all, :conditions => ["id = ?", params[:crew]], :include => [:contracts, {:contracts => :estimate}], :order => "ordering ASC")
    end
    @contracts = Contract.where("scheduled_date > ?", (Time.current - 1.day)).includes(:estimate, {:estimate => :job}).order("scheduled_date ASC")
  end
  
  def consolidated_printable
    @quarries = Quarry.all
    @query_future_date = parse_date_until(params[:until],(Time.current.to_date + 2.weeks))
    @crews = Crew.find(:all, :conditions => ["id = ?", current_user.crew_id], :include => [:contracts, {:contracts => :estimate}], :order => "ordering ASC")
    @contracts = Contract.where("scheduled_date > ?", (Time.current.to_date - 1.day)).includes(:estimate, {:estimate => :job}).order("scheduled_date ASC")
  end



  def parse_date_until(string_date, default_date = Time.current.to_date)
    return (default_date) if string_date.nil?
    qty = string_date.split(".").first.to_i
    span = string_date.split(".").last
    days = case span
    when "d"
      1
    when "w"
      if qty < 1
        @num_weeks = qty * -1
      end
      7
    when "m"
      30
    end
    # You CANNOT subtract 8 hours from here without further parsing.  This leads to an eternal loopback on Time#succ 
    return Date.strptime((Time.current).strftime("%m/%d/%Y"), "%m/%d/%Y") + (days*qty).days
  end
  
  def get_contract_details
    @contract = Contract.find(params[:id])
    if @contract
      @estimate = @contract.estimate
      @options_for_job = YAML::load(@estimate.flashvars).with_indifferent_access
      render :json => { 
        :job_address => "<strong>Address:</strong> " + @options_for_job[:contact_address] + " " + @options_for_job[:contact_address2],
        :phone_number => "<strong>Phone:</strong> " + (@estimate.job.contact.phone || "") + " <strong>Alt:</strong> " + (@estimate.job.contact.phone_alt || ""),
        :email => @options_for_job[:contact_email] || "No email",
        :sixbysix => @estimate.job.border_sixbysix,
        :foundation => "<strong>Foundation:</strong> #{@options_for_job[:job_width]}' x #{@options_for_job[:job_length]}' - #{@estimate.job.job_quick_title rescue ''}", 
        :erosion_control => "#{@estimate.job.erosion_control_lft rescue 0} lft of <strong>Erosion Control Wire</strong>", 
        :offlevel => "#{(@estimate.job.off_level_amount_in_inches rescue 0) || 0} inches <strong>off level</strong>",
        :trex_color => "#{@estimate.job.trex_color || "no"}<strong> Trex</strong>", 
        shed_company: "<strong>Referrer: </strong>#{@estimate.job.contact.campaign.name rescue ""}",
        additional_notes: "#{@estimate.additional_notes}",
        estimate_token: "#{@estimate.token}",
        rig_id: "#{@contract.rig_id}"
      }
    else
      render :text => "no"
    end
  end
end
