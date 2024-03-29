class CreateCheckPayments < ActiveRecord::Migration
  def change
    create_table :check_payments do |t|
      t.string :check_number
      t.decimal :total, default: 0.00, precision: 10, scale: 2
      t.integer :estimate_id

      t.timestamps
    end
  end
end
