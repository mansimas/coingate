require 'rails_helper'

RSpec.describe 'Api::V1::Orders', type: :request do
  let(:proxy_api_key) { 'test_proxy_api_key' }
  let(:coingate_api_token) { 'test_coingate_api_token' }
  let(:coingate_api_url) { 'https://api-sandbox.coingate.com/v2' }

  before do
    ENV['PROXY_API_KEY'] = proxy_api_key
    ENV['COINGATE_API_TOKEN'] = coingate_api_token
    ENV['COINGATE_API_URL'] = coingate_api_url

    Rails.cache.clear

    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  after do
    ENV.delete('PROXY_API_KEY')
    ENV.delete('COINGATE_API_TOKEN')
    ENV.delete('COINGATE_API_URL')
  end

  def json_response
    JSON.parse(response.body)
  end

  describe 'Authentication' do
    let(:valid_headers) { { 'X-API-Key' => proxy_api_key, 'Content-Type' => 'application/json' } }
    let(:invalid_headers) { { 'X-API-Key' => 'wrong_key', 'Content-Type' => 'application/json' } }
    let(:missing_headers) { { 'Content-Type' => 'application/json' } }
    let(:valid_create_params) { { order_id: 'ORD-123', amount: 100.5, currency: 'USD' } }

    context 'with valid API key' do
      it 'allows access to protected endpoints' do
        allow_any_instance_of(CoingateService).to receive(:create_order).and_return({ 'id' => 1, 'status' => 'new' })
        post '/api/v1/orders', params: valid_create_params, headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid API key' do
      it 'returns unauthorized' do
        post '/api/v1/orders', params: valid_create_params, headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq({ 'error' => 'Unauthorized' })
      end
    end

    context 'with missing API key' do
      it 'returns unauthorized' do
        post '/api/v1/orders', params: valid_create_params, headers: missing_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq({ 'error' => 'Unauthorized' })
      end
    end
  end

  describe 'Parameter Validation' do
    let(:valid_headers) { { 'X-API-Key' => proxy_api_key, 'Content-Type' => 'application/json' } }

    context 'for create action' do
      let(:base_params) { { callback_url: 'http://cb.com', cancel_url: 'http://cancel.com', success_url: 'http://success.com', title: 'Test', description: 'Desc' } }

      it 'returns bad request if amount is missing' do
        post '/api/v1/orders', params: base_params.merge(order_id: 'ORD-123', currency: 'USD'), headers: valid_headers, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(json_response).to eq({ 'error' => 'Missing required parameters (amount, currency, order_id)' })
      end

      it 'returns bad request if currency is missing' do
        post '/api/v1/orders', params: base_params.merge(order_id: 'ORD-123', amount: 100.5), headers: valid_headers, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(json_response).to eq({ 'error' => 'Missing required parameters (amount, currency, order_id)' })
      end

      it 'returns bad request if order_id is missing' do
        post '/api/v1/orders', params: base_params.merge(amount: 100.5, currency: 'USD'), headers: valid_headers, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(json_response).to eq({ 'error' => 'Missing required parameters (amount, currency, order_id)' })
      end

      it 'allows access if all required parameters are present' do
        allow_any_instance_of(CoingateService).to receive(:create_order).and_return({ 'id' => 1, 'status' => 'new' })
        post '/api/v1/orders', params: base_params.merge(order_id: 'ORD-123', amount: 100.5, currency: 'USD'), headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context 'for show action' do
      it 'returns not found if the ID in the URL is not a valid order ID' do
        allow_any_instance_of(CoingateService).to receive(:retrieve_order).and_return(nil)
        get '/api/v1/orders/invalid_order_id', headers: valid_headers
        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq({ 'error' => "Order with ID invalid_order_id not found or failed to retrieve" })
      end

      it 'allows access if id is present in the URL' do
        allow_any_instance_of(CoingateService).to receive(:retrieve_order).and_return({ 'id' => 'order_abc', 'status' => 'paid' })
        get '/api/v1/orders/order_abc', headers: valid_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'for cancel action' do
      it 'returns unprocessable entity if the ID in the URL is not a valid order ID for cancellation' do
        allow_any_instance_of(CoingateService).to receive(:cancel_order).and_return(nil)
        post '/api/v1/orders/invalid_order_id/cancel', headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'error' => "Failed to cancel order with ID invalid_order_id" })
      end

      it 'allows access if id is present in the URL' do
        allow_any_instance_of(CoingateService).to receive(:cancel_order).and_return({ 'id' => 'order_xyz', 'status' => 'canceled' })
        post '/api/v1/orders/order_xyz/cancel', headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'CoinGate API Interaction' do
    let(:valid_headers) { { 'X-API-Key' => proxy_api_key, 'Content-Type' => 'application/json' } }

    context 'POST /api/v1/orders' do
      let(:valid_create_params) { { order_id: 'ORD-123', amount: 100.5, currency: 'USD', callback_url: 'http://cb.com' } }
      let(:coingate_success_response) { { 'id' => 1, 'status' => 'new', 'payment_url' => 'http://pay.coingate.com/invoice/1' } }
      let(:coingate_failure_response) { nil }

      it 'calls CoingateService#create_order with correct params and returns created on success' do
        expected_coingate_params = {
          order_id: 'ORD-123',
          price_amount: 100.5,
          price_currency: 'USD',
          callback_url: 'http://test.host/api/v1/orders/callback',
          cancel_url: nil,
          success_url: nil,
          title: nil,
          description: nil
        }.compact

        allow_any_instance_of(ActionDispatch::Routing::UrlFor).to receive(:url_for).and_return('http://test.host/api/v1/orders/callback')

        allow_any_instance_of(CoingateService).to receive(:create_order).with(expected_coingate_params).and_return(coingate_success_response)

        post '/api/v1/orders', params: valid_create_params, headers: valid_headers, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to eq(coingate_success_response)
      end

      it 'returns internal server error if CoingateService#create_order returns nil' do
        allow_any_instance_of(ActionDispatch::Routing::UrlFor).to receive(:url_for).and_return('http://test.host/api/v1/orders/callback')
        allow_any_instance_of(CoingateService).to receive(:create_order).and_return(coingate_failure_response)

        post '/api/v1/orders', params: valid_create_params, headers: valid_headers, as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(json_response).to eq({ 'error' => 'Failed to create order with CoinGate' })
      end
    end

    context 'GET /api/v1/orders/:id' do
      let(:order_id) { 'order_abc' }
      let(:coingate_success_response) { { 'id' => order_id, 'status' => 'paid' } }
      let(:coingate_failure_response) { nil }

      it 'calls CoingateService#retrieve_order with correct id and returns ok on success' do
        allow_any_instance_of(CoingateService).to receive(:retrieve_order).with(order_id).and_return(coingate_success_response)

        get "/api/v1/orders/#{order_id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(coingate_success_response)
      end

      it 'returns not found if CoingateService#retrieve_order returns nil' do
        allow_any_instance_of(CoingateService).to receive(:retrieve_order).with(order_id).and_return(coingate_failure_response)

        get "/api/v1/orders/#{order_id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq({ 'error' => "Order with ID #{order_id} not found or failed to retrieve" })
      end
    end

    context 'POST /api/v1/orders/:id/cancel' do
      let(:order_id) { 'order_xyz' }
      let(:coingate_success_response) { { 'id' => order_id, 'status' => 'canceled' } }
      let(:coingate_failure_response) { nil }

      it 'calls CoingateService#cancel_order with correct id and returns ok on success' do
        allow_any_instance_of(CoingateService).to receive(:cancel_order).with(order_id).and_return(coingate_success_response)

        post "/api/v1/orders/#{order_id}/cancel", headers: valid_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(coingate_success_response)
      end

      it 'returns unprocessable entity if CoingateService#cancel_order returns nil' do
        allow_any_instance_of(CoingateService).to receive(:cancel_order).with(order_id).and_return(coingate_failure_response)

        post "/api/v1/orders/#{order_id}/cancel", headers: valid_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to eq({ 'error' => "Failed to cancel order with ID #{order_id}" })
      end
    end
  end
end
