class CreateInitialQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :initial_quizzes do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :age
      t.date :relation_end_date
      t.integer :relation_duration
      t.integer :pain_level
      t.string :breakup_type
      t.string :breakup_initiator
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
