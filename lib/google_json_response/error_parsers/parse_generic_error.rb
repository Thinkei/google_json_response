# frozen_string_literal: true

module GoogleJsonResponse
  module ErrorParsers
    class ParseGenericError
      attr_reader :errors, :parsed_data

      GENERIC_ERROR_MESSAGE = 'Unknown Error!'.freeze

      def initialize(errors, options = {})
        @errors = errors
        @options = options
      end

      def call
        error_objects =
          if errors.is_a?(Array)
            array_objects
          elsif errors.is_a?(Exception)
            exception_object
          else
            generic_object
          end

        errors_data = { errors: error_objects }
        errors_data[:code] = code if code
        @parsed_data = { error: errors_data }
      end

      private

      def code
        @options[:code]
      end

      def exception_object
        [{ message: errors.message, reason: errors.class.name }]
      end

      def generic_object
        [{ message: generic_message_content_for(errors) }]
      end

      def generic_message_content_for(error)
        if error.is_a?(String)
          error
        elsif error.is_a?(Hash)
          error[:message] || GENERIC_ERROR_MESSAGE
        else
          error.try(:message) || GENERIC_ERROR_MESSAGE
        end
      end

      def array_objects
        errors.map { |error| { message: generic_message_content_for(error) } }
      end
    end
  end
end
