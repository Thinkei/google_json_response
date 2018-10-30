begin
  require 'active_record'
  require 'active_model'
  require 'active_model_serializers'
rescue LoadError
  raise "This module requires active_record and active_model_serializers"
end


module GoogleJsonResponse
  class ParseActiveRecords
    attr_reader :parsed_data

    def initialize(data, options = {})
      @serializer_klass = options[:serializer_klass]
      @api_params = options[:api_params] || {}
      @options = options.except(:serializer_klass, :api_params)
      @data = data
    end

    def call
      parsed_resource = serializable_resource(@data, @serializer_klass, @options)

      if parsed_resource.is_a?(Hash)
        @parsed_data = {
          data: parsed_resource
        }
      else
        data = {
          sort: sort,
          item_per_page: @api_params[:item_per_page].to_i,
          page_index: @data.try(:current_page),
          total_pages: @data.try(:total_pages),
          total_items: @data.try(:total_count),
          items: parsed_resource
        }
        data[:status_filter] = { status: @api_params[:status] } if @options[:status_filter]
        @parsed_data = { data: data }
      end
    end

    private

    def sort
      return @api_params[:sort] if @api_params[:sort]
      return @api_params[:sorts].join(',') if @api_params[:sorts].is_a?(Array)
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
      ActiveModelSerializers::SerializableResource.new(
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
      ActiveModelSerializers::SerializableResource.new(
        resource,
        options
      ).as_json
    end
  end
end
