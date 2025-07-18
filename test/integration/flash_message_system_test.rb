require "test_helper"

class FlashMessageSystemIntegrationTest < ActionDispatch::IntegrationTest
  test "flash messages are properly displayed on messages page" do
    sign_in users(:one)
    
    get messages_path
    assert_response :success
    
    # Check that flash container exists
    assert_select "#flash-message-container"
    assert_select "[data-controller*='flash-manager']"
  end
  
  test "flash messages are displayed after failed message creation" do
    sign_in users(:one)
    
    # Try to create an invalid message
    post messages_path, params: { content: "" }, headers: { "Accept" => "text/html" }
    
    # Should redirect or show error
    assert_response :unprocessable_entity
    
    # Check that flash container is present
    assert_select "#flash-message-container"
  end
  
  test "turbo stream flash updates work" do
    sign_in users(:one)
    
    # Try to create an invalid message via Turbo
    post messages_path, params: { content: "" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    # Should return turbo stream response
    assert_response :unprocessable_entity
    assert_match "turbo-stream", response.content_type
  end
end