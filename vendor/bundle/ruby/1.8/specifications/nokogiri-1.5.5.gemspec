# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{nokogiri}
  s.version = "1.5.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson", "Mike Dalessio", "Yoko Harada", "Tim Elliott"]
  s.date = %q{2012-06-23}
  s.default_executable = %q{nokogiri}
  s.description = %q{Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser.  Among Nokogiri's
many features is the ability to search documents via XPath or CSS3 selectors.

XML is like violence - if it doesn’t solve your problems, you are not using
enough of it.}
  s.email = ["aaronp@rubyforge.org", "mike.dalessio@gmail.com", "yokolet@gmail.com", "tle@holymonkey.com"]
  s.executables = ["nokogiri"]
  s.extensions = ["ext/nokogiri/extconf.rb"]
  s.files = ["test/test_nokogiri.rb", "test/css/test_tokenizer.rb", "test/css/test_xpath_visitor.rb", "test/css/test_nthiness.rb", "test/css/test_parser.rb", "test/xml/test_dtd_encoding.rb", "test/xml/test_document_encoding.rb", "test/xml/test_node_inheritance.rb", "test/xml/test_entity_decl.rb", "test/xml/test_node_reparenting.rb", "test/xml/sax/test_parser_context.rb", "test/xml/sax/test_push_parser.rb", "test/xml/sax/test_parser.rb", "test/xml/test_attr.rb", "test/xml/test_cdata.rb", "test/xml/test_document.rb", "test/xml/test_node_encoding.rb", "test/xml/test_document_fragment.rb", "test/xml/test_c14n.rb", "test/xml/test_dtd.rb", "test/xml/test_node.rb", "test/xml/test_comment.rb", "test/xml/test_text.rb", "test/xml/node/test_save_options.rb", "test/xml/node/test_subclass.rb", "test/xml/test_schema.rb", "test/xml/test_node_attributes.rb", "test/xml/test_namespace.rb", "test/xml/test_attribute_decl.rb", "test/xml/test_xpath.rb", "test/xml/test_processing_instruction.rb", "test/xml/test_reader_encoding.rb", "test/xml/test_element_decl.rb", "test/xml/test_builder.rb", "test/xml/test_node_set.rb", "test/xml/test_syntax_error.rb", "test/xml/test_parse_options.rb", "test/xml/test_xinclude.rb", "test/xml/test_element_content.rb", "test/xml/test_unparented_node.rb", "test/xml/test_entity_reference.rb", "test/xml/test_relax_ng.rb", "test/test_xslt_transforms.rb", "test/test_memory_leak.rb", "test/test_css_cache.rb", "test/decorators/test_slop.rb", "test/test_soap4r_sax.rb", "test/test_encoding_handler.rb", "test/html/test_document_encoding.rb", "test/html/test_named_characters.rb", "test/html/sax/test_parser_context.rb", "test/html/sax/test_parser.rb", "test/html/test_document.rb", "test/html/test_node_encoding.rb", "test/html/test_document_fragment.rb", "test/html/test_node.rb", "test/html/test_element_description.rb", "test/html/test_builder.rb", "test/xslt/test_exception_handling.rb", "test/xslt/test_custom_functions.rb", "test/test_reader.rb", "test/test_convert_xpath.rb", "bin/nokogiri", "ext/nokogiri/extconf.rb"]
  s.homepage = %q{http://nokogiri.org}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubyforge_project = %q{nokogiri}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser}
  s.test_files = ["test/test_nokogiri.rb", "test/css/test_tokenizer.rb", "test/css/test_xpath_visitor.rb", "test/css/test_nthiness.rb", "test/css/test_parser.rb", "test/xml/test_dtd_encoding.rb", "test/xml/test_document_encoding.rb", "test/xml/test_node_inheritance.rb", "test/xml/test_entity_decl.rb", "test/xml/test_node_reparenting.rb", "test/xml/sax/test_parser_context.rb", "test/xml/sax/test_push_parser.rb", "test/xml/sax/test_parser.rb", "test/xml/test_attr.rb", "test/xml/test_cdata.rb", "test/xml/test_document.rb", "test/xml/test_node_encoding.rb", "test/xml/test_document_fragment.rb", "test/xml/test_c14n.rb", "test/xml/test_dtd.rb", "test/xml/test_node.rb", "test/xml/test_comment.rb", "test/xml/test_text.rb", "test/xml/node/test_save_options.rb", "test/xml/node/test_subclass.rb", "test/xml/test_schema.rb", "test/xml/test_node_attributes.rb", "test/xml/test_namespace.rb", "test/xml/test_attribute_decl.rb", "test/xml/test_xpath.rb", "test/xml/test_processing_instruction.rb", "test/xml/test_reader_encoding.rb", "test/xml/test_element_decl.rb", "test/xml/test_builder.rb", "test/xml/test_node_set.rb", "test/xml/test_syntax_error.rb", "test/xml/test_parse_options.rb", "test/xml/test_xinclude.rb", "test/xml/test_element_content.rb", "test/xml/test_unparented_node.rb", "test/xml/test_entity_reference.rb", "test/xml/test_relax_ng.rb", "test/test_xslt_transforms.rb", "test/test_memory_leak.rb", "test/test_css_cache.rb", "test/decorators/test_slop.rb", "test/test_soap4r_sax.rb", "test/test_encoding_handler.rb", "test/html/test_document_encoding.rb", "test/html/test_named_characters.rb", "test/html/sax/test_parser_context.rb", "test/html/sax/test_parser.rb", "test/html/test_document.rb", "test/html/test_node_encoding.rb", "test/html/test_document_fragment.rb", "test/html/test_node.rb", "test/html/test_element_description.rb", "test/html/test_builder.rb", "test/xslt/test_exception_handling.rb", "test/xslt/test_custom_functions.rb", "test/test_reader.rb", "test/test_convert_xpath.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe-bundler>, [">= 1.1"])
      s.add_development_dependency(%q<hoe-debugging>, [">= 1.0.3"])
      s.add_development_dependency(%q<hoe-gemspec>, [">= 1.0"])
      s.add_development_dependency(%q<hoe-git>, [">= 1.4"])
      s.add_development_dependency(%q<mini_portile>, [">= 0.2.2"])
      s.add_development_dependency(%q<minitest>, ["~> 2.2.2"])
      s.add_development_dependency(%q<rake>, [">= 0.9"])
      s.add_development_dependency(%q<rake-compiler>, ["= 0.8.0"])
      s.add_development_dependency(%q<racc>, [">= 1.4.6"])
      s.add_development_dependency(%q<rexical>, [">= 1.0.5"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 2.16"])
    else
      s.add_dependency(%q<hoe-bundler>, [">= 1.1"])
      s.add_dependency(%q<hoe-debugging>, [">= 1.0.3"])
      s.add_dependency(%q<hoe-gemspec>, [">= 1.0"])
      s.add_dependency(%q<hoe-git>, [">= 1.4"])
      s.add_dependency(%q<mini_portile>, [">= 0.2.2"])
      s.add_dependency(%q<minitest>, ["~> 2.2.2"])
      s.add_dependency(%q<rake>, [">= 0.9"])
      s.add_dependency(%q<rake-compiler>, ["= 0.8.0"])
      s.add_dependency(%q<racc>, [">= 1.4.6"])
      s.add_dependency(%q<rexical>, [">= 1.0.5"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 2.16"])
    end
  else
    s.add_dependency(%q<hoe-bundler>, [">= 1.1"])
    s.add_dependency(%q<hoe-debugging>, [">= 1.0.3"])
    s.add_dependency(%q<hoe-gemspec>, [">= 1.0"])
    s.add_dependency(%q<hoe-git>, [">= 1.4"])
    s.add_dependency(%q<mini_portile>, [">= 0.2.2"])
    s.add_dependency(%q<minitest>, ["~> 2.2.2"])
    s.add_dependency(%q<rake>, [">= 0.9"])
    s.add_dependency(%q<rake-compiler>, ["= 0.8.0"])
    s.add_dependency(%q<racc>, [">= 1.4.6"])
    s.add_dependency(%q<rexical>, [">= 1.0.5"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 2.16"])
  end
end
