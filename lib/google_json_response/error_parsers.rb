require "google_json_response/error_parsers/parse_errors"

module GoogleJsonResponse
  module ErrorParsers
    def self.parse(data, options = {})
      parser = GoogleJsonResponse::ErrorParsers::ParseErrors.new(data, options)
      parser.call
      parser.parsed_data
    end
  end
end
