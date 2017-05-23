# Redmine Messenger plugin for Redmine

require_dependency 'projects_helper'

module RedmineMessenger
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :project_settings_tabs, :messenger
        end
      end

      module InstanceMethods
        def project_messenger_options(active)
          options_for_select({ l(:label_messenger_settings_default) => 0,
                               l(:label_messenger_settings_disabled) => 1,
                               l(:label_messenger_settings_enabled) => 2 }, active)
        end

        def project_settings_tabs_with_messenger
          tabs = project_settings_tabs_without_messenger
          action = { name: 'messenger',
                     controller: 'messenger_settings',
                     action: :show,
                     partial: 'messenger_settings/show',
                     label: :label_messenger }

          tabs << action if User.current.allowed_to?(:manage_messenger, @project)
          tabs
        end

        def project_setting_messenger_default_value(value)
          if RedmineMessenger.settings[value] == '1'
            l(:label_messenger_settings_enabled)
          else
            l(:label_messenger_settings_disabled)
          end
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineMessenger::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineMessenger::Patches::ProjectsHelperPatch)
end
