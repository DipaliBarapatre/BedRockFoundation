require 'test_helper'

class RigsControllerTest < ActionController::TestCase
  setup do
    @rig = rigs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rigs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create rig" do
    assert_difference('Rig.count') do
      post :create, rig: @rig.attributes
    end

    assert_redirected_to rig_path(assigns(:rig))
  end

  test "should show rig" do
    get :show, id: @rig
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @rig
    assert_response :success
  end

  test "should update rig" do
    put :update, id: @rig, rig: @rig.attributes
    assert_redirected_to rig_path(assigns(:rig))
  end

  test "should destroy rig" do
    assert_difference('Rig.count', -1) do
      delete :destroy, id: @rig
    end

    assert_redirected_to rigs_path
  end
end
