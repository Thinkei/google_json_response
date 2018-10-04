require "google_json_response/version"
require "google_json_response/parse_active_records"
require "google_json_response/parse_errors"
require "google_json_response/parse_hash"
require 'active_model'
require 'active_record'

module GoogleJsonResponse
  class << self
    def parse(data, options = {})
      if is_error?(data) || is_errors?(data)
        parser = ParseErrors.new(data, options)
        parser.call
        return parser.parsed_data
      end

      if is_active_record_object?(data) || is_active_record_objects?(data)
        parser = ParseActiveRecords.new(data, options)
        parser.call
        return parser.parsed_data
      end

      if data.is_a?(Hash)
        parser = ParseHash.new(data, options)
        parser.call
        return parser.parsed_data
      end
    end

    def render_generic_error(message, status = '400')
      {
        error: {
          code: status,
          errors: [
            {
              reason: 'error',
              message: message
            }
          ]
        }
      }
    end

    private

    def is_error?(data)
      return true if data.is_a?(StandardError)
      return true if data.is_a?(::ActiveModel::Errors)
      false
    end

    def is_errors?(data)
      return false if !data.is_a?(::Array)
      return is_error?(data[0])
    end

    def is_active_record_objects?(data)
      return false if !data.is_a?(::Array)
      return is_active_record_object?(data[0])
    end

    def is_active_record_object?(data)
      return data.is_a?(::ActiveRecord::Base) || data.is_a?(::ActiveRecord::Relation)
    end
  end
end
