require "google_json_response/version"
require "google_json_response/error_parsers"
require "google_json_response/record_parsers/parse_hash_records"

module GoogleJsonResponse
  class << self
    def render(data, options = {})
      if is_error?(data) || is_errors?(data)
        unless defined?(GoogleJsonResponse::ErrorParsers)
          raise "Please require google_json_response/error_parsers"\
                " to render errors"
        end
        return ErrorParsers.parse(data, options)
      end

      parser =
        if is_active_record_object?(data) || is_active_record_objects?(data)
          unless defined?(GoogleJsonResponse::RecordParsers::ParseActiveRecords)
            raise "Please require google_json_response/active_records"\
                " to render active records"
          end
          GoogleJsonResponse::RecordParsers::ParseActiveRecords.new(data, options)
        elsif is_sequel_record_object?(data) || is_sequel_record_objects?(data)
          unless defined?(GoogleJsonResponse::RecordParsers::ParseSequelRecords)
            raise "Please require google_json_response/sequel_records"\
                " to render sequel records"
          end
          GoogleJsonResponse::RecordParsers::ParseSequelRecords.new(data, options)
        else
          GoogleJsonResponse::RecordParsers::ParseHashRecords.new(data, options)
        end

      parser.call
      parser.parsed_data
    end

    def render_error(data, options = {})
      return render_generic_error(data, options[:code]) if data.is_a?(String)
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
      return false unless data.is_a?(::Array)
      is_error?(data[0])
    end

    def is_active_record_objects?(data)
      return false unless data.is_a?(::Array)
      is_active_record_object?(data[0])
    end

    def is_active_record_object?(data)
      return false if !defined?(::ActiveRecord::Base) || !defined?(::ActiveRecord::Relation)
      data.is_a?(::ActiveRecord::Base) || data.is_a?(::ActiveRecord::Relation)
    end

    def is_sequel_record_objects?(data)
      return false unless data.is_a?(::Array)
      is_sequel_record_object?(data[0])
    end

    def is_sequel_record_object?(data)
      return false if !defined?(::Sequel::Model) || !defined?(::Sequel::Dataset)
      data.is_a?(::Sequel::Model) || data.is_a?(::Sequel::Dataset)
    end
  end
end
