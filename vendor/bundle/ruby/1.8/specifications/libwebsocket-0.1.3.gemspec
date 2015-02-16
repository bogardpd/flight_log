# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{libwebsocket}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bernard Potocki"]
  s.date = %q{2012-03-20 00:00:00.000000000Z}
  s.description = %q{Universal Ruby library to handle WebSocket protocol}
  s.email = %q{bernard.potocki@imanel.org}
  s.homepage = %q{http://github.com/imanel/libwebsocket}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Universal Ruby library to handle WebSocket protocol}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, [">= 0"])
    else
      s.add_dependency(%q<addressable>, [">= 0"])
    end
  else
    s.add_dependency(%q<addressable>, [">= 0"])
  end
end
