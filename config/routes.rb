Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :orders, only: [:create, :show] do
        post :cancel, on: :member
        post :callback, on: :collection
      end
    end
  end
end
