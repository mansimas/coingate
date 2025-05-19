class Api::V1::OrdersController < ApplicationController
  wrap_parameters false
  skip_before_action :verify_authenticity_token

  include Authenticatable
  before_action :authenticate_knicko, only: [:create, :show, :cancel]
  before_action :validate_params, only: [:create, :show, :cancel]
  before_action :verify_coingate_ip, only: [:callback]

  def create
    permitted = order_params

    callback_url = url_for(controller: 'api/v1/orders', action: 'callback', only_full_url: true)

    coingate_params = {
      order_id:       permitted[:order_id],
      price_amount:   permitted[:amount],
      price_currency: permitted[:currency],
      callback_url:   callback_url,
      cancel_url:     permitted[:cancel_url],
      success_url:    permitted[:success_url],
      title:          permitted[:title],
      description:    permitted[:description]
    }.compact

    result = CoingateService.new.create_order(coingate_params)
    return render json: result, status: :created if result

    render json: { error: 'Failed to create order with CoinGate' }, status: :internal_server_error
  end

  def show
    result = CoingateService.new.retrieve_order(params[:id])
    return render json: result if result

    render json: { error: "Order with ID #{params[:id]} not found or failed to retrieve" }, status: :not_found
  end

  def cancel
    result = CoingateService.new.cancel_order(params[:id])
    return render json: result if result

    render json: { error: "Failed to cancel order with ID #{params[:id]}" }, status: :unprocessable_entity
  end

  def callback
    Rails.logger.info "Received CoinGate callback for order: #{params[:order_id]}"
    Rails.logger.info "Callback details: #{params.inspect}"

    head :ok
  end

  private

  def order_params
    params.permit(:order_id, :amount, :currency, :callback_url, :cancel_url, :success_url, :title, :description)
  end

  def validate_params
    if action_name.to_sym == :create
      unless params[:amount].present? && params[:currency].present? && params[:order_id].present?
        render json: { error: 'Missing required parameters (amount, currency, order_id)' }, status: :bad_request
        return false
      end
    end

    if [:show, :cancel].include?(action_name.to_sym)
      unless params[:id].present?
        render json: { error: 'Missing order ID in URL' }, status: :bad_request
        return false
      end
    end

    true
  end

  def verify_coingate_ip
    coingate_ips_string = ENV['COINGATE_CALLBACK_IPS']
    valid_ips = coingate_ips_string.to_s.split(',').map(&:strip).reject(&:empty?)

    unless valid_ips.is_a?(Array) && valid_ips.present?
      Rails.logger.error "CoinGate IP verification failed: COINGATE_CALLBACK_IPS environment variable is not set or is empty."
      render json: { error: 'Unauthorized IP' }, status: :unauthorized
      return false
    end

    request_ip = request.remote_ip
    Rails.logger.info "Verifying CoinGate callback IP: Incoming IP is #{request_ip}"

    unless valid_ips.include?(request_ip)
      Rails.logger.warn "CoinGate IP verification failed: Incoming IP #{request_ip} is not in the valid list."
      render json: { error: 'Unauthorized IP' }, status: :unauthorized
      return false
    end

    Rails.logger.info "CoinGate IP verification successful for IP: #{request_ip}"
    true
  end
end
