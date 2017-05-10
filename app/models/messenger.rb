# Redmine Messenger plugin for Redmine
require 'httpclient'

class Messenger
  include Redmine::I18n

  def self.speak(msg, channels, attachment = nil, url = nil)
    return if channels.blank?

    url = RedmineMessenger.settings[:messenger_url] unless url
    username = RedmineMessenger.settings[:messenger_username]
    icon = RedmineMessenger.settings[:messenger_icon]

    params = {
      text: msg,
      link_names: 1
    }

    params[:username] = username if username
    params[:attachments] = [attachment] if attachment

    if icon.present?
      if icon.start_with? ':'
        params[:icon_emoji] = icon
      else
        params[:icon_url] = icon
      end
    end

    channels.each do |channel|
      params[:channel] = channel

      begin
        client = HTTPClient.new
        client.ssl_config.cert_store.set_default_paths
        client.ssl_config.ssl_version = :auto
        client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        client.post_async url, payload: params.to_json
      rescue Exception => e
        Rails.logger.warn("cannot connect to #{url}")
        Rails.logger.warn(e)
      end
    end
  end

  def self.object_url(obj)
    if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
      host = Regexp.last_match(2)
      port = Regexp.last_match(4)
      prefix = Regexp.last_match(5)
      Rails.application.routes.url_for(obj.event_url(host: host, protocol: Setting.protocol, port: port, script_name: prefix))
    else
      Rails.application.routes.url_for(obj.event_url(host: Setting.host_name, protocol: Setting.protocol))
    end
  end

  def self.url_for_project(proj)
    return nil if proj.blank?

    cf = ProjectCustomField.find_by(name: 'Messenger URL')

    [
      (proj.custom_value_for(cf).value rescue nil),
      (url_for_project proj.parent),
      RedmineMessenger.settings[:messenger_url]
    ].flatten.find(&:present?)
  end

  def self.post_private_issues_for_project(proj)
    return nil if proj.blank?

    cf = ProjectCustomField.find_by_name('Messenger Post private issues')
    [
      (proj.custom_value_for(cf).value rescue nil),
      (post_private_issues_for_project proj.parent),
      RedmineMessenger.settings[:post_private_issues]
    ].flatten.find(&:present?)
  end

  def self.post_private_notes_for_project(proj)
    return nil if proj.blank?

    cf = ProjectCustomField.find_by_name('Messenger Post private notes')
    [
      (proj.custom_value_for(cf).value rescue nil),
      (post_private_notes_for_project proj.parent),
      RedmineMessenger.settings[:post_private_notes]
    ].flatten.find(&:present?)
  end

  def self.channels_for_project(proj)
    return nil if proj.blank?

    cf = ProjectCustomField.find_by_name('Messenger Channel')
    val = [
      (proj.custom_value_for(cf).value rescue nil),
      (channels_for_project proj.parent),
      RedmineMessenger.settings[:messenger_channel]
    ].flatten.find(&:present?)

    # Channel name '-' or empty '' is reserved for NOT notifying
    return [] if val.nil? || val.to_s == ''
    return [] if val.to_s == '-'
    return val.split(',') if val.is_a? String
    val
  end

  def self.detail_to_field(detail)
    field_format = nil

    if detail.property == 'cf'
      key = CustomField.find(detail.prop_key).name rescue nil
      title = key
      field_format = CustomField.find(detail.prop_key).field_format rescue nil
    elsif detail.property == 'attachment'
      key = 'attachment'
      title = I18n.t :label_attachment
    else
      key = detail.prop_key.to_s.sub('_id', '')
      title = I18n.t "field_#{key}"
    end

    short = true
    value = ERB::Util.html_escape(detail.value.to_s)

    case key
    when 'title', 'subject', 'description'
      short = false
    when 'tracker'
      tracker = Tracker.find(detail.value) rescue nil
      value = ERB::Util.html_escape(tracker.to_s)
    when 'project'
      project = Project.find(detail.value) rescue nil
      value = ERB::Util.html_escape(project.to_s)
    when 'status'
      status = IssueStatus.find(detail.value) rescue nil
      value = ERB::Util.html_escape(status.to_s)
    when 'priority'
      priority = IssuePriority.find(detail.value) rescue nil
      value = ERB::Util.html_escape(priority.to_s)
    when 'category'
      category = IssueCategory.find(detail.value) rescue nil
      value = ERB::Util.html_escape(category.to_s)
    when 'assigned_to'
      user = User.find(detail.value) rescue nil
      value = ERB::Util.html_escape(user.to_s)
    when 'fixed_version'
      version = Version.find(detail.value) rescue nil
      value = ERB::Util.html_escape(version.to_s)
    when 'attachment'
      attachment = Attachment.find(detail.prop_key) rescue nil
      value = "<#{Messenger.object_url attachment}|#{ERB::Util.html_escape(attachment.filename)}>" if attachment
    when 'parent'
      issue = Issue.find(detail.value) rescue nil
      value = "<#{Messenger.object_url issue}|#{ERB::Util.html_escape(issue)}>" if issue
    end

    case field_format
    when 'version'
      version = Version.find(detail.value) rescue nil
      value = ERB::Util.html_escape(version.to_s)
    end

    value = '-' if value.empty?

    result = { title: title, value: value }
    result[:short] = true if short
    result
  end

  def self.mentions(text)
    return nil if text.nil?
    names = extract_usernames(text)
    names.present? ? '\nTo: ' + names.join(', ') : nil
  end

  def self.extract_usernames(text)
    text = '' if text.nil?
    # messenger usernames may only contain lowercase letters, numbers,
    # dashes, dots and underscores and must start with a letter or number.
    text.scan(/@[a-z0-9][a-z0-9_\-.]*/).uniq
  end
end
