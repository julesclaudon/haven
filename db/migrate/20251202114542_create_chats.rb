class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.references :state, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
