class CreateStates < ActiveRecord::Migration[7.1]
  def change
    create_table :states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.references :grief_stage, null: false, foreign_key: true
      t.integer :pain_level
      t.text :raw_input
      t.string :trigger_source
      t.string :time_of_day
      t.string :drugs
      t.string :emotion_label
      t.text :main_sentiment
      t.string :ex_contact_frequency
      t.boolean :considered_reunion
      t.string :ruminating_frequency
      t.string :sleep_quality
      t.text :habits_changed
      t.string :support_level

      t.timestamps
    end
  end
end
