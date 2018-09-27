module GoogleJsonResponse
  class ParseHash
    attr_reader :parsed_data

    def initialize(data, options = {})
      @options = options
    end

    def call
    end
  end
end
