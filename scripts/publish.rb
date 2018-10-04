manifest_path = File.expand_path('../../app.json', __FILE__)
version = JSON.parse(File.read(manifest_path))['version']

exec("gem build google_json_response.gemspec && curl -F package=@google_json_response_#{version}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
