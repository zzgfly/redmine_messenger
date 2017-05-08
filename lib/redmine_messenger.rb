# Redmine Messenger plugin for Redmine

Rails.configuration.to_prepare do
  # Patches
  require_dependency 'redmine_messenger/patches/issue_patch'

  # Hooks
  require_dependency 'redmine_messenger/hooks'
end
