# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rake}
  s.version = "0.9.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Weirich"]
  s.date = %q{2011-10-22}
  s.default_executable = %q{rake}
  s.description = %q{Rake is a Make-like program implemented in Ruby. Tasks and dependencies arespecified in standard Ruby syntax.}
  s.email = %q{jim@weirichhouse.org}
  s.executables = ["rake"]
  s.files = ["bin/rake"]
  s.homepage = %q{http://rake.rubyforge.org}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubyforge_project = %q{rake}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Ruby based make-like utility.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 2.1"])
    else
      s.add_dependency(%q<minitest>, ["~> 2.1"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 2.1"])
  end
end
