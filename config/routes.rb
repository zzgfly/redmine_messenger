# Redmine Messenger plugin for Redmine

RedmineApp::Application.routes.draw do
  match 'projects/:id/messenger_settings/:action', controller: 'messenger_settings', via: %i[get post put patch]
end
