Rails.application.routes.draw do
  resources :texts
  
  root 'texts#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
