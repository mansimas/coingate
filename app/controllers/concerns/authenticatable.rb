module Authenticatable
  extend ActiveSupport::Concern

  def authenticate_knicko
    api_key = request.headers['X-API-Key']
    expected_key = ENV['PROXY_API_KEY']

    unless api_key.present? && expected_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_key)
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
