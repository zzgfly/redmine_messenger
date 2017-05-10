require 'redmine'
require 'redmine_messenger'

Redmine::Plugin.register :redmine_messenger do
  name 'Redmine Messenger'
  author 'AlphaNodes GmbH'
  url 'https://github.com/alphanodes/redmine_messenger'
  author_url 'https://alphanodes.com/'
  description 'Messenger integration for Slack, Rocketchat and Mattermost support'
  version '0.6.2-dev'

  requires_redmine version_or_higher: '3.0.0'

  settings default: {
    messenger_url: '',
    messenger_channel: 'redmine',
    messenger_icon: 'https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/icon.png',
    messenger_username: 'robot',
    display_watchers: '0',
    auto_mentions: '1',
    post_updates: '1',
    new_include_description: '1',
    updated_include_description: '1',
    post_private_issues: '1',
    post_private_notes: '1',
    post_wiki_updates: '0'
  }, partial: 'settings/messenger_settings'
end
