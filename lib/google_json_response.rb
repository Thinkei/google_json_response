require "google_json_response/version"
require "google_json_response/parse_hash"
require "google_json_response/error_parsers"

module GoogleJsonResponse
  class << self
    def render(data, options = {})
      if is_error?(data) || is_errors?(data)
        if !defined?(GoogleJsonResponse::ErrorParsers)
          raise "Please require google_json_response/error_parsers"\
                " to render errors"
        end
        return ErrorParsers.parse(data, options)
      end

      if is_active_record_object?(data) || is_active_record_objects?(data)
        if !defined?(GoogleJsonResponse::RecordParsers::ParseActiveRecords)
          raise "Please require google_json_response/active_records"\
                " to render active records"
        end
        parser = GoogleJsonResponse::RecordParsers::ParseActiveRecords.new(data, options)
        parser.call
        return parser.parsed_data
      end

      if is_sequel_record_object?(data) || is_sequel_record_objects?(data)
        if !defined?(GoogleJsonResponse::RecordParsers::ParseSequelRecords)
          raise "Please require google_json_response/sequel_records"\
                " to render sequel records"
        end
        parser = GoogleJsonResponse::RecordParsers::ParseSequelRecords.new(data, options)
        parser.call
        return parser.parsed_data
      end

      if data.is_a?(Hash)
        parser = ParseHash.new(data, options)
        parser.call
        return parser.parsed_data
      end
    end

    def render_error(data, options = {})
      if data.is_a?(String)
        render_generic_error(data, options[:code])
      else
        render(data, options)
      end
    end

    def render_record(data, options = {})
      render(data, options)
    end

    def render_records(data, options = {})
      render(data, options)
    end


    private

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

    def is_error?(data)
      return true if data.is_a?(StandardError)
      return true if defined?(::ActiveModel::Errors) && data.is_a?(::ActiveModel::Errors)
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
      return false if !defined?(::ActiveRecord::Base) || !defined?(::ActiveRecord::Relation)
      return data.is_a?(::ActiveRecord::Base) || data.is_a?(::ActiveRecord::Relation)
    end

    def is_sequel_record_objects?(data)
      return false if !data.is_a?(::Array)
      return is_sequel_record_object?(data[0])
    end

    def is_sequel_record_object?(data)
      return false if !defined?(::Sequel::Model) || !defined?(::Sequel::Dataset)
      return data.is_a?(::Sequel::Model) || data.is_a?(::Sequel::Dataset)
    end
  end
end
