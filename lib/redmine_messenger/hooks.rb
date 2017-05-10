# Redmine Messenger plugin for Redmine

module RedmineMessenger
  class MessengerListener < Redmine::Hook::Listener
    def redmine_rocketchat_issues_new_after_save(context = {})
      issue = context[:issue]

      channels = Messenger.channels_for_project issue.project
      url = Messenger.url_for_project issue.project
      post_private_issues = Messenger.post_private_issues_for_project(issue.project)

      return unless channels.present? && url
      return if issue.is_private? && post_private_issues != '1'

      msg = "[#{ERB::Util.html_escape(issue.project)}] #{ERB::Util.html_escape(issue.author)} created <#{Messenger.object_url issue}|#{ERB::Util.html_escape(issue)}>#{Messenger.mentions issue.description if RedmineMessenger.settings[:auto_mentions] == '1'}"

      attachment = {}
      attachment[:text] = ERB::Util.html_escape(issue.description) if issue.description && RedmineMessenger.settings[:new_include_description] == '1'
      attachment[:fields] = [{
        title: I18n.t(:field_status),
        value: ERB::Util.html_escape(issue.status.to_s),
        short: true
      }, {
        title: I18n.t(:field_priority),
        value: ERB::Util.html_escape(issue.priority.to_s),
        short: true
      }, {
        title: I18n.t(:field_assigned_to),
        value: ERB::Util.html_escape(issue.assigned_to.to_s),
        short: true
      }]

      attachment[:fields] << {
        title: I18n.t(:field_watcher),
        value: ERB::Util.html_escape(issue.watcher_users.join(', ')),
        short: true
      } if RedmineMessenger.settings[:display_watchers] == '1'

      speak msg, channels, attachment, url
    end

    def redmine_rocketchat_issues_edit_after_save(context={})
      issue = context[:issue]
      journal = context[:journal]

      channels = Messenger.channels_for_project issue.project
      url = Messenger.url_for_project issue.project
      post_private_issues = Messenger.post_private_issues_for_project(issue.project)
      post_private_notes = Messenger.post_private_notes_for_project(issue.project)

      return unless channels.present? && url && RedmineMessenger.settings[:post_updates] == '1'
      return if issue.is_private? && post_private_issues != '1'
      return if journal.private_notes? && post_private_notes != '1'

      msg = "[#{ERB::Util.html_escape(issue.project)}] #{ERB::Util.html_escape(journal.user.to_s)} updated <#{Messenger.object_url issue}|#{ERB::Util.html_escape(issue)}>#{Messenger.mentions journal.notes if RedmineMessenger.settings[:auto_mentions] == '1'}"

      attachment = {}
      attachment[:text] = ERB::Util.html_escape(journal.notes) if journal.notes && RedmineMessenger.settings[:updated_include_description] == '1'
      attachment[:fields] = journal.details.map { |d| Messenger.detail_to_field d }

      speak msg, channels, attachment, url
    end

    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      changeset = context[:changeset]

      channels = Messenger.channels_for_project issue.project
      url = Messenger.url_for_project issue.project
      post_private_issues = Messenger.post_private_issues_for_project(issue.project)

      return unless channels.present? && url && issue.save
      return if issue.is_private? && post_private_issues != '1'

      msg = "[#{ERB::Util.html_escape(issue.project)}] #{ERB::Util.html_escape(journal.user.to_s)} updated <#{Messenger.object_url issue}|#{ERB::Util.html_escape(issue)}>"

      repository = changeset.repository

      if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
        host, port, prefix = $2, $4, $5
        revision_url = Rails.application.routes.url_for(
          controller: 'repositories',
          action: 'revision',
          id: repository.project,
          repository_id: repository.identifier_param,
          rev: changeset.revision,
          host: host,
          protocol: Setting.protocol,
          port: port,
          script_name: prefix
        )
      else
        revision_url = Rails.application.routes.url_for(
          controller: 'repositories',
          action: 'revision',
          id: repository.project,
          repository_id: repository.identifier_param,
          rev: changeset.revision,
          host: Setting.host_name,
          protocol: Setting.protocol
        )
      end

      attachment = {}
      attachment[:text] = ll(Setting.default_language, :text_status_changed_by_changeset, "<#{revision_url}|#{ERB::Util.html_escape(changeset.comments)}>")
      attachment[:fields] = journal.details.map { |d| Messenger.detail_to_field d }

      speak msg, channels, attachment, url
    end

    def controller_wiki_edit_after_save(context = {})
      return unless RedmineMessenger.settings[:post_wiki_updates] == '1'

      project = context[:project]
      page = context[:page]

      user = page.content.author
      project_url = "<#{Messenger.object_url project}|#{ERB::Util.html_escape(project)}>"
      page_url = "<#{Messenger.object_url page}|#{page.title}>"
      comment = "[#{project_url}] #{page_url} updated by *#{user}*"

      channels = Messenger.channels_for_project project
      url = Messenger.url_for_project project

      return unless channels.present? && url

      attachment = nil
      unless page.content.comments.empty?
        attachment = {}
        attachment[:text] = "#{ERB::Util.html_escape(page.content.comments)}"
      end

      speak comment, channels, attachment, url
    end
  end
end
