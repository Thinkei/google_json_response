require "google_json_response/error_parsers/parse_generic_error"
require "google_json_response/error_parsers/parse_active_record_error"
require "google_json_response/error_parsers/parse_standard_error"

module GoogleJsonResponse
  class ErrorRenderer
    attr_reader :errors, :rendered_content

    def self.render(errors)
      renderer = GoogleJsonResponse::ErrorRenderer.new(errors)
      renderer.call
      renderer.rendered_content
    end

    def initialize(errors)
      @errors = errors
    end

    def call
      parser.call
      @rendered_content = parser.parsed_data
    end

    private

    attr_reader :errors

    def parser
      @parser =
        if standard_error?
          GoogleJsonResponse::ErrorParsers::ParseStandardError.new(errors)
        elsif active_model_error?
          GoogleJsonResponse::ErrorParsers::ParseActiveRecordError.new(errors)
        else
          GoogleJsonResponse::ErrorParsers::ParseGenericError.new(errors)
        end
    end

    def standard_error?
      return true if data.is_a?(StandardError)
      false
    end

    def active_model_error?
      return false unless defined?(::ActiveModel::Errors)
      data.is_a?(::ActiveModel::Errors)
    end

    def generic_error?
      data.is_a?(::String) || data.is_a?(::Array)
    end
  end
end
