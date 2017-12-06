require "test_helper"

class PublicUploadsControllerTest < ActionController::TestCase
  test "redirect asset requests that aren't made via the asset host" do
    host! 'www.example.com'
    get :show, params: {path: '/foo/bar', extension: '.txt'}
    puts response.body
  end

#   test "redirect asset requests that aren't made via the asset host" do
#     host! 'www.example.com'
# # p ['host', host]
# # p ['scheme', scheme]
#     get "/government/uploads/foo.txt"
# # p ['Plek.new.public_asset_host', Plek.new.public_asset_host]
#     assert_redirected_to URI.parse(Plek.new.public_asset_host).host + '/government/uploads/foo.txt'
#   end

  # test "responds to asset requests that are made via the asset host" do
  #   host! URI.parse(Plek.new.public_asset_host).host
  #   get "/government/uploads/foo.txt"
  #   assert_response 200
  # end
end
