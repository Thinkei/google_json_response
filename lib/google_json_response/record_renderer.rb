require "google_json_response/record_parsers/parse_hash_records"

module GoogleJsonResponse
  class RecordRenderer
    attr_reader :data, :options, :rendered_content

    def self.render(data, options = {})
      renderer = GoogleJsonResponse::RecordRenderer.new(data, options)
      renderer.call
      renderer.rendered_content
    end

    def initialize(data, options = {})
      @data = data
      @options = options
    end

    def call
      parser.call
      @rendered_content = parser.parsed_data
    end

    private

    def parser
      @parser ||=
        if active_record?
          active_record_parser
        elsif sequel_record?
          sequel_parser
        else
          hash_parser
        end
    end

    def active_record?
      return data[0].is_a?(::ActiveRecord::Base) if data.is_a?(::Array)
      return false if !defined?(::ActiveRecord::Base) || !defined?(::ActiveRecord::Relation)
      data.is_a?(::ActiveRecord::Base) || data.is_a?(::ActiveRecord::Relation)
    end

    def sequel_record?
      return data[0].is_a?(::Sequel::Model) if data.is_a?(::Array)
      return false if !defined?(::Sequel::Model) || !defined?(::Sequel::Dataset)
      data.is_a?(::Sequel::Model) || data.is_a?(::Sequel::Dataset)
    end

    def active_record_parser
      unless defined?(GoogleJsonResponse::RecordParsers::ParseActiveRecords)
        raise "Please require google_json_response/active_records"\
        " to render active records"
      end
      GoogleJsonResponse::RecordParsers::ParseActiveRecords.new(data, options)
    end

    def sequel_parser
      unless defined?(GoogleJsonResponse::RecordParsers::ParseSequelRecords)
        raise "Please require google_json_response/sequel_records"\
        " to render sequel records"
      end
      GoogleJsonResponse::RecordParsers::ParseSequelRecords.new(data, options)
    end

    def hash_parser
      GoogleJsonResponse::RecordParsers::ParseHashRecords.new(data, options)
    end
  end
end
