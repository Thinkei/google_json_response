module GoogleJsonResponse
  module RecordParsers
    class ParserBase
      attr_reader :parsed_data

      def initialize(data, options = {})
        @serializer_klass = options[:serializer_klass]
        @custom_data = options[:custom_data] || {}
        @options = options.except(:serializer_klass, :custom_data)
        @data = data
      end

      private

      def sort
        return @custom_data[:sort] if @custom_data[:sort]
        return @custom_data[:sorts].join(',') if @custom_data[:sorts].is_a?(Array)
      end

      def serializable_resource(resource, serializer_klass, options = {})
        if resource.is_a?(::Array)
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

      def serializable_resource_klass
        version = Gem.loaded_specs["active_model_serializers"].version.to_s
        klass_name =
          case version
          when '0.10.0.rc2' # Main app version. fixed for now!
            'ActiveModel::SerializableResource'
          else
            'ActiveModelSerializers::SerializableResource'
          end
        Object.const_get(klass_name)
      end
    end
  end
end
