class Avo::Resources::ExternalDuration < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :start_time, as: :date_time
    field :end_time, as: :date_time
    field :ip_address, as: :text
  end
end
