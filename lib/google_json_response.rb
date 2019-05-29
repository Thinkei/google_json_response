require "google_json_response/version"
require "google_json_response/error_renderer"
require "google_json_response/record_renderer"

module GoogleJsonResponse
  class << self
    def render(data, options = {})
      RecordRenderer.render(data, options)
    end

    def render_error(data)
      ErrorRenderer.render(data)
    end
  end
end
