class Api::V1::OrdersController < ApplicationController
  wrap_parameters false
  skip_before_action :verify_authenticity_token

  include Authenticatable
  before_action :authenticate_knicko
  before_action :validate_params, only: [:create, :show, :cancel]

  def create
    coingate_params = {
      order_id: order_params[:order_id],
      price_amount: order_params[:amount],
      price_currency: order_params[:currency],
      callback_url: order_params[:callback_url],
      cancel_url: order_params[:cancel_url],
      success_url: order_params[:success_url],
      title: order_params[:title],
      description: order_params[:description]
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
end
