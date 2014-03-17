class ContactsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Contact.count,
      iTotalDisplayRecords: contacts.total_entries,
      aaData: data
    }
  end

private

  def data
    contacts.map do |contact|
      [
        link_to(contact.name, contact ,class: "row_class spec"),
        h(contact.contact_status.status_name ),
        h(contact.phone),
        h(contact.address_oneline),
        h(contact.campaign.name),
        [link_to('Show', contact ,class: "row_class spec"), link_to("Destroy", "/contacts/destroy/#{contact.id}", :confirm => 'Are you sure?', :method => :delete), link_to('Set Active', controller: :contacts, action: :contact_active, :id=> contact.id), link_to('Sold!', controller: :contacts, action: :contact_dead, :id=> contact.id), link_to('Set Dead', controller: :contacts, action: :contact_dead, :id=> contact.id),],
      ]
    end
  end

  def contacts
    @contacts ||= fetch_contacts
  end

  def fetch_contacts
    contacts = Contact.joins(:campaign).joins(:contact_status).order("#{sort_column} #{sort_direction}")
    contacts = contacts.page(page).per_page(per_page)
    if params[:sSearch].present?
      #contacts = contacts.where("first_name  like :search or phone like :search or address_1 like :search or contact.campaign.name like :search", search: "%#{params[:sSearch]}%")
    end
    
    contacts
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[first_name  status phone address_oneline contact_campaign_name]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
