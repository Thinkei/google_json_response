begin
  require 'active_record'
  require 'active_model'
  require 'active_model_serializers'
rescue LoadError
  raise "This module requires active_record and active_model_serializers"
end

require 'google_json_response/record_parsers/parser_base'

module GoogleJsonResponse
  module RecordParsers
    class ParseActiveRecords < ParserBase
      def call
        parsed_resource = serializable_resource(@data, @serializer_klass, @options)

        if parsed_resource.is_a?(Hash)
          @parsed_data = {
            data: parsed_resource
          }
        else
          data = {
            sort: sort,
            item_per_page: @custom_data[:item_per_page].to_i,
            page_index: @data.try(:current_page),
            total_pages: @data.try(:total_pages),
            total_items: @data.try(:total_count),
            items: parsed_resource
          }
          data[:status_filter] = { status: @custom_data[:status] } if @options[:status_filter]
          @parsed_data = { data: data }
        end
      end

      private

      def serializable_resource(resource, serializer_klass, options = {})
        if resource.is_a?(ActiveRecord::Relation)
          return serializable_collection_resource(resource, serializer_klass, options)
        end
        super
      end
    end
  end
end
