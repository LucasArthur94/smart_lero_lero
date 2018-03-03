require 'test_helper'

class TextControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get text_new_url
    assert_response :success
  end

  test "should get show" do
    get text_show_url
    assert_response :success
  end

end
