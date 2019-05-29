begin
  require 'active_model'
  require 'active_record'
rescue LoadError
  raise "This module requires active_record and active_model"
end

module GoogleJsonResponse
  module ErrorParsers
    class ParseActiveRecordError
      attr_reader :parsed_data, :errors

      def initialize(errors)
        @errors = errors
      end

      def call
        @parsed_data = render_validation_error
      end

      private

      def render_validation_error
        error_objects = []
        errors.details.each do |field, details|
          default_error_index = field_index(field)
          details.each_with_index do |detail, index|
            if default_error_index != index
              error_objects << {
                reason: detail[:error],
                message: validation_message(errors, field, index),
                location: field,
                location_type: :field
              }
            end
          end
        end
        { error: { errors: error_objects } }
      end

      def validation_message(errors, field, index)
        if errors.messages[field][index].try(:chr) == '^'
          return errors.full_messages_for(field)[index].split('^', 2).last
        end
        errors.full_messages_for(field)[index]
      end

      def field_index(field)
        if errors.messages[field].size > 1
          field_messages = errors.messages[field]
          field_index = field_messages.index { |message| message == "is invalid" }
          return field_index
        end
        nil
      end
    end
  end
end
