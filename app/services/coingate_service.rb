class CoingateService
  include HTTParty

  base_uri ENV['COINGATE_API_URL']
  headers 'Authorization' => "Bearer #{ENV['COINGATE_API_TOKEN']}"
  headers 'Content-Type' => 'application/json'

  def handle_response(response)
    unless response.is_a?(HTTParty::Response)
      Rails.logger.error "CoinGate API Error: Unexpected response type: #{response.class.inspect}"
      return nil
    end

    Rails.logger.info "CoinGate API Response: Code=#{response.code}, Body=#{response.body.inspect.to_s.truncate(500)}"

    unless response.success?
      Rails.logger.error "CoinGate API Error: Code=#{response.code}, Body=#{response.body.inspect.to_s.truncate(500)}"
      return nil
    end

    unless response.body.present? && response.body.is_a?(String)
      Rails.logger.warn "CoinGate API Success response with empty or non-string body (Type: #{response.body.class.inspect})"
      return nil
    end

    begin
      parsed_body = JSON.parse(response.body)
      Rails.logger.info "CoinGate API Response: Successfully parsed JSON."
      parsed_body
    rescue JSON::ParserError => e
      Rails.logger.error "CoinGate API JSON Parse Error: #{e.message} for body: #{response.body}"
      nil
    end
  end

  def create_order(order_params)
    Rails.logger.info "CoinGateService: Creating order. Body: #{order_params.to_json}"

    response = self.class.post('/orders', body: order_params.to_json)

    handle_response(response)
  rescue HTTParty::Error => e
    Rails.logger.error "HTTParty Error during create_order: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected Error during create_order: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def retrieve_order(order_id)
    Rails.logger.info "CoinGateService: Retrieving order ID: #{order_id}"

    response = self.class.get("/orders/#{order_id}")

    handle_response(response)
  rescue HTTParty::Error => e
    Rails.logger.error "HTTParty Error during retrieve_order: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected Error during retrieve_order: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def cancel_order(order_id)
    Rails.logger.info "CoinGateService: Canceling order ID: #{order_id}"

    response = self.class.post("/orders/#{order_id}/cancel")

    handle_response(response)
  rescue HTTParty::Error => e
    Rails.logger.error "HTTParty Error during cancel_order: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected Error during cancel_order: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  private :handle_response
end
