begin
  require 'active_model'
  require 'active_record'
rescue LoadError
  raise "This module requires active_record and active_model"
end

module GoogleJsonResponse
  module ErrorParsers
    class ParseActiveRecordError
      attr_reader :parsed_data, :options, :errors

      def initialize(errors, options = {})
        @errors = errors
        @options = options
      end

      def call
        @parsed_data = render_validation_error
      end

      private

      def code
        @options[:code]
      end

      def show_active_record_full_message?
        @options[:active_record_full_message] == true
      end

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

        errors_data = { errors: error_objects }
        errors_data[:code] = code if code
        { error: errors_data }
      end

      def validation_message(errors, field, index)
        if show_active_record_full_message?
          if errors.messages[field][index].try(:chr) == '^'
            return errors.full_messages_for(field)[index].split('^', 2).last
          end
          errors.full_messages_for(field)[index]
        else
          errors[field][index]
        end
      end

      def field_index(field)
        if errors.messages.with_indifferent_access[field].size > 1
          field_messages = errors.messages.with_indifferent_access[field]
          field_index = field_messages.index { |message| message == "is invalid" }
          return field_index
        end
        nil
      end
    end
  end
end
