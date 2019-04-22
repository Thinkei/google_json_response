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

      def sort
        return @custom_data[:sort] if @custom_data[:sort]
        return @custom_data[:sorts].join(',') if @custom_data[:sorts].is_a?(Array)
      end

      def serializable_resource(resource, serializer_klass, options = {})
        if resource.is_a?(ActiveRecord::Relation) || resource.is_a?(::Array)
          serializable_collection_resource(resource, serializer_klass, options)
        else
          serializable_object_resource(resource, serializer_klass, options)
        end
      end

      def serializable_collection_resource(collection, serializer_klass, options = {})
        options.reverse_merge!(
          each_serializer: serializer_klass,
          scope: {},
          include: "",
          current_member: {}
        )
        serializable_resource_klass.new(
          collection,
          options
        ).as_json
      end

      def serializable_object_resource(resource, serializer_klass, options = {})
        options.reverse_merge!(
          serializer: serializer_klass,
          scope: {},
          include: "",
          current_member: {}
        )
        serializable_resource_klass.new(
          resource,
          options
        ).as_json
      end
    end
  end
end
