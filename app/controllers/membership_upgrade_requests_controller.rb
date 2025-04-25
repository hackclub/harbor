class MembershipUpgradeRequestsController < ApplicationController
  def new
    unless current_user.eligible_for_next_status?
      redirect_to my_membership_path, alert: "You are not eligible for an upgrade."
    end

    @membership_upgrade_request = MembershipUpgradeRequest.new
  end

  def create
    @membership_upgrade_request = MembershipUpgradeRequest.new(membership_upgrade_request_params)
    @membership_upgrade_request.user = current_user
    @membership_upgrade_request.status = "pending"

    if @membership_upgrade_request.save
      if @membership_upgrade_request.payment_method == "direct_payment"
        # TODO: Create and enqueue a job to send the invoice
        # SendInvoiceJob.perform_later(@membership_upgrade_request)
      end

      redirect_to my_membership_path, notice: "Your upgrade request has been submitted!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def membership_upgrade_request_params
    params.require(:membership_upgrade_request).permit(:payment_method, :from_status, :to_status)
  end
end
