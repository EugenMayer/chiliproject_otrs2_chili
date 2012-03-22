class OtrsTicketController < ApplicationController
  unloadable

  after_filter :allow_otrs_origin

  accept_key_auth :store_otrs_ticket, :get_chili_ticket_id, :destroy
  # use POST instead of DELETE to destroy temp data as this is easier to handle for cross-origin scripts
  verify :method => :post, :only => :destroy, :render => {:nothing => true, :status => :method_not_allowed }
  verify :method => :post, :only => :store_otrs_ticket, :render => {:nothing => true, :status => :method_not_allowed }
  verify :method => :get, :only => :get_chili_ticket_id, :render => {:nothing => true, :status => :method_not_allowed }


  def allow_otrs_origin
    headers['Access-Control-Allow-Origin'] = Setting.plugin_chiliproject_otrs2_chili['cors_allowed_origin']
  end


  def store_otrs_ticket
    otrsTicket = OtrsToChiliOtrsTicket.new
    otrsTicket.otrs_ticket_id = params[:otrs_ticket_id]
    otrsTicket.otrs_ticket_body = params[:otrs_ticket_body]
    otrsTicket.otrs_ticket_title = params[:otrs_ticket_title]
    otrsTicket.owner = User.current.id
    begin
      render :text => otrsTicket.save ? otrsTicket.id.to_s :  "-1"
    rescue
      render :text => "-2"
    end
  end

  def get_chili_ticket_id
    begin
      otrsTicket = OtrsToChiliOtrsTicket.find(params[:id])
      return head(:unauthorized) unless otrsTicket.owner == User.current.id
      render :text => otrsTicket.chili_ticket_id.nil? ? "-1" : otrsTicket.chili_ticket_id.to_s
    rescue ActiveRecord::RecordNotFound
      render :text => "-1"
    end
  end

  def destroy
    begin
      OtrsToChiliOtrsTicket.find(params[:id]).destroy
      destroy_all_timed_out_entries()
    rescue ActiveRecord::RecordNotFound
     # nothing to do, data was already deleted
    end
    render :nothing => true
  end

  private

  def destroy_all_timed_out_entries
    OtrsToChiliOtrsTicket.find(:all, :conditions => ['created_at < ?', 2.hours.ago]).each do |entry|
      entry.destroy
    end
  end

end
