require 'test_helper'

class AssetsTest < ActionDispatch::IntegrationTest
  setup do
    asset_filename = 'asset.txt'
    @asset_filesystem_path = File.join(Whitehall.clean_uploads_root, asset_filename)
    FileUtils.touch(@asset_filesystem_path)

    @asset_url_path = "/government/uploads/#{asset_filename}"

    @asset_host = 'asset-host.gov.uk'
    Plek.any_instance.stubs(:public_asset_host).returns("http://#{@asset_host}")
  end

  teardown do
    FileUtils.rm(@asset_filesystem_path)
  end

  test "redirect asset requests that aren't made via the asset host" do
    host! 'not-asset-host.gov.uk'

    get @asset_url_path

    assert_redirected_to "http://#{@asset_host}#{@asset_url_path}"
  end

  test "responds to asset requests that are made via the asset host" do
    host! @asset_host

    get @asset_url_path

    assert_response 200
  end
end
