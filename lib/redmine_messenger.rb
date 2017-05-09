# Redmine Messenger plugin for Redmine

Rails.configuration.to_prepare do
  # Patches
  require_dependency 'redmine_messenger/patches/issue_patch'

  # Hooks
  require_dependency 'redmine_messenger/hooks'

  module RedmineMessenger
    def self.settings
      Setting[:plugin_redmine_messenger].blank? ? {} : Setting[:plugin_redmine_messenger]
    end
  end
end
