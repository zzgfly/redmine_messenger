require 'redmine'

require_dependency 'redmine_rocketchat/listener'

Redmine::Plugin.register :redmine_rocketchat do
  name 'Redmine Rocket.Chat'
  author 'Egon Zemmer'
  url 'https://github.com/phlegx/redmine_rocketchat'
  author_url 'https://phlegx.com'
  description 'Rocket.Chat integration'
  version '0.6.1'

  requires_redmine :version_or_higher => '2.0.0'

  settings \
    :default => {
      'callback_url' => 'https://rocket.chat/hooks/my_rocket_chat_token',
      'channel' => 'redmine',
      'icon' => 'https://raw.githubusercontent.com/phlegx/redmine_rocketchat/assets/icon.png',
      'username' => 'redmine.bot',
      'display_watchers' => '0',
      'auto_mentions' => '1',
      'post_updates' => '1',
      'new_include_description' => '1',
      'updated_include_description' => '1',
      'post_private_issues' => '1',
      'post_private_notes' => '1',
      'post_wiki_updates' => '0'
    },
    :partial => 'settings/rocketchat_settings'
end

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'issue'
  unless Issue.included_modules.include? RedmineRocketchat::IssuePatch
    Issue.send(:include, RedmineRocketchat::IssuePatch)
  end
end
