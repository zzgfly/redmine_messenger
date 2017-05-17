# Redmine Messenger plugin for Redmine

Rails.configuration.to_prepare do
  # Patches
  require_dependency 'redmine_messenger/patches/issue_patch'
  require_dependency 'redmine_messenger/patches/wiki_page_patch'

  require 'redmine_messenger/patches/contact_patch' if RedmineMessenger::REDMINE_CONTACTS_SUPPORT
  require 'redmine_messenger/patches/db_entry_patch' if RedmineMessenger::REDMINE_DB_SUPPORT
  require 'redmine_messenger/patches/password_patch' if RedmineMessenger::REDMINE_PASSWORDS_SUPPORT

  # Hooks
  require_dependency 'redmine_messenger/hooks'

  module RedmineMessenger
    REDMINE_CONTACTS_SUPPORT = Redmine::Plugin.installed?('redmine_contacts') ? true : false
    REDMINE_DB_SUPPORT = Redmine::Plugin.installed?('redmine_db') ? true : false
    REDMINE_PASSWORDS_SUPPORT = Redmine::Plugin.installed?('redmine_passwords') ? true : false

    def self.settings
      Setting[:plugin_redmine_messenger].blank? ? {} : Setting[:plugin_redmine_messenger]
    end
  end
end
