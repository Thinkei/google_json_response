module GoogleJsonResponse
  module RecordParsers
    class ParserBase
      attr_reader :parsed_data, :record, :serializer_klass, :options

      def initialize(record, options = {})
        @serializer_klass = options[:serializer_klass]
        @options = options[:custom_data] || {}
        @record = record
      end

      private

      def sort
        return options[:sort] if options[:sort]
        return options[:sorts].join(',') if options[:sorts].is_a?(Array)
      end

      def serializable_resource
        @serializable_resource ||=
          if record.is_a?(::Array)
            serializable_collection_resource
          else
            serializable_object_resource
          end
      end

      def serializable_collection_resource
        options.reverse_merge!(
          each_serializer: serializer_klass,
          scope: {},
          include: "",
          current_member: {}
        )
        serializable_resource_klass.new(record, options).as_json
      end

      def serializable_object_resource
        options.reverse_merge!(
          serializer: serializer_klass,
          scope: {},
          include: "",
          current_member: {}
        )
        serializable_resource_klass.new(
          record,
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
