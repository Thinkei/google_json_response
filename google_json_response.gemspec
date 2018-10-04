# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google_json_response/version'

Gem::Specification.new do |spec|
  spec.name          = "google_json_response"
  spec.version       = GoogleJsonResponse::VERSION
  spec.authors       = ["Dang (Wilber) Nguyen(minhdang.net@gmail.com)"]
  spec.email         = ["minhdang.net@gmail.com"]

  spec.summary       = %q{API response parser}
  spec.description   = %q{API response parser following Google JSON style}
  spec.homepage      = "https://github.com/Thinkei/google_json_response"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'active_model_serializers', '~> 0.10.0'
  spec.add_development_dependency "kaminari"
end
