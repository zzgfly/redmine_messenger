# Redmine Messenger plugin for Redmine
require 'net/http'
require 'rails' 
require 'uri'  
require 'json'  
require "erb"
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
      speak(issue, RedmineMessenger.settings[:messenger_url])
    end

    def speak(issue, url)
      # url ||= RedmineMessenger.settings[:messenger_url]
       url = "https://oapi.dingtalk.com/robot/send?access_token=3cc8750c7d5cb6d883d1d4f1406ea9dfc04273aa87ec9e7baf93e7baa1f0e5fe"
       

       
       params = {
           :msgtype=>"markdown",
           :at=> {
             :atMobiles=>["18600369206"],
             :isAtAll=>false
           },
           :markdown=>{
             :title=>"##{issue.id} Assigned to: #{ERB::Util.html_escape(issue.assigned_to.to_s)}",
             :text=>"# ##{issue.id} #{ERB::Util.html_escape(issue.subject)}\n- Project: **#{ERB::Util.html_escape(issue.project)}**\n- Author: **#{ERB::Util.html_escape(issue.author)}**\n- Assigned to: **#{ERB::Util.html_escape(issue.assigned_to.to_s)}**\n- Status: **#{ERB::Util.html_escape(issue.status.to_s)}**\n# [查看详情](http://oa.188yd.com:3000/issues/#{issue.id})\n@18600369206"
           }
         }

       #   params = {
       #     "msgtype": "actionCard",
       #     "at": {
       #       "atMobiles": ["18600369206"],
       #       "isAtAll": false
       #     },
       #     "actionCard": {
       #       "title": "##{issue.id} Assigned to: #{ERB::Util.html_escape(issue.assigned_to.to_s)}",
       #         #   "text": "# #{escape issue.title}]\n- Repo: **[mymall](http://git.188yd.com:8000/zhenzhigang/mymall)**\n- New Tag: **[1711.3.8](http://git.188yd.com:8000/zhenzhigang/mymall/src/1711.3.8)**",
       #       "text": "# @18600369206 ##{issue.id} #{ERB::Util.html_escape(issue.title)}\n- Project: **#{ERB::Util.html_escape(issue.project)}**\n- Author: **#{ERB::Util.html_escape(issue.author)}**\n- Assigned to: **#{ERB::Util.html_escape(issue.assigned_to.to_s)}**\n- Status: **#{ERB::Util.html_escape(issue.status.to_s)}**",
       #       "hideAvatar": "0", 
       #       "btnOrientation": "0", 
       #       "singleTitle": "查看",
       #       "singleURL": "http://oa.188yd.com:3000/issues/#{issue.id}"
       #     }
       #   }
       uri = URI(url)
       http_options = { 
           use_ssl: uri.scheme == 'https',
           verify_mode:OpenSSL::SSL::VERIFY_NONE
       }
       begin
           req = Net::HTTP::Post.new(uri,{'Content-Type' => 'application/json'})
           payload = params.to_json
           puts "payload:"
           puts payload
           # req.set_form_data(payload: payload)
           req.body = payload
           Net::HTTP.start(uri.hostname, uri.port, http_options) do |http|
           response = http.request(req)
           unless [Net::HTTPSuccess, Net::HTTPRedirection, Net::HTTPOK].include? response
               #Rails.logger.warn(response)
               puts response.body
           end
           end
       rescue StandardError => e
           #Rails.logger.warn("cannot connect to #{url}")
           #Rails.logger.warn(e)
           puts "err:"
           puts e
       end
   end




  end
end
