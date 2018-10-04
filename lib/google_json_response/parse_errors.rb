require "google_json_response/error_parsers/parse_standard_error"
require "google_json_response/error_parsers/parse_active_model_error"

module GoogleJsonResponse
  class ParseErrors
    attr_reader :parsed_data
    DEFAULT_ERROR_CODE = 'error'

    def initialize(data, options = {})
      @options = options
      @code = @options[:code]
      @data = data
      @errors = []
    end

    def call
      if @data.is_a?(::Array)
        @parsed_data = parse_error_array(@data)
      else
        @parsed_data = parse_error(@data)
      end
    end

    private

    def parse_error_array(errors)
      temp_parsed_data = {
        error: {
          code: @code.to_s,
          errors: []
        }
      }
      errors.each do |e| 
        parsed_e = parse_error(e)
        next if parsed_e.blank?
        temp_parsed_data[:error][:errors].push(*parsed_e[:error][:errors])
      end
      temp_parsed_data
    end

    def parse_error(error)
      if is_a_standard_error?(error)
        parseStandardError(error)
      else is_an_active_model_error?(error)
        parse_active_model_error(error)
      end
    end

    def parse_active_model_error(error)
      parser = GoogleJsonResponse::ErrorParsers::ParseActiveModelError.new(error, code: @code.to_s)
      parser.call
      parser.parsed_data
    end


    def parseStandardError(error)
      parser = GoogleJsonResponse::ErrorParsers::ParseStandardError.new(error, code: @code.to_s)
      parser.call
      parser.parsed_data
    end

    def is_a_standard_error?(error)
      return true if error.is_a?(StandardError)
      false
    end

    def is_an_active_model_error?(error)
      return true if error.is_a?(::ActiveModel::Errors)
      false
    end
  end
end
