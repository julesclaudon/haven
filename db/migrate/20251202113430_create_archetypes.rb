class CreateArchetypes < ActiveRecord::Migration[7.1]
  def change
    create_table :archetypes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :archetype_name
      t.text :archetype_desc

      t.timestamps
    end
  end
end
