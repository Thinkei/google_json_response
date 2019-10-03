$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "google_json_response"
require 'active_model'
require 'active_record'
require 'active_model_serializers'
require 'sequel'
require 'database_cleaner'
require 'byebug'

#Active record test data
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/support/schema.rb'
require File.dirname(__FILE__) + '/support/models.rb'
require File.dirname(__FILE__) + '/support/serializers.rb'
require File.dirname(__FILE__) + '/support/custom_errors.rb'

#Sequel test data
SequelDB = Sequel.sqlite # memory database, requires sqlite3
SequelDB.extension(:pagination)
require 'sequel/plugins/serialization'
require 'json'

SequelDB.create_table :items do
  primary_key :id
  String :name
  String :code
end

class Item < Sequel::Model(SequelDB[:items])
  def read_attribute_for_serialization(name)
    self.values[name]
  end
end

class ItemSerializer < ActiveModel::Serializer
  attributes :code, :name
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
