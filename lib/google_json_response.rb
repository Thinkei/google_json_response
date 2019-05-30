require "google_json_response/version"
require "google_json_response/error_renderer"
require "google_json_response/record_renderer"

module GoogleJsonResponse
  class << self
    def render(data, options = {})
      renderer = GoogleJsonResponse::RecordRenderer.new(data, options)
      renderer.call
      renderer.rendered_content
    end

    def render_error(errors)
      renderer = GoogleJsonResponse::ErrorRenderer.new(errors)
      renderer.call
      renderer.rendered_content
    end
  end
end
