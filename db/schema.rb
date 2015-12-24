# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151224195816) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "airports", force: :cascade do |t|
    t.string   "iata_code"
    t.string   "city"
    t.boolean  "region_conus"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "country"
  end

  add_index "airports", ["iata_code"], name: "index_airports_on_iata_code", unique: true, using: :btree

  create_table "flights", force: :cascade do |t|
    t.integer  "origin_airport_id"
    t.integer  "destination_airport_id"
    t.integer  "trip_id"
    t.date     "departure_date"
    t.string   "airline"
    t.integer  "flight_number"
    t.string   "aircraft_family"
    t.string   "aircraft_variant"
    t.string   "tail_number"
    t.string   "travel_class"
    t.text     "comment"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "trip_section"
    t.datetime "departure_utc"
    t.string   "codeshare_airline"
    t.integer  "codeshare_flight_number"
    t.string   "operator"
    t.string   "fleet_number"
    t.string   "aircraft_name"
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
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "password_digest"
    t.string   "remember_token"
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree

end
