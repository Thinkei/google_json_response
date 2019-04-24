begin
  require 'active_model'
  require 'active_record'
  require 'active_model_serializers'
rescue LoadError
  raise "This module requires active_record and active_model_serializers"
end
require 'google_json_response/record_parsers/base'

module GoogleJsonResponse
  module RecordParsers
    class ParseActiveRecords < Base
      def call
        data =
          if serializable_resource.is_a?(Hash)
            serializable_resource
          else
            {
              sort: sort,
              item_per_page: options[:item_per_page]&.to_i || record.try(:limit_value),
              page_index: options[:page_index]&.to_i || record.try(:current_page),
              total_pages: options[:total_pages]&.to_i || record.try(:total_pages),
              total_items: options[:total_items]&.to_i || record.try(:total_count),
              items: serializable_resource
            }.reverse_merge(options)
          end
        @parsed_data = { data: data }
      end

      private

      def serializer_option
        return { each_serializer: serializer_klass } if record.is_a?(ActiveRecord::Relation)
        super
      end
    end
  end
end
