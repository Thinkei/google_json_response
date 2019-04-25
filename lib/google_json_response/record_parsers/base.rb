module GoogleJsonResponse
  module RecordParsers
    class Base
      attr_reader :parsed_data, :record, :serializer_klass, :each_serializer_options, :options

      def initialize(record, options = {})
        @record = record
        @serializer_klass = options[:serializer_klass]
        @each_serializer_options = options[:custom_data]&.delete(:each_serializer_options) || {}
        @options = options[:custom_data] || {}
      end

      def call
        data =
          if serializable_resource.is_a?(Hash)
            serializable_resource
          else
            { items: serializable_resource }
              .merge(sort_data)
              .merge(pagination_data)
          end
        data.reverse_merge!(options)
        @parsed_data = { data: data }
      end

      private

      def pagination_data
        {
          item_per_page: options[:item_per_page]&.to_i,
          page_index: options[:page_index]&.to_i,
          total_pages: options[:total_pages]&.to_i,
          total_items: options[:total_items]&.to_i
        }
      end

      def sort_data
        return { sort: options[:sort] } if options[:sort]
        return { sort: options[:sorts].join(',') } if options[:sorts].is_a?(Array)
        { sort: nil }
      end

      def serializable_resource
        @serializable_resource ||=
          if serializer_klass.blank?
            record.as_json
          else
            serializable_resource_klass.new(record, active_model_options).as_json(json_options)
          end
      end

      def serializer_option
        if record.is_a?(::Array)
          { each_serializer: serializer_klass }
        else
          { serializer: serializer_klass }
        end
      end

      def active_model_options
        return @active_model_options if @active_model_options.present?

        _merge_options = each_serializer_options || { scope: {}, include: "", current_member: {} }
        _merge_options.reverse_merge!(serializer_option)
        @active_model_options = options.reverse_merge(_merge_options)
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

      def json_options
        json_options = {}
        json_options[:fields] = json_fields if json_fields
        json_options
      end

      def json_fields
        return nil if serializer_klass.blank?
        @json_fields ||=
          if options[:only].present?
            Array(options[:only])
          elsif options[:except].present?
            serializer_klass._attributes - Array(options[:except])
          end
      end
    end
  end
end
