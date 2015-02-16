# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{journey}
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson"]
  s.date = %q{2012-06-14}
  s.description = %q{Journey is a router.  It routes requests.}
  s.email = ["aaron@tenderlovemaking.com"]
  s.files = ["test/gtg/test_builder.rb", "test/gtg/test_transition_table.rb", "test/nfa/test_simulator.rb", "test/nfa/test_transition_table.rb", "test/nodes/test_symbol.rb", "test/path/test_pattern.rb", "test/route/definition/test_parser.rb", "test/route/definition/test_scanner.rb", "test/router/test_strexp.rb", "test/router/test_utils.rb", "test/test_route.rb", "test/test_router.rb", "test/test_routes.rb"]
  s.homepage = %q{http://github.com/rails/journey}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{journey}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Journey is a router}
  s.test_files = ["test/gtg/test_builder.rb", "test/gtg/test_transition_table.rb", "test/nfa/test_simulator.rb", "test/nfa/test_transition_table.rb", "test/nodes/test_symbol.rb", "test/path/test_pattern.rb", "test/route/definition/test_parser.rb", "test/route/definition/test_scanner.rb", "test/router/test_strexp.rb", "test/router/test_utils.rb", "test/test_route.rb", "test/test_router.rb", "test/test_routes.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 2.11"])
      s.add_development_dependency(%q<racc>, [">= 1.4.6"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.11"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 2.13"])
    else
      s.add_dependency(%q<minitest>, ["~> 2.11"])
      s.add_dependency(%q<racc>, [">= 1.4.6"])
      s.add_dependency(%q<rdoc>, ["~> 3.11"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 2.13"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 2.11"])
    s.add_dependency(%q<racc>, [">= 1.4.6"])
    s.add_dependency(%q<rdoc>, ["~> 3.11"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 2.13"])
  end
end
