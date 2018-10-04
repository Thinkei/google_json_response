module GoogleJsonResponse
  module ErrorParsers
    class ParseStandardError
      attr_reader :parsed_data
      DEFAULT_ERROR_CODE = 'error'

      def initialize(data, options = {})
        @options = options
        @code = @options[:code]
        @data = data
        @errors = []
      end

      def call
        @errors.push()
        @parsed_data = {
          error: {
            code: @code.to_s,
            errors: parse_errors
          }
        }
      end

      private

      def parse_errors
        if is_a_standard_error?(@data)
          [parseStandardError(@data)]
        end
      end

      def parseStandardError(data)
        {
          reason: data.try(:key) || data.try(:code) || DEFAULT_ERROR_CODE,
          message: data.message,
        }
      end

      def is_a_standard_error?(data)
        return true if data.is_a?(StandardError)
        false
      end
    end
  end
end
