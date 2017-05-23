# Redmine Messenger plugin for Redmine

class MessengerSettingsController < ApplicationController
  layout 'base'

  before_action :find_project, :authorize, :find_user

  def save
    setting = MessengerSetting.find_or_create @project.id
    begin
      setting.transaction do
        # setting.auto_preview_enabled = auto_preview_enabled
        setting.assign_attributes(params[:setting])
        setting.save!
      end
      flash[:notice] = l(:notice_successful_update)
    rescue => e
      flash[:error] = 'Updating failed.' + e.message
    end

    redirect_to controller: 'projects', action: 'settings', id: @project, tab: 'messenger'
  end

  private

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = User.current
  end
end
