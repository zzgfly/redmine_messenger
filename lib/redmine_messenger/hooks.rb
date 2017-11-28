# Redmine Messenger plugin for Redmine

module RedmineMessenger
  class MessengerListener < Redmine::Hook::Listener
    
    # def controller_issues_new_after_save(context={})
    #   return unless self.class.get_setting(:add_notify)
    #   issue = context[:issue]
    #   title = l(:label_issue_added)
    #   content = l(:text_issue_added, :id => "##{issue.id}", :author => issue.author)
    #   issueUrl = redmine_url(:controller => 'issues', :action => 'show', :id => issue)
    #   send_rtx(issue, title, content, issueUrl)
    # end
    
    def controller_issues_edit_after_save(context={})
      return unless RedmineMessenger.settings[:messenger_url]
      issue = context[:issue]
      DingTalkMessenger.speak(issue, RedmineMessenger.settings[:messenger_url])
    end
  end
end
