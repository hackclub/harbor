class MembershipUpgradeRequest < ApplicationRecord
  belongs_to :user

  enum :from_status, User.membership_types, prefix: true
  enum :to_status, User.membership_types, prefix: true

  enum :payment_method, {
    project: 0,
    cash: 1
  }
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }
end
