# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_29_213045) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aircraft_families", id: :serial, force: :cascade do |t|
    t.string "family_name"
    t.string "iata_aircraft_code"
    t.string "manufacturer"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icao_aircraft_code"
    t.integer "parent_id"
    t.string "slug"
    t.index ["slug"], name: "index_aircraft_families_on_slug", unique: true
  end

  create_table "airlines", id: :serial, force: :cascade do |t|
    t.string "iata_airline_code", null: false
    t.string "airline_name", null: false
    t.boolean "is_only_operator"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "numeric_code"
    t.string "icao_airline_code"
    t.string "slug"
    t.index ["slug"], name: "index_airlines_on_slug", unique: true
  end

  create_table "airports", id: :serial, force: :cascade do |t|
    t.string "iata_code"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.string "icao_code"
    t.float "latitude"
    t.float "longitude"
    t.string "slug"
    t.index ["slug"], name: "index_airports_on_slug", unique: true
  end

  create_table "flights", id: :serial, force: :cascade do |t|
    t.integer "origin_airport_id"
    t.integer "destination_airport_id"
    t.integer "trip_id"
    t.date "departure_date"
    t.string "flight_number"
    t.string "tail_number"
    t.string "travel_class"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "trip_section"
    t.datetime "departure_utc"
    t.string "codeshare_flight_number"
    t.string "fleet_number"
    t.string "aircraft_name"
    t.integer "airline_id"
    t.integer "operator_id"
    t.integer "codeshare_airline_id"
    t.text "boarding_pass_data"
    t.integer "aircraft_family_id"
  end

  create_table "pk_passes", id: :serial, force: :cascade do |t|
    t.string "serial_number"
    t.text "pass_json"
    t.datetime "received"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "flight_id"
  end

  create_table "routes", id: :serial, force: :cascade do |t|
    t.integer "airport1_id"
    t.integer "airport2_id"
    t.integer "distance_mi"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trips", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "hidden"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "purpose"
    t.integer "user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_token"
    t.string "email"
    t.string "alternate_email"
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

end
