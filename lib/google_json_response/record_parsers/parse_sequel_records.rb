begin
  require 'sequel'
  require 'active_model_serializers'
rescue LoadError
  raise "This module requires sequel and active_model_serializers"
end
require 'google_json_response/record_parsers/parser_base'

module GoogleJsonResponse
  module RecordParsers
    class ParseSequelRecords < ParserBase
      def call
        if serializable_resource.is_a?(Hash)
          @parsed_data = {
            data: serializable_resource
          }
        else
          data = {
            sort: sort,
            item_per_page: record.try(:page_size) || options[:item_per_page]&.to_i,
            page_index: options[:page_index]&.to_i || record.try(:current_page),
            total_pages: options[:total_pages]&.to_i || record.try(:page_count),
            total_items: options[:total_items]&.to_i ||
              record.try(:pagination_record_count) ||
              record.try(:size),
            items: serializable_resource
          }.reverse_merge(options).compact
          @parsed_data = { data: data }
        end
      end

      private

      def serializable_resource
        @serializable_resource ||=
          record.is_a?(Sequel::Dataset) ? serializable_collection_resource : super
      end
    end
  end
end
