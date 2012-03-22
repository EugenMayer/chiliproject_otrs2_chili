class OtrsToChiliOtrsTicket < ActiveRecord::Base
  unloadable

  before_create :set_created_at_to_now
  def set_created_at_to_now
    self.created_at = Time.now
  end

end
