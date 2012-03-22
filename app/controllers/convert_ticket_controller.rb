class ConvertTicketController < ApplicationController
  unloadable

  before_filter :find_otrs_ticket, :only => [:select_project, :update_existing_issue]
  before_filter :find_otrs_custom_field, :only => [:select_project, :update_existing_issue]
  before_filter :find_ticket_type_custom_field, :only => [:select_project, :update_existing_issue]
  before_filter :find_issue, :only => [:update_existing_issue]

  def select_project
    @projects = Project.visible.sort_by { |p| p.name.downcase }
    @issue = Issue.new
    @issue.subject = @otrsTicket.otrs_ticket_title
    @issue.description = @otrsTicket.otrs_ticket_body
  end

private

  def find_otrs_ticket
    @otrsTicket = OtrsToChiliOtrsTicket.find(params[:id])
    render_403 unless @otrsTicket.owner == User.current.id
  rescue ActiveRecord::RecordNotFound
    render_404 :message => "Stored data with id '#{params[:id]}' not found"
  end

  def find_otrs_custom_field
    customFieldName = Setting.plugin_chiliproject_otrs2_chili['otrs_links_custom_field']
    @otrsField = CustomField.find(:first, :conditions => ["name=?", customFieldName])
  rescue ActiveRecord::RecordNotFound
    render_404 :message => "Custom Field '#{customFieldName}' not found"
  end

  def find_ticket_type_custom_field
    customFieldName = Setting.plugin_chiliproject_otrs2_chili['ticket_type_custom_field']
    @ticketTypeField = CustomField.find(:first, :conditions => ["name=?", customFieldName])
    @ticket_type_value = Setting.plugin_chiliproject_otrs2_chili['ticket_type_value']
  rescue ActiveRecord::RecordNotFound
    render_404 :message => "Custom Field '#{customFieldName}' not found"
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404 :message => "Issue '#{params[:issue_id]}' not found"
  end

end
