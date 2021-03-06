require 'test_helper'

class AssetManagerIntegrationTest
  class CreatingAnOrganisationLogo < ActiveSupport::TestCase
    test 'sends the logo to Asset Manager' do
      filename = '960x640_jpeg.jpg'
      organisation = FactoryBot.build(
        :organisation,
        organisation_logo_type_id: OrganisationLogoType::CustomLogo.id,
        logo: File.open(fixture_path.join('images', filename))
      )

      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/#{filename}/))

      organisation.save!
    end
  end

  class RemovingAnOrganisationLogo < ActiveSupport::TestCase
    test 'removing an organisation logo removes it from asset manager' do
      logo_filename = '960x640_jpeg.jpg'
      organisation = FactoryBot.create(
        :organisation,
        organisation_logo_type_id: OrganisationLogoType::CustomLogo.id,
        logo: File.open(fixture_path.join('images', logo_filename))
      )
      logo_asset_id = 'asset-id'
      Services.asset_manager.stubs(:whitehall_asset)
        .with(regexp_matches(/#{logo_filename}/))
        .returns('id' => "http://asset-manager/assets/#{logo_asset_id}")

      Services.asset_manager.expects(:delete_asset).with(logo_asset_id)

      organisation.remove_logo!
    end
  end

  class ReplacingAnOrganisationLogo < ActiveSupport::TestCase
    test 'replacing an organisation logo removes the old logo from asset manager' do
      old_logo_filename = '960x640_jpeg.jpg'
      organisation = FactoryBot.create(
        :organisation,
        organisation_logo_type_id: OrganisationLogoType::CustomLogo.id,
        logo: File.open(fixture_path.join('images', old_logo_filename))
      )
      old_logo_asset_id = 'asset-id'
      Services.asset_manager.stubs(:whitehall_asset)
        .with(regexp_matches(/#{old_logo_filename}/))
        .returns('id' => "http://asset-manager/assets/#{old_logo_asset_id}")

      Services.asset_manager.expects(:delete_asset).with(old_logo_asset_id)

      organisation.logo = File.open(fixture_path.join('images', '960x640_gif.gif'))
      organisation.save!
    end
  end

  class CreatingAPersonImage < ActiveSupport::TestCase
    setup do
      @filename = 'minister-of-funk.960x640.jpg'
      @person = FactoryBot.build(
        :person,
        image: File.open(fixture_path.join(@filename))
      )

      Services.asset_manager.stubs(:create_whitehall_asset)
    end

    test 'sends the person image to Asset Manager' do
      Services.asset_manager.expects(:create_whitehall_asset).with(file_and_legacy_url_path_matching(/#{@filename}/))

      @person.save!
    end

    test 'sends each version of the person image to Asset Manager' do
      ImageUploader.versions.each_key do |version_prefix|
        Services.asset_manager.expects(:create_whitehall_asset).with(
          file_and_legacy_url_path_matching(/#{version_prefix}_#{@filename}/)
        )
      end

      @person.save!
    end

    test 'saves the person image to the file system' do
      @person.save!

      assert File.exist?(@person.image.path)
    end

    test 'saves each version of the person image to the file system' do
      @person.save!

      @person.image.versions.each_pair do |_, image|
        assert File.exist?(image.file.path)
      end
    end
  end

  class RemovingAPersonImage < ActiveSupport::TestCase
    setup do
      @filename = 'minister-of-funk.960x640.jpg'
      @person = FactoryBot.create(
        :person,
        image: File.open(fixture_path.join(@filename))
      )

      VirusScanHelpers.simulate_virus_scan(@person.image, include_versions: true)
      @person.reload

      @asset_id = 'asset-id'
      Services.asset_manager.stubs(:whitehall_asset).returns('id' => "http://asset-manager/assets/#{@asset_id}")
    end

    test 'removes the person image and all its versions from asset manager' do
      # Creating a person creates one asset record in asset manager
      # for the uploaded asset and one asset record for each of the
      # versions defined in ImageUploader.
      expected_number_of_versions = @person.image.versions.size + 1
      Services.asset_manager.expects(:delete_asset).with(@asset_id).times(expected_number_of_versions)

      @person.remove_image!
    end

    test 'removes the person image from the file system' do
      image_path = @person.image.path

      assert File.exist?(image_path)

      @person.remove_image!

      refute File.exist?(image_path)
    end

    test 'removes each version of the person image from the file system' do
      file_paths = @person.image.versions.map { |_, image| image.file.path }

      file_paths.each { |path| assert File.exist?(path) }

      @person.remove_image!

      file_paths.each { |path| refute File.exist?(path) }
    end
  end

  class ReplacingAPersonImage < ActiveSupport::TestCase
    setup do
      @filename = 'minister-of-funk.960x640.jpg'
      @person = FactoryBot.create(
        :person,
        image: File.open(fixture_path.join(@filename))
      )

      VirusScanHelpers.simulate_virus_scan(@person.image, include_versions: true)
      @person.reload
    end

    test 'sends the new image and its versions to asset manager' do
      expected_number_of_versions = @person.image.versions.size + 1
      Services.asset_manager.expects(:create_whitehall_asset).times(expected_number_of_versions)

      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!
    end

    test 'saves the person image to the file system' do
      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!

      assert File.exist?(@person.image.path)
    end

    test 'saves each version of the person image to the file system' do
      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!

      @person.image.versions.each_pair do |_, image|
        assert File.exist?(image.file.path)
      end
    end

    test 'does not remove the original image from the file system' do
      image_path = @person.image.path

      assert File.exist?(image_path)

      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!

      assert File.exist?(image_path)
    end

    test 'does not remove each version of the original person image from the file system' do
      file_paths = @person.image.versions.map { |_, image| image.file.path }

      file_paths.each { |path| assert File.exist?(path) }

      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!

      file_paths.each { |path| assert File.exist?(path) }
    end

    test 'does not remove the original images from asset manager' do
      Services.asset_manager.expects(:delete_asset).never

      @person.image = File.open(fixture_path.join('big-cheese.960x640.jpg'))
      @person.save!
    end
  end

  class CreatingAConsultationResponseFormData < ActiveSupport::TestCase
    setup do
      @filename = 'greenpaper.pdf'
      @consultation_response_form_data = FactoryBot.build(
        :consultation_response_form_data,
        file: File.open(fixture_path.join(@filename))
      )
    end

    test 'sends the consultation response form data file to Asset Manager' do
      Services.asset_manager.expects(:create_whitehall_asset).with(
        file_and_legacy_url_path_matching(/#{@filename}/)
      )

      @consultation_response_form_data.save!
    end

    test 'saves the consultation response form data file to the file system' do
      @consultation_response_form_data.save!

      assert File.exist?(@consultation_response_form_data.file.path)
    end
  end

  class RemovingAConsultationResponseFormData < ActiveSupport::TestCase
    setup do
      filename = 'greenpaper.pdf'
      @consultation_response_form_asset_id = 'asset-id'
      @consultation_response_form_data = FactoryBot.create(
        :consultation_response_form_data,
        file: File.open(fixture_path.join(filename))
      )
      VirusScanHelpers.simulate_virus_scan(@consultation_response_form_data.file)
      @consultation_response_form_data.reload
      @file_path = @consultation_response_form_data.file.path

      Services.asset_manager.stubs(:whitehall_asset)
        .with(regexp_matches(/#{filename}/))
        .returns('id' => "http://asset-manager/assets/#{@consultation_response_form_asset_id}")
      Services.asset_manager.stubs(:delete_asset)
    end

    test 'removing a consultation response form data file removes it from the file system' do
      assert File.exist?(@file_path)

      @consultation_response_form_data.remove_file!

      refute File.exist?(@file_path)
    end

    test 'removing a consultation response form data file removes it from asset manager' do
      Services.asset_manager.expects(:delete_asset)
        .with(@consultation_response_form_asset_id)

      @consultation_response_form_data.remove_file!
    end
  end

  class ReplacingAConsultationResponseFormData < ActiveSupport::TestCase
    setup do
      filename = 'greenpaper.pdf'
      @consultation_response_form_asset_id = 'asset-id'
      @consultation_response_form_data = FactoryBot.create(
        :consultation_response_form_data,
        file: File.open(fixture_path.join(filename))
      )
      VirusScanHelpers.simulate_virus_scan(@consultation_response_form_data.file)
      @consultation_response_form_data.reload
      @file_path = @consultation_response_form_data.file.path

      Services.asset_manager.stubs(:whitehall_asset)
        .with(regexp_matches(/#{filename}/))
        .returns('id' => "http://asset-manager/assets/#{@consultation_response_form_asset_id}")
      Services.asset_manager.stubs(:delete_asset)
    end

    test 'replacing a consultation response form data file removes the old file from the file system' do
      assert File.exist?(@file_path)

      @consultation_response_form_data.file = File.open(fixture_path.join('whitepaper.pdf'))
      @consultation_response_form_data.save!

      refute File.exist?(@file_path)
    end

    test 'replacing a consultation response form data file removes the old file from asset manager' do
      Services.asset_manager.expects(:delete_asset)
        .with(@consultation_response_form_asset_id)

      @consultation_response_form_data.file = File.open(fixture_path.join('whitepaper.pdf'))
      @consultation_response_form_data.save!
    end
  end
end
