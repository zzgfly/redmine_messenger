# Redmine Messenger plugin for Redmine
require 'net/http'

class Messenger
  include Redmine::I18n

  def self.speak(msg, channels, attachment = nil, url = nil)
    url = RedmineMessenger.settings[:messenger_url] unless url
    icon = RedmineMessenger.settings[:messenger_icon]

    return if url.blank?
    return if channels.blank?

    params = {
      text: msg,
      link_names: 1
    }

    if RedmineMessenger.settings[:messenger_username].present?
      params[:username] = RedmineMessenger.settings[:messenger_username]
    end
    params[:attachments] = [attachment] if attachment && attachment.any?

    if icon.present?
      if icon.start_with? ':'
        params[:icon_emoji] = icon
      else
        params[:icon_url] = icon
      end
    end

    channels.each do |channel|
      uri = URI(url)
      params[:channel] = channel

      http_options = { use_ssl: uri.scheme == 'https' }
      if RedmineMessenger.settings[:messenger_verify_ssl] != 1
        http_options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      begin
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(payload: params.to_json)
        Net::HTTP.start(uri.hostname, uri.port, http_options) do |http|
          response = http.request(req)
          unless response == Net::HTTPSuccess || response == Net::HTTPRedirection
            Rails.logger.warn(response)
          end
        end
      rescue StandardError => e
        Rails.logger.warn("cannot connect to #{url}")
        Rails.logger.warn(e)
      end
    end
  end

  def self.object_url(obj)
    if Setting.host_name.to_s =~ %r{/\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i}
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

    cf = ProjectCustomField.find_by(name: 'Messenger Post private issues')
    [
      (proj.custom_value_for(cf).value rescue nil),
      (post_private_issues_for_project proj.parent),
      RedmineMessenger.settings[:post_private_issues]
    ].flatten.find(&:present?)
  end

  def self.post_private_notes_for_project(proj)
    return nil if proj.blank?

    cf = ProjectCustomField.find_by(name: 'Messenger Post private notes')
    [
      (proj.custom_value_for(cf).value rescue nil),
      (post_private_notes_for_project proj.parent),
      RedmineMessenger.settings[:post_private_notes]
    ].flatten.find(&:present?)
  end

  def self.channels_for_project(proj)
    return if proj.blank?

    cf = ProjectCustomField.find_by(name: 'Messenger Channel')
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
    key = nil
    escape = true

    if detail.property == 'cf'
      key = CustomField.find(detail.prop_key).name rescue nil
      title = key
      field_format = CustomField.find(detail.prop_key).field_format rescue nil
    elsif detail.property == 'attachment'
      key = 'attachment'
      title = I18n.t :label_attachment
    else
      key = detail.prop_key.to_s.sub('_id', '')
      title = if key == 'parent'
                I18n.t "field_#{key}_issue"
              else
                I18n.t "field_#{key}"
              end
    end

    short = true
    value = detail.value.to_s

    case key
    when 'title', 'subject', 'description'
      short = false
    when 'tracker'
      tracker = Tracker.find(detail.value)
      value = tracker.to_s if tracker.present?
    when 'project'
      project = Project.find(detail.value)
      value = project.to_s if project.present?
    when 'status'
      status = IssueStatus.find(detail.value)
      value = status.to_s if status.present?
    when 'priority'
      priority = IssuePriority.find(detail.value)
      value = priority.to_s if priority.present?
    when 'category'
      category = IssueCategory.find(detail.value)
      value = category.to_s if category.present?
    when 'assigned_to'
      user = User.find(detail.value)
      value = user.to_s if user.present?
    when 'fixed_version'
      fixed_version = Version.find(detail.value)
      value = fixed_version.to_s if fixed_version.present?
    when 'attachment'
      attachment = Attachment.find(detail.prop_key)
      value = "<#{Messenger.object_url attachment}|#{ERB::Util.html_escape(attachment.filename)}>" if attachment.present?
      escape = false
    when 'parent'
      issue = Issue.find(detail.value)
      value = "<#{Messenger.object_url issue}|#{ERB::Util.html_escape(issue)}>" if issue.present?
      escape = false
    end

    if detail.property == 'cf' && field_format == 'version'
      version = Version.find(detail.value)
      value = version.to_s if version.present?
    end

    value = if value.present?
              if escape
                ERB::Util.html_escape(value)
              else
                value
              end
            else
              '-'
            end

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
