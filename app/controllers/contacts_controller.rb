class ContactsController < ApplicationController
  before_filter :authenticate_user!

  # Updated On 14-03-13
  def index
    @page_title = "All Contacts"
    @contacts = Contact.find(:all, :order => "last_name ASC")
    respond_to do |format|
      format.html
      format.json { render json: ContactsDatatable.new(view_context) }
    end
  end
  
  def show
    @contact = Contact.find(params[:id])
    session[:look] = 'show'
    session[:return_to] = nil
    
  end
  
  def status
    @contact = Contact.find(params[:id])
    if params[:contract_id_rem]
      logger.debug "REMOVED FROM SCHEDULE"
      @contract = Contract.find(params[:contract_id_rem])
      @contract.estimate.update_attribute(:sold, 0)
      @contract.estimate.job.update_attribute "current_scheduled_at", nil
      @contract.destroy
    end
    session[:look] = 'show'
  end
  
  def new
    @contact = Contact.new
  end
  
  def create
    @contact = Contact.new(params[:contact])
    @contact.created_by = current_user.id
    if @contact.save
      flash[:notice] = "Successfully created contact."
      redirect_to "/contacts/#{@contact.id}" and return
    else
      render :action => 'new'
    end
  end
  
  def edit
    @contact = Contact.find(params[:id])
  end
  
  def update
    @contact = Contact.find(params[:id])
    if @contact.update_attributes(params[:contact])
      flash[:notice] = "Successfully updated contact."
      return if has_session_return_to?
      redirect_to @contact if session[:look] == 'show'
      redirect_to contacts_url if session[:look] == 'index'
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy
    flash[:notice] = "Successfully destroyed contact."
    redirect_to contacts_url
  end
  
  def active_contacts
    @page_title = "Active Contacts"
    @contacts = Contact.where(:contact_status_id => [1,2]).includes(:contact_status, :campaign, :jobs, :statuses).order("created_at DESC")
    render :template => 'contacts/index'
  end
  
  def dead_contacts
    @page_title = "Dead Contacts"
    @contacts = Contact.where(:contact_status_id => 3).includes(:contact_status, :campaign, :jobs, :statuses).order("created_at DESC")
    render :template => 'contacts/index'
  end
  
  def contact_active
    @contact = Contact.find(params[:id])
    @contact.contact_status_id = ContactStatus.find_by_status_name("Active").id
    if @contact.save
      logger.debug("mission accomplished")
      flash[:notice] = "Contact is now Active"
    else 
      logger.debug("mission failed.")
      flash[:notice] = "Contact was not successfully updated."
    end
    redirect_to :back
  end
  
  def contact_dead
    @contact = Contact.find(params[:id])
    @contact.contact_status_id = ContactStatus.find_by_status_name("Dead").id
    if @contact.save
      logger.debug("swimmin with the fishies")
      flash[:notice] = "Contact is now Dead"
    else 
      logger.debug("safe... for now")
      flash[:notice] = "Contact was not successfully updated."
    end
    redirect_to :back
  end
end
