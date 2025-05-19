# **CoinGate Payment Proxy**

This application serves as a proxy layer between a merchant's online shop (simulated by Knicko) and the CoinGate payment gateway. It provides a simplified API for the shop to interact with CoinGate, handling authentication and parameter mapping internally.

## **Requirements Fulfilled**

- **Ability to Create Order:** Exposes an endpoint for the shop to initiate a new payment order via CoinGate.
- **Ability to Retrieve Order:** Provides an endpoint to fetch the current status and details of an existing order from CoinGate.
- **Ability to Cancel Order:** Offers an endpoint to cancel an order via CoinGate.
- **Credentials Storage:** Stores CoinGate API credentials securely using environment variables (and recommends Rails encrypted credentials for production).
- **Authentication:** Secures the API endpoints using an API key mechanism.
- **CoinGate Sandbox Environment:** Configured to interact with the CoinGate sandbox API.
- **Simple Documentation:** This README serves as the documentation for the available API endpoints.
- **Tested:** Includes RSpec tests for controller logic.

## **Technology Stack**

- **Backend:** Ruby on Rails 7.1.x (configured as API-only)
- **HTTP Client:** HTTParty gem
- **Authentication:** Custom API Key (using `ActiveSupport::SecurityUtils.secure_compare`)
- **Environment Variables:** dotenv-rails gem (for development)
- **Testing:** RSpec, RSpec Rails
- **Web Server:** Puma (default Rails)
- **Caching:** Rails Cache (using MemoryStore in development for IP caching)

## **Setup Instructions**

### **Prerequisites**

- Ruby 3.2.x
- Rails 7.1.x
- Bundler gem (gem install bundler)

### **Getting Started**

1. **Clone the repository:**  
    `git clone &lt;repository_url&gt;`
    `cd coingate`

2. **Install dependencies:**  
    `bundle install`

3. **Set up Environment Variables:** Create a file named .env in the root of your project directory. This file will store sensitive credentials for development. **Do NOT commit this file to version control.**

    ```
    # .env  
    COINGATE_API_TOKEN=YOUR_COINGATE_SANDBOX_API_TOKEN # Get this from your CoinGate Sandbox account  
    COINGATE_API_URL=<https://api-sandbox.coingate.com/v2> # CoinGate Sandbox API URL  
    PROXY_API_KEY=YOUR_SECRET_PROXY_API_KEY # A secret key for Knicko's shop to authenticate with your proxy  
    ```

Replace the placeholder values with your actual credentials.

1. **Get CoinGate Sandbox API Credentials:**
    - Sign up for a CoinGate Sandbox account at <https://sandbox.coingate.com/>.
    - Log in to your sandbox account.
    - Look for a menu item **Integrations**.
    - Continue generating **API** with **JSON** format.
    - Create new API credentials.
    - **Copy the API Auth Token displayed immediately after creation.** This token is shown only once. Paste it into your .env file as COINGATE_API_TOKEN.

## **Running the Application**

1. **Start the Rails server:**  
    `rails server`
    <br/>The server will typically start on <http://localhost:3000> in the development environment.
2. Testing Locally with Postman:  
    You can use a tool like Postman to send requests to your proxy's API endpoints. Remember to include the X-API-Key header for authentication (except for the callback endpoint).

    - **Authentication Header:** `X-API-Key: YOUR_SECRET_PROXY_API_KEY`
    - **Content-Type Header (for POST):** `Content-Type: application/json`

**Example: Create Order (POST)**

- **URL:** `<http://localhost:3000/api/v1/orders>`
- **Method:** `POST`
- **Body (raw, JSON):**  
  ```
    {  
    "order_id": "KNICKO-ORD-123",  
    "amount": 100.50,  
    "currency": "USD",  
    "callback_url": "<http://knickoshop.com/callback>",  
    "cancel_url": "<http://knickoshop.com/cancel>",  
    "success_url": "<http://knickoshop.com/success>",  
    "title": "Clothing Order",  
    "description": "Various items"  
    }  
  ```
    <br/>_(Note: The proxy will override the `callback_url` sent to CoinGate with its own callback endpoint URL.)_

## **API Endpoints**

All API endpoints are located under the `/api/v1` path.

### **1\. Create Order**

Initiates a new payment order with CoinGate.

- **URL:** `/api/v1/orders`
- **Method:** `POST`
- **Authentication:** `X-API-Key` header required.
- **Request Body (JSON):**
  - `order_id` (string, required): Unique ID from Knicko's shop.
  - `amount` (numeric, required): Price amount.
  - `currency` (string, required): Price currency (e.g., "USD", "EUR").
  - `callback_url` (string, optional): URL for CoinGate to send payment notifications (proxy will use its own callback endpoint).
  - `cancel_url` (string, optional): URL to redirect to if the user cancels the payment.
  - `success_url` (string, optional): URL to redirect to after successful payment.
  - `title` (string, optional): Order title.
  - `description` (string, optional): Order description.
