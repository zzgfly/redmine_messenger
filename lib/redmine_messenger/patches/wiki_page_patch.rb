# Redmine Messenger plugin for Redmine

module RedmineMessenger
  module Patches
    module WikiPagePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_create :send_messenger_create
          after_update :send_messenger_update
        end
      end

      module InstanceMethods
        def send_messenger_create
          return unless RedmineMessenger.settings[:post_wiki] == '1'

          user = User.current
          project_url = "<#{Messenger.object_url self}|#{ERB::Util.html_escape(project)}>"
          page_url = "<#{Messenger.object_url self}|#{title}>"
          comment = "[#{project_url}] #{page_url} created by *#{user}*"

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url
          Messenger.speak comment, channels, nil, url
        end

        def send_messenger_update
          return unless RedmineMessenger.settings[:post_wiki_updates] == '1'

          user = content.author
          project_url = "<#{Messenger.object_url self}|#{ERB::Util.html_escape(project)}>"
          page_url = "<#{Messenger.object_url self}|#{title}>"
          comment = "[#{project_url}] #{page_url} updated by *#{user}*"

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url

          attachment = nil
          unless content.comments.empty?
            attachment = {}
            attachment[:text] = ERB::Util.html_escape(content.comments.to_s)
          end

          Messenger.speak comment, channels, attachment, url
        end
      end
    end
  end
end

unless Issue.included_modules.include? RedmineMessenger::Patches::IssuePatch
  Issue.send(:include, RedmineMessenger::Patches::IssuePatch)
end
