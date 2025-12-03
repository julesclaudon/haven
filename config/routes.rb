Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :archetypes, only: [:index, :show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resources :initial_quizzes, only: [:new, :create, :show, :edit, :update]
  resources :states, only: [:new, :create, :show, :index]
  resources :analyses, only: [:index, :show]
  resources :chats, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end
  resource :dashboard, only: :show

end
