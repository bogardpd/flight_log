# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{builder}
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Weirich"]
  s.autorequire = %q{builder}
  s.date = %q{2010-11-16}
  s.description = %q{Builder provides a number of builder objects that make creating structured data
simple to do.  Currently the following builder objects are supported:

* XML Markup
* XML Events
}
  s.email = %q{jim@weirichhouse.org}
  s.files = ["test/test_blankslate.rb", "test/test_cssbuilder.rb", "test/test_eventbuilder.rb", "test/test_markupbuilder.rb", "test/test_namecollision.rb", "test/test_xchar.rb"]
  s.homepage = %q{http://onestepback.org}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Builders for MarkUp.}
  s.test_files = ["test/test_blankslate.rb", "test/test_cssbuilder.rb", "test/test_eventbuilder.rb", "test/test_markupbuilder.rb", "test/test_namecollision.rb", "test/test_xchar.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
