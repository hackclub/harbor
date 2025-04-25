class SendInvoiceJob < ApplicationJob
  def perform(membership_upgrade_request)
    # "https://hcb.hackclub.com/api/v4/invoices"
    HTTP.auth("Bearer #{ENV['HCB_API_KEY']}")
        .post("https://hcb.hackclub.com/api/v4/invoices",
              json: {
                due_date: 1.month.from_now.to_date,
                item_description: "Membership Upgrade",
                item_amount: 10 * 100,
                sponsor_name: membership_upgrade_request.user.name,
                sponsor_email: membership_upgrade_request.user.email_addresses.first.email,
                sponsor_address_line1:,
                sponsor_address_line2:,
                sponsor_address_city:,
                sponsor_address_state:,
                sponsor_address_postal_code:,
                sponsor_address_country:
              })
  end
end
