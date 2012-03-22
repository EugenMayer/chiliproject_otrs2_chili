class CreateOtrsToChiliOtrsTickets < ActiveRecord::Migration
  def self.up
    create_table :otrs_to_chili_otrs_tickets do |t|
      t.column :id, :primary_key
      t.column :created_at, :datetime
      t.column :otrs_ticket_id, :integer, :null => false
      t.column :otrs_ticket_body, :text
      t.column :otrs_ticket_title, :string
      t.column :chili_ticket_id, :integer
      t.column :owner, :integer, :null => false
    end
  end

  def self.down
    drop_table :otrs_to_chili_otrs_tickets
  end
end
