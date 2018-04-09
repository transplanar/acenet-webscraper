class CreateDriverTesters < ActiveRecord::Migration
  def change
    create_table :driver_testers do |t|

      t.timestamps null: false
    end
  end
end
