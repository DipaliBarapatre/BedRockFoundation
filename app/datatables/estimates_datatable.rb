class EstimatesDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Job.count,
      iTotalDisplayRecords: estimates.total_entries,
      aaData: data
    }
  end

private

  def data
    estimates.map do |estimate|
      compaign_name = estimate.contact.campaign_id.nil? ? "" : Campaign.find_by_id(estimate.contact.campaign_id).name
      [
        link_to(estimate.contact.name,"/contacts/#{estimate.contact_id}", class: "button blue-gradient"),
        h(estimate.id),
        h(estimate.updated_at.strftime("%Y-%m-%d")),
        h(estimate.current_scheduled_at ? estimate.current_scheduled_at.strftime("%B %e, %Y") : ''),
        number_to_currency(estimate.price_in_cents.to_f/100),
        h(estimate.contact.contact_status.status_name ),
        h(estimate.contact.phone),
        h(estimate.contact.address_oneline),
        h(compaign_name)
      ]
    end
  end

  def estimates
    @job ||= fetch_estimates
  end

  def fetch_estimates
    estimates = Job.joins(:contact).order("#{sort_column} #{sort_direction}")
    estimates = estimates.page(page).per_page(per_page)
    if params[:sSearch].present?
      estimates = estimates.where("contacts.first_name like :search or contacts.last_name like :search or jobs.price_in_cents like :search or jobs.id like :search", search: "%#{params[:sSearch]}%")
    end
    estimates
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[contact_id id updated_at current_scheduled_at price_in_cents]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end