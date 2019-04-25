require 'google_json_response/record_parsers/base'

module GoogleJsonResponse
  module RecordParsers
    class ParseHashRecords < Base
      attr_reader :parsed_data
      private

      def serializable_resource
        @serializable_resource ||= record.as_json
      end
    end
  end
end