- **Success Response (201 Created):** JSON object representing the CoinGate order details, including `id`, `status`, `payment_url`, etc. (as returned by CoinGate API).
- **Error Responses:**
  - `401 Unauthorized`: Invalid or missing `X-API-Key`.
  - `400 Bad Request`: Missing required parameters (`amount`, `currency`, `order_id`) in the request body.
  - `422 Unprocessable Entity`: CoinGate API validation error (e.g., invalid currency).
  - `500 Internal Server Error`: Failure to communicate with CoinGate API or unexpected error.

### **2\. Retrieve Order**

Fetches the details of an existing order from CoinGate.

- **URL:** `/api/v1/orders/:id` (Replace `:id` with the CoinGate Order ID)
- **Method:** `GET`
- **Authentication:** X-API-Key header required.
- **Request Parameters:** Order ID in the URL segment.
- **Success Response (200 OK):** JSON object representing the CoinGate order details.
- **Error Responses:**
  - `401 Unauthorized`: Invalid or missing `X-API-Key`.
  - `400 Bad Request`: Missing Order ID in the URL (though routing might catch this first).
  - `404 Not Found`: Order with the given ID not found on CoinGate or failed to retrieve.
  - `500 Internal Server Error`: Failure to communicate with CoinGate API or unexpected error.

### **3\. Cancel Order**

Cancels an existing order with CoinGate.

- **URL:** `/api/v1/orders/:id/cancel` (Replace `:id` with the CoinGate Order ID)
- **Method:** `POST`
- **Authentication:** `X-API-Key` header required.
- **Request Parameters:** Order ID in the URL segment.
- **Success Response (200 OK):** JSON object representing the updated CoinGate order details (status should be 'canceled').
- **Error Responses:**
  - `401 Unauthorized`: Invalid or missing `X-API-Key`.
  - `400 Bad Request`: Missing Order ID in the URL.
  - `422 Unprocessable Entity`: Failed to cancel the order on CoinGate (e.g., order already paid, invalid status for cancellation).
  - `500 Internal Server Error`: Failure to communicate with CoinGate API or unexpected error.

### **4\. CoinGate Callback (Payment Notification)**

Receives automated payment status updates from CoinGate.

