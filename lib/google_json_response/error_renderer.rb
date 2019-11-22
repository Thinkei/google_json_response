require "google_json_response/error_parsers/parse_generic_error"
require "google_json_response/error_parsers/parse_standard_error"

module GoogleJsonResponse
  class ErrorRenderer
    attr_reader :errors, :options, :rendered_content


    def initialize(errors, options = {})
      @errors = errors
      @options = options
    end

    def call
      unless errors.is_a?(::Array)
        parser = create_parser(errors)
        parser.call
        @rendered_content = parser.parsed_data
      else
        @rendered_content = parse_error_array(errors)
      end
    end

    private

    attr_reader :errors

    def parse_error_array(errors)
      temp_parsed_data = {
        error: {
          errors: []
        }
      }
      errors.each do |e|
        parser = create_parser(e)
        parser.call
        next if parser.parsed_data.blank?
        temp_parsed_data[:error][:errors].push(*parser.parsed_data[:error][:errors])
      end
      temp_parsed_data[:error][:code] = options[:code] if options[:code]
      temp_parsed_data
    end

    def create_parser(input_errors)
      if standard_error?(input_errors)
        GoogleJsonResponse::ErrorParsers::ParseStandardError.new(input_errors, options)
      elsif active_model_error?(input_errors)
        GoogleJsonResponse::ErrorParsers::ParseActiveRecordError.new(input_errors, options)
      else
        GoogleJsonResponse::ErrorParsers::ParseGenericError.new(input_errors, options)
      end
    end

    def standard_error?(input_errors)
      return true if input_errors.is_a?(StandardError)
      false
    end

    def active_model_error?(input_errors)
      return false unless defined?(::ActiveModel::Errors)
      input_errors.is_a?(::ActiveModel::Errors)
    end

    def generic_error?(input_errors)
      input_errors.is_a?(::String) || input_errors.is_a?(::Array)
    end
  end
end
