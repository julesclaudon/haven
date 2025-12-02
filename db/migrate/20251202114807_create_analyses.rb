class CreateAnalyses < ActiveRecord::Migration[7.1]
  def change
    create_table :analyses do |t|
      t.references :state, null: false, foreign_key: true
      t.text :resume
      t.integer :score

      t.timestamps
    end
  end
end
