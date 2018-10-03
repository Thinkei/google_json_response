$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "google_json_response"
require 'active_record'
require 'active_model_serializers'
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/support/schema.rb'
require File.dirname(__FILE__) + '/support/models.rb'
require File.dirname(__FILE__) + '/support/serializers.rb'
require File.dirname(__FILE__) + '/support/custom_errors.rb'
