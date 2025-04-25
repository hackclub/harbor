class Avo::Resources::MembershipUpgradeRequest < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :from_status, as: :number
    field :to_status, as: :number
    field :payment_method, as: :number
    field :status, as: :number
  end
end
