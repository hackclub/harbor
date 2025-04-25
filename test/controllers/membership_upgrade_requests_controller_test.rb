require "test_helper"

class MembershipUpgradeRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get membership_upgrade_requests_new_url
    assert_response :success
  end

  test "should get create" do
    get membership_upgrade_requests_create_url
    assert_response :success
  end
end
