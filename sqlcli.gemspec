# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqlcli/version'

Gem::Specification.new do |gem|
  gem.name          = "sqlcli"
  gem.version       = Sqlcli::VERSION
  gem.authors       = ["Johnny Boursiquot"]
  gem.email         = ["jboursiquot@gmail.com"]
  gem.description   = %q{Command line interface for interacting with relational databases, local or remote.}
  gem.summary       = %q{Command line interface for interacting with relational databases, local or remote. Supports bookmarking of connection strings for easy referencing when submitting queries.}
  gem.homepage      = "https://github.com/jboursiquot/sqlcli"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "thor"
  gem.add_runtime_dependency "sequel"
  gem.add_runtime_dependency "terminal-table"

  gem.add_development_dependency "pry"
  gem.add_development_dependency "pry-debugger"
end
