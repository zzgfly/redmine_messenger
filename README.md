# Messenger plugin for Redmine

This plugin posts updates to issues in your Redmine installation to [Slack](https://slack.com/), [Rocket.Chat](https://rocket.chat/) or [Mattermost](https://about.mattermost.com/) channel.

Redmine Supported versions: 3.0.x.

## Installation

Install ``redmine_messenger`` plugin for `Redmine`_

    cd $REDMINE_ROOT
    git clone git://github.com/alphanodes/redmine_messenger.git plugins/redmine_messenger
    bundle install --without development test

Restart Redmine, and you should see the plugin show up in the Plugins page.
Under the configuration options, set the Messenger API URL to the URL for an
Incoming WebHook integration in your Rocket.Chat account and also set the Messenger
Channel to the channel's handle (be careful, this is not the channel's display name
visible to users, you can find each channel's handle by navigating inside the channel
and clicking the down-arrow and selecting view info). See also the next two sections
for advanced and custom routing options.

## Customized Routing

You can also route messages to different channels on a per-project basis. To
do this, create a project custom field (Administration > Custom fields > Project)
named `Messenger Channel`. If no custom channel is defined for a project, the parent
project will be checked (or the default will be used). To prevent all notifications
from being sent for a project, set the custom channel to `-`.

For more information, see [https://www.redmine.org/projects/redmine/wiki/Plugins](https://www.redmine.org/projects/redmine/wiki/Plugins) (see also next section for an easy configuration demonstration).

## Screenshot Guided Configuration

Step 1: Create an Incoming Webhook in Messenger (Administration > Integrations > Incoming WebHook).

![step1](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step1.png)

Step 2: Install this Redmine plugin for Messenger.

![step2](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step2.png)

Step 3: Configure this Redmine plugin for Messenger. For per-project customized routing, leave the `Messenger Channel` field empty and follow the next steps, otherwise all Redmine projects will post to the same Messenger channel. Be careful when filling the channel field, you need to input the channel's handle, not the display name visible to users. You can find each channel's handle by going inside the channel and click the down-arrow and selecting view info.

![step3](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step3.png)

Step 4: For per-project customized routing, first create the project custom field (Administration > Custom fields > New custom field > Projects).

![step4a](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step4a.png)
![step4b](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step4b.png)

Step 5: For per-project customized routing, configure the Messenger channel handle inside your Redmine project.

![step5](https://raw.githubusercontent.com/alphanodes/redmine_messenger/assets/step5.png)

## Credits

The source code is forked from [https://github.com/altsol/redmine_mattermost](https://github.com/altsol/redmine_mattermost) . Special thanks to the original author and contributors for making this awesome hook for Redmine. This fork is just refactored to use Messenger-namespaced configuration options in order to use all hooks (Rocket.Chat, Mattermost and Slack) in a Redmine installation.
