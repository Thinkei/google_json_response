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
                reason: data.try(:key) || data.try(:code) || data.class.to_s,
                message: data.message,
              }
            ]
          }
        }
      end
    end
  end
end
