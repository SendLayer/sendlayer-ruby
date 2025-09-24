# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "sendlayer"
  spec.version       = ::SendLayer::VERSION
  spec.authors       = ["SendLayer"]
  spec.email         = ["support@sendlayer.com"]

  spec.summary       = "Official Ruby SDK for SendLayer API"
  spec.description   = "The official Ruby SDK for interacting with the SendLayer API, providing a simple and intuitive interface for sending emails, managing webhooks, and retrieving email events."
  spec.homepage      = "https://github.com/sendlayer/sendlayer-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sendlayer/sendlayer-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/sendlayer/sendlayer-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "mime-types", "~> 3.4"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
end
