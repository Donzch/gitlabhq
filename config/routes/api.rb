constraints(::Constraints::FeatureConstrainer.new(:graphql)) do
  post '/api/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/-/graphql-explorer', graphql_path: '/api/graphql'
end

API::API.logger Rails.logger
mount API::API => '/'
