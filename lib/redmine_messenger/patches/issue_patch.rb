# Redmine Messenger plugin for Redmine

module RedmineMessenger
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_create :create_from_issue
          after_save :save_from_issue
        end
      end

      module InstanceMethods
        def create_from_issue
          @create_already_fired = true
          Redmine::Hook.call_hook(:redmine_rocketchat_issues_new_after_save, issue: self)
          true
        end

        def save_from_issue
          unless @create_already_fired
            Redmine::Hook.call_hook(:redmine_rocketchat_issues_edit_after_save, issue: self, journal: self.current_journal) unless self.current_journal.nil?
          end
          true
        end
      end
    end
  end
end

unless Issue.included_modules.include? RedmineMessenger::Patches::IssuePatch
  Issue.send(:include, RedmineMessenger::Patches::IssuePatch)
end
