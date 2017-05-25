# Redmine Messenger plugin for Redmine

RedmineApp::Application.routes.draw do
  match 'projects/:id/messenger_settings/save',
        to: 'messenger_settings#save',
        via: %i[post put patch]
end
