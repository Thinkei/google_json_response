begin
  require 'sequel'
  require 'active_model_serializers'
rescue LoadError
  raise "This module requires sequel and active_model_serializers"
end
require 'google_json_response/record_parsers/base'

module GoogleJsonResponse
  module RecordParsers
    class ParseSequelRecords < Base
      private

      def pagination_data
        {
          item_per_page: record.try(:page_size) || options[:item_per_page]&.to_i,
          page_index: options[:page_index]&.to_i || record.try(:current_page),
          total_pages: options[:total_pages]&.to_i || record.try(:page_count),
          total_items: options[:total_items]&.to_i ||
            record.try(:pagination_record_count) ||
            record.try(:size)
        }
      end

      def serializable_resource
        if record.is_a?(Sequel::Dataset)
          @serializable_resource ||=
            serializable_resource_klass.new(record.to_a, active_model_options).as_json
        else
          super
        end
      end

      def serializer_option
        return { each_serializer: serializer_klass } if record.is_a?(Sequel::Dataset)
        super
      end
    end
  end
end
