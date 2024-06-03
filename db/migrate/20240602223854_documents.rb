class Documents < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :url
      t.string :security_password
      t.string :message
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
