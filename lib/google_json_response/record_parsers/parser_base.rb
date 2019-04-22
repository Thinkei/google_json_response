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
