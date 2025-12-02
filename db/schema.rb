# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_02_114807) do
  create_table "analyses", force: :cascade do |t|
    t.integer "state_id", null: false
    t.text "resume"
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_analyses_on_state_id"
  end

  create_table "archetypes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "archetype_name"
    t.text "archetype_desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_archetypes_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.integer "state_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_chats_on_state_id"
  end

  create_table "grief_stages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "initial_quizzes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "age"
    t.date "relation_end_date"
    t.integer "relation_duration"
    t.integer "pain_level"
    t.string "breakup_type"
    t.string "breakup_initiator"
    t.string "emotion_label"
    t.text "main_sentiment"
    t.string "ex_contact_frequency"
    t.boolean "considered_reunion"
    t.string "ruminating_frequency"
    t.string "sleep_quality"
    t.text "habits_changed"
    t.string "support_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_initial_quizzes_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.string "role"
    t.text "content"
    t.string "message_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "chat_id", null: false
    t.integer "grief_stage_id", null: false
    t.integer "pain_level"
    t.text "raw_input"
    t.string "trigger_source"
    t.string "time_of_day"
    t.string "drugs"
    t.string "emotion_label"
    t.text "main_sentiment"
    t.string "ex_contact_frequency"
    t.boolean "considered_reunion"
    t.string "ruminating_frequency"
    t.string "sleep_quality"
    t.text "habits_changed"
    t.string "support_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_states_on_chat_id"
    t.index ["grief_stage_id"], name: "index_states_on_grief_stage_id"
    t.index ["user_id"], name: "index_states_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "analyses", "states"
  add_foreign_key "archetypes", "users"
  add_foreign_key "chats", "states"
  add_foreign_key "initial_quizzes", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "states", "chats"
  add_foreign_key "states", "grief_stages"
  add_foreign_key "states", "users"
end
