require 'google_json_response/record_parsers/base'

module GoogleJsonResponse
  module RecordParsers
    class ParseHashRecords < Base
      attr_reader :parsed_data

      def call
        data =
          if serializable_resource.is_a?(Hash)
            serializable_resource
          else
            {
              sort: sort,
              item_per_page: options[:item_per_page]&.to_i,
              page_index: options[:page_index]&.to_i,
              total_pages: options[:total_pages]&.to_i,
              total_items: options[:total_items]&.to_i,
              items: serializable_resource
            }.reverse_merge(options)
          end
        @parsed_data = { data: data }
      end

      private

      def serializable_resource
        @serializable_resource ||= record.as_json
      end
    end
  end
end
