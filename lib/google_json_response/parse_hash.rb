module GoogleJsonResponse
  class ParseHash
    attr_reader :parsed_data

    def initialize(data, options = {})
      @data = data
    end

    def call
      @parsed_data = {
        data: @data
      }
    end
  end
end
