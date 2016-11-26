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

ActiveRecord::Schema.define(version: 20161118234442) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aircraft_families", force: :cascade do |t|
    t.string   "family_name"
    t.string   "iata_aircraft_code"
    t.string   "manufacturer"
    t.string   "category"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "airlines", force: :cascade do |t|
    t.string   "iata_airline_code", null: false
    t.string   "airline_name",      null: false
    t.boolean  "is_only_operator"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "airports", force: :cascade do |t|
    t.string   "iata_code"
    t.string   "city"
    t.boolean  "region_conus"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "country"
    t.index ["iata_code"], name: "index_airports_on_iata_code", unique: true, using: :btree
  end

  create_table "flights", force: :cascade do |t|
    t.integer  "origin_airport_id"
    t.integer  "destination_airport_id"
    t.integer  "trip_id"
    t.date     "departure_date"
    t.integer  "flight_number"
    t.string   "aircraft_variant"
    t.string   "tail_number"
    t.string   "travel_class"
    t.text     "comment"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "trip_section"
    t.datetime "departure_utc"
    t.integer  "codeshare_flight_number"
    t.string   "fleet_number"
    t.string   "aircraft_name"
    t.integer  "airline_id"
    t.integer  "operator_id"
    t.integer  "codeshare_airline_id"
    t.text     "boarding_pass_data"
    t.integer  "aircraft_family_id"
  end

  create_table "routes", force: :cascade do |t|
    t.integer  "airport1_id"
    t.integer  "airport2_id"
    t.integer  "distance_mi"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "trips", force: :cascade do |t|
    t.string   "name"
    t.boolean  "hidden"
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "purpose"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "password_digest"
    t.string   "remember_token"
    t.index ["name"], name: "index_users_on_name", unique: true, using: :btree
    t.index ["remember_token"], name: "index_users_on_remember_token", using: :btree
  end

end
