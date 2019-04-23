module GoogleJsonResponse
  module RecordParsers
    class ParserBase
      attr_reader :parsed_data, :record, :serializer_klass, :each_serializer_options, :options

      def initialize(record, options = {})
        @record = record
        @serializer_klass = options[:serializer_klass]
        @each_serializer_options = options[:custom_data]&.delete(:each_serializer_options) || {}
        @options = options[:custom_data] || {}
      end

      private

      def sort
        return options[:sort] if options[:sort]
        options[:sorts].join(',') if options[:sorts].is_a?(Array)
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
        serializer_options = options.reverse_merge(each_serializer: serializer_klass)
        serializer_options = merge_each_serializer_options(serializer_options)
        if record.is_a?(Sequel::Dataset) # Has to do this because guess what? It's stupid fuckn sequel
          return serializable_resource_klass.new(record.to_a, serializer_options).as_json
        end
        serializable_resource_klass.new(record, serializer_options).as_json
      end

      def serializable_object_resource
        serializer_options = options.reverse_merge(serializer: serializer_klass)
        serializer_options = merge_each_serializer_options(serializer_options)
        serializable_resource_klass.new(record, serializer_options).as_json
      end

      def merge_each_serializer_options(serializer_options)
        return serializer_options.reverse_merge(each_serializer_options) if each_serializer_options.present?
        serializer_options.reverse_merge(scope: {}, include: "", current_member: {})
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