- **URL:** `/api/v1/orders/callback`
- **Method:** `POST`
- **Authentication:** **IP Whitelisting** (must originate from CoinGate's callback IP addresses, fetched from `<https://api-sandbox.coingate.com/v2/ips-v4>` and cached). **Does NOT require `X-API-Key`.**
- **Request Body:** JSON or URL-encoded data sent by CoinGate with order status details.
- **Success Response (200 OK):** An empty response body (`head :ok`). This acknowledges receipt to CoinGate.
- **Error Responses:**
  - `401 Unauthorized`: Request did not originate from a valid CoinGate callback IP address.
  - `500 Internal Server Error`: Error processing the callback (e.g., parsing issue).

## **Deployed Application and Callback Verification**

The application is deployed to Heroku at the following URL:

**Heroku App URL:** <https://coingate-dabd49cb6426.herokuapp.com/>

To verify that the CoinGate callback functionality is working:

1. Use Postman (or a similar tool) to send a **Create Order** request to the Heroku App URL's `/api/v1/orders` endpoint (details above). Ensure you include the X-API-Key header.
2. In the successful response from the Create Order request, note the payment_url.
3. Open the payment_url in a web browser. This will take you to the CoinGate sandbox invoice page.
4. On the CoinGate sandbox invoice page, use the provided buttons (e.g., "Mark as Paid") to simulate a payment status change.
5. CoinGate's sandbox will then send a callback request to the callback URL configured during the order creation (which is the `/api/v1/orders/callback` endpoint on the Heroku app URL).
6. The proxy application on Heroku will receive this callback. The verify_coingate_ip before_action will validate the source IP. If the IP is valid (which it should be from CoinGate's sandbox), the callback action will execute.
7. The callback endpoint is configured to return a **200 OK** response status upon successful receipt and processing (which includes logging the callback details). While the response body is empty, the **200 OK status** indicates successful processing from the perspective of the receiving server (your proxy).

This sequence demonstrates that the callback mechanism is functional and secured by IP validation on the deployed application.


- **REQUEST DEMO**
```
Started POST "/api/v1/orders" for 62.80.225.156 at 2025-05-19 20:24:15 +0000
Parameters: {
  "order_id"=>"KNICKO-ORD-123", "amount"=>100.5, "currency"=>"USD", "callback_url"=>"http://knickoshop.com/callback", "cancel_url"=>"http://knickoshop.com/cancel", 
  "success_url"=>"http://knickoshop.com/success", "title"=>"Clothing Order", "description"=>"Various items"
}
CoinGateService: Creating order. Body: {
  "order_id":"KNICKO-ORD-123","price_amount":100.5,"price_currency":"USD",
  "callback_url":"https://coingate-dabd49cb6426.herokuapp.com/api/v1/orders/callback","cancel_url":"http://knickoshop.com/cancel","success_url":"http://knickoshop.com/success","title":"Clothing Order",
  "description":"Various items"
}
CoinGate API Response: Code=200, Body="{
  \"id\":247096,\"status\":\"new\",\"title\":\"Clothing Order\",\"do_not_convert\":false,\"orderable_type\":\"ApiApp\",\"orderable_id\":3189,
  \"uuid\":\"825b79f2-f576-4219-9d95-5307ab3d1d8c\",\"payment_gateway\":null,\"price_currency\":\"USD\",\"price_amount\":\"100.5\",
  \"lightning_network\":false,\"receive_currency\":\"\",\"receive_amount\":\"0\",\"created_at\":\"2025-05-19T20:24:16+00:00\",
  \"order_id\":\"KNICKO-ORD-123\",\"payment_url\":\"https://pay-sandbox.coingate.com/invoice/825b79f2-f57...
}
```

- **CALLBACK DEMO**
```
Started POST "/api/v1/orders/callback" for 3.122.122.94 at 2025-05-19 20:24:34 +0000
Processing by Api::V1::OrdersController#callback as */*
Parameters: {
  "id"=>247096, "order_id"=>"KNICKO-ORD-123", "status"=>"pending", "pay_amount"=>"0.00097073", "pay_currency"=>"BTC", 
  "price_amount"=>"100.5", "price_currency"=>"USD", "receive_currency"=>"USDC", "receive_amount"=>"100.065373", "created_at"=>"2025-05-19T20:24:16+00:00", 
  "token"=>"[FILTERED]", "underpaid_amount"=>"0.00097073", "overpaid_amount"=>"0", "is_refundable"=>false, "fees"=>[]
}
Verifying CoinGate callback IP: Incoming IP is 3.122.122.94
CoinGate IP verification successful for IP: 3.122.122.94
Received CoinGate callback for order: KNICKO-ORD-123
at=info method=POST path="/api/v1/orders/callback" host=coingate-dabd49cb6426.herokuapp.com request_id=bbbc097f-1fc5-4b09-8b42-402fdd61adf9 fwd="3.122.122.94" dyno=web.1 connect=0ms service=3ms status=200 bytes=418 protocol=https
```

- **SECONDARY CALLBACK AFTER MARKING AS PAID**

```
Started POST "/api/v1/orders/callback" for 3.122.122.94 at 2025-05-19 20:24:38 +0000
Processing by Api::V1::OrdersController#callback as */*
Parameters: {
  "id"=>247096, "order_id"=>"KNICKO-ORD-123", "status"=>"paid", "pay_amount"=>"0.00097073", "pay_currency"=>"BTC", 
  "price_amount"=>"100.5", "price_currency"=>"USD", "receive_currency"=>"USDC", "receive_amount"=>"100.065373", "created_at"=>"2025-05-19T20:24:16+00:00", 
  "token"=>"[FILTERED]", "underpaid_amount"=>"0.00097073", "overpaid_amount"=>"0", "is_refundable"=>false, 
  "fees"=>[{"type"=>"processing_fee", "amount"=>"1.010761", "currency"=>{"id"=>33, "symbol"=>"USDC"}}], 
  "paid_at"=>"2025-05-19T20:24:37+00:00"
}
```


## **Testing**

Run the RSpec test suite from your project root directory:

`rspec`

This will execute request specs (testing the API endpoints and their `before_action`s) and service specs (testing the `CoingateService` logic with mocked HTTP calls).

## **Deployment Considerations**

- **Environment Variables:** Ensure `COINGATE_API_TOKEN`, `COINGATE_API_URL`, and `PROXY_API_KEY` are securely configured in your production environment (e.g., using environment variables, Rails encrypted credentials).
- **Callback URL:** Configure `config.action_controller.default_url_options` in `config/environments/production.rb` to match your proxy's production domain and protocol (e.g., `config.action_controller.default_url_options = { host: 'your-proxy-domain.com', protocol: 'https' }`).
- **SSL:** Deploy your application with SSL enabled (`https`) for security. Configure your web server (Puma, Nginx, Apache) and hosting environment accordingly. `config.force_ssl = true` is set in `production.rb`.
- **Web Server:** Configure Puma or another production web server (like Nginx or Apache) to serve your Rails application.
- **IP Whitelisting:** The callback endpoint's IP whitelisting relies on fetching IPs from CoinGate and caching them. Ensure your production environment's cache store is appropriately configured (e.g., Redis, Memcached) for persistence across process restarts if needed, though the 24-hour fetch interval is a reasonable default.
- **Error Monitoring & Logging:** Set up production logging and error monitoring to track any issues.

## **Future Improvements**

- **Callback Signature Verification:** Implement verification of CoinGate's callback signature for enhanced security.
- **More Robust Error Handling:** Add more specific error handling and logging based on CoinGate API error responses.
- **Database for Logging/Status:** Introduce a simple database to log incoming requests, outgoing CoinGate calls, and received callbacks for auditing and debugging.
- **Forwarding Callbacks to Knicko:** Implement the logic within the `callback` endpoint to securely forward the status update to Knicko's internal system.
- **Admin Interface:** Add a basic web interface for monitoring logs or managing configurations.
- **Rate Limiting:** Implement rate limiting on the proxy's endpoints to protect against abuse.
