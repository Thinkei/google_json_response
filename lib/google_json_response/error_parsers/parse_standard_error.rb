module GoogleJsonResponse
  module ErrorParsers
    class ParseStandardError
      attr_reader :parsed_data, :error

      def initialize(error, options = {})
        @error = error
        @options = options
      end

      def call
        errors_data =  {
          errors: [
            {
              reason: error.try(:key) || error.try(:code) || error.class.to_s,
              message: error.message,
            }
          ]
        }
        errors_data[:code] = code if code
        @parsed_data = {
          error: errors_data
        }
      end

      private

      def code
        @options[:code]
      end
    end
  end
end
