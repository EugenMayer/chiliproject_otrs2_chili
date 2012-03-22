class OTRS2ChiliHooks < Redmine::Hook::Listener
  def controller_issues_new_after_save(context={ })
    issue = context[:issue]
    if dereference_all_otrs_ids(issue)
      issue.save
    end
  end

  def controller_issues_edit_after_save(context={ })
    issue = context[:issue]
    if dereference_all_otrs_ids(issue)
      issue.save
    end
  end

  private

  def dereference_all_otrs_ids(issue)
    begin
      otrs_field = CustomField.find(:first, :conditions => ["name=?", Setting.plugin_chiliproject_otrs2_chili['otrs_links_custom_field']])
    rescue ActiveRecord::RecordNotFound
      return false
    end
    # not sure why but ist is done like this in Issue.copy_from and doesn't work otherwise
    custom_field_hash = issue.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value; h }
    otrs_id_values = custom_field_hash[otrs_field.id]
    return false if otrs_id_values.nil?
    chili_id = issue.id
    otrs_ids = otrs_id_values.split(",")
    dereferenced_otrs_ids = otrs_ids.map { |id| dereference_otrs_id_and_set_backreference(id, chili_id) }
    if dereferenced_otrs_ids != otrs_ids
      issue.custom_field_values = {otrs_field.id => dereferenced_otrs_ids.join(",")}
      return true
    end
    false
  end

  def dereference_otrs_id_and_set_backreference(id, chili_id)
    return id unless id =~ /ref:(\d+)/
    begin
      otrsTicket = OtrsToChiliOtrsTicket.find($1)
      return id unless otrsTicket.owner == User.current.id
    rescue ActiveRecord::RecordNotFound
      return id
    end
    otrsTicket.chili_ticket_id = chili_id
    return id unless otrsTicket.save
    return otrsTicket.otrs_ticket_id
  end

end
