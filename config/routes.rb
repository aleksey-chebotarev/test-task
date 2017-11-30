Rails.application.routes.draw do
  devise_for :users

  mount ResqueWeb::Engine => '/resque'

  root to: 'welcome#index'

  resources :users
end
