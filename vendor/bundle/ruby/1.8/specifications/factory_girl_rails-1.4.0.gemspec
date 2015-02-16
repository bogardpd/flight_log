# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{factory_girl_rails}
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joe Ferris"]
  s.date = %q{2011-11-17}
  s.description = %q{factory_girl_rails provides integration between
    factory_girl and rails 3 (currently just automatic factory definition
    loading)}
  s.email = %q{jferris@thoughtbot.com}
  s.files = ["features/fixture_replacement_config.feature", "features/generators.feature", "features/load_definitions.feature", "features/step_definitions/rails_steps.rb", "features/support/env.rb"]
  s.homepage = %q{http://github.com/thoughtbot/factory_girl_rails}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{factory_girl_rails provides integration between factory_girl and rails 3}
  s.test_files = ["features/fixture_replacement_config.feature", "features/generators.feature", "features/load_definitions.feature", "features/step_definitions/rails_steps.rb", "features/support/env.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<factory_girl>, ["~> 2.3.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<cucumber>, ["~> 1.0.0"])
      s.add_development_dependency(%q<aruba>, [">= 0"])
      s.add_development_dependency(%q<rails>, ["= 3.0.7"])
    else
      s.add_dependency(%q<railties>, [">= 3.0.0"])
      s.add_dependency(%q<factory_girl>, ["~> 2.3.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<cucumber>, ["~> 1.0.0"])
      s.add_dependency(%q<aruba>, [">= 0"])
      s.add_dependency(%q<rails>, ["= 3.0.7"])
    end
  else
    s.add_dependency(%q<railties>, [">= 3.0.0"])
    s.add_dependency(%q<factory_girl>, ["~> 2.3.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<cucumber>, ["~> 1.0.0"])
    s.add_dependency(%q<aruba>, [">= 0"])
    s.add_dependency(%q<rails>, ["= 3.0.7"])
  end
end
