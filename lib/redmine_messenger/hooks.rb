# Redmine Messenger plugin for Redmine

module RedmineMessenger
  class MessengerListener < Redmine::Hook::Listener
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

      Messenger.speak msg, channels, attachment, url
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

      Messenger.speak comment, channels, attachment, url
    end
  end
end
