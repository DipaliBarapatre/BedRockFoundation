require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get referrals" do
    get :referrals
    assert_response :success
  end

end
