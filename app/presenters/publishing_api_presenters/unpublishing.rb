class PublishingApiPresenters::Unpublishing
  attr_reader :unpublishing, :update_type

  def initialize(unpublishing, options = {})
    @unpublishing = unpublishing
    @update_type = options[:update_type] || default_update_type
  end

  def as_json
    if unpublishing.redirect?
      redirect_hash
    else
      unpublishing_hash
    end
  end

  def base_path
    unpublishing.document_path
  end

private

  def redirect_hash
    {
      content_id: unpublishing.content_id,
      base_path: base_path,
      format: 'redirect',
      publishing_app: 'whitehall',
      redirects: [
        { path: base_path, type: 'exact', destination: alternative_path }
      ],
      update_type: update_type,
    }
  end

  def unpublishing_hash
    {
      base_path: base_path,
      content_id: unpublishing.content_id,
      title: edition.title,
      description: edition.summary,
      format: 'unpublishing',
      locale: I18n.locale.to_s,
      need_ids: edition.need_ids,
      public_updated_at: edition.public_timestamp,
      update_type: update_type,
      publishing_app: 'whitehall',
      rendering_app: edition.rendering_app,
      routes: [ { path: base_path, type: 'exact' } ],
      redirects: [],
      details: details,
    }
  end

  def edition
    @edition ||= Edition.unscoped.find(unpublishing.edition_id)
  end

  def alternative_path
    full_uri = Addressable::URI.parse(unpublishing.alternative_url)

    path_uri = Addressable::URI.new
    path_uri.path = full_uri.path
    path_uri.query = full_uri.query
    path_uri.fragment = full_uri.fragment

    path_uri.to_s
  end

  def details
    {
      explanation: unpublishing_explanation,
      unpublished_at: unpublishing.created_at,
      alternative_url: unpublishing.alternative_url
    }
  end

  def unpublishing_explanation
    Whitehall::EditionGovspeakRenderer.new(edition).unpublishing_explanation
  end

  def default_update_type
    'major'
  end
end
