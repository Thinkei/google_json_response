module GoogleJsonResponse
  module ErrorParsers
    class ParseStandardError
      attr_reader :parsed_data, :error

      def initialize(error)
        @error = error
      end

      def call
        @parsed_data = {
          error: {
            errors: [
              {
                reason: error.try(:key) || error.try(:code) || error.class.to_s,
                message: error.message,
              }
            ]
          }
        }
      end
    end
  end
end
