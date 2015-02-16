# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rspec-mocks}
  s.version = "2.10.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Steven Baker", "David Chelimsky"]
  s.date = %q{2012-05-05}
  s.description = %q{RSpec's 'test double' framework, with support for stubbing and mocking}
  s.email = %q{rspec-users@rubyforge.org}
  s.files = ["features/README.md", "features/Scope.md", "features/Upgrade.md", "features/argument_matchers/README.md", "features/argument_matchers/explicit.feature", "features/argument_matchers/general_matchers.feature", "features/argument_matchers/type_matchers.feature", "features/message_expectations/README.md", "features/message_expectations/any_instance.feature", "features/message_expectations/block_local_expectations.feature.pending", "features/message_expectations/expect_message.feature", "features/message_expectations/receive_counts.feature", "features/message_expectations/warn_when_expectation_is_set_on_nil.feature", "features/method_stubs/README.md", "features/method_stubs/any_instance.feature", "features/method_stubs/as_null_object.feature", "features/method_stubs/simple_return_value.feature", "features/method_stubs/stub_chain.feature", "features/method_stubs/stub_implementation.feature", "features/method_stubs/to_ary.feature", "features/outside_rspec/configuration.feature", "features/outside_rspec/standalone.feature", "features/step_definitions/additional_cli_steps.rb", "features/support/env.rb", "spec/rspec/mocks/and_yield_spec.rb", "spec/rspec/mocks/any_instance/message_chains_spec.rb", "spec/rspec/mocks/any_instance_spec.rb", "spec/rspec/mocks/any_number_of_times_spec.rb", "spec/rspec/mocks/argument_expectation_spec.rb", "spec/rspec/mocks/at_least_spec.rb", "spec/rspec/mocks/at_most_spec.rb", "spec/rspec/mocks/block_return_value_spec.rb", "spec/rspec/mocks/bug_report_10260_spec.rb", "spec/rspec/mocks/bug_report_10263_spec.rb", "spec/rspec/mocks/bug_report_11545_spec.rb", "spec/rspec/mocks/bug_report_496_spec.rb", "spec/rspec/mocks/bug_report_600_spec.rb", "spec/rspec/mocks/bug_report_7611_spec.rb", "spec/rspec/mocks/bug_report_8165_spec.rb", "spec/rspec/mocks/bug_report_830_spec.rb", "spec/rspec/mocks/bug_report_957_spec.rb", "spec/rspec/mocks/double_spec.rb", "spec/rspec/mocks/failing_argument_matchers_spec.rb", "spec/rspec/mocks/hash_excluding_matcher_spec.rb", "spec/rspec/mocks/hash_including_matcher_spec.rb", "spec/rspec/mocks/mock_ordering_spec.rb", "spec/rspec/mocks/mock_space_spec.rb", "spec/rspec/mocks/mock_spec.rb", "spec/rspec/mocks/multiple_return_value_spec.rb", "spec/rspec/mocks/nil_expectation_warning_spec.rb", "spec/rspec/mocks/null_object_mock_spec.rb", "spec/rspec/mocks/once_counts_spec.rb", "spec/rspec/mocks/options_hash_spec.rb", "spec/rspec/mocks/partial_mock_spec.rb", "spec/rspec/mocks/partial_mock_using_mocks_directly_spec.rb", "spec/rspec/mocks/passing_argument_matchers_spec.rb", "spec/rspec/mocks/precise_counts_spec.rb", "spec/rspec/mocks/record_messages_spec.rb", "spec/rspec/mocks/serialization_spec.rb", "spec/rspec/mocks/stash_spec.rb", "spec/rspec/mocks/stub_chain_spec.rb", "spec/rspec/mocks/stub_implementation_spec.rb", "spec/rspec/mocks/stub_spec.rb", "spec/rspec/mocks/stubbed_message_expectations_spec.rb", "spec/rspec/mocks/test_double_spec.rb", "spec/rspec/mocks/to_ary_spec.rb", "spec/rspec/mocks/twice_counts_spec.rb", "spec/rspec/mocks_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/rspec/rspec-mocks}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rspec}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{rspec-mocks-2.10.1}
  s.test_files = ["features/README.md", "features/Scope.md", "features/Upgrade.md", "features/argument_matchers/README.md", "features/argument_matchers/explicit.feature", "features/argument_matchers/general_matchers.feature", "features/argument_matchers/type_matchers.feature", "features/message_expectations/README.md", "features/message_expectations/any_instance.feature", "features/message_expectations/block_local_expectations.feature.pending", "features/message_expectations/expect_message.feature", "features/message_expectations/receive_counts.feature", "features/message_expectations/warn_when_expectation_is_set_on_nil.feature", "features/method_stubs/README.md", "features/method_stubs/any_instance.feature", "features/method_stubs/as_null_object.feature", "features/method_stubs/simple_return_value.feature", "features/method_stubs/stub_chain.feature", "features/method_stubs/stub_implementation.feature", "features/method_stubs/to_ary.feature", "features/outside_rspec/configuration.feature", "features/outside_rspec/standalone.feature", "features/step_definitions/additional_cli_steps.rb", "features/support/env.rb", "spec/rspec/mocks/and_yield_spec.rb", "spec/rspec/mocks/any_instance/message_chains_spec.rb", "spec/rspec/mocks/any_instance_spec.rb", "spec/rspec/mocks/any_number_of_times_spec.rb", "spec/rspec/mocks/argument_expectation_spec.rb", "spec/rspec/mocks/at_least_spec.rb", "spec/rspec/mocks/at_most_spec.rb", "spec/rspec/mocks/block_return_value_spec.rb", "spec/rspec/mocks/bug_report_10260_spec.rb", "spec/rspec/mocks/bug_report_10263_spec.rb", "spec/rspec/mocks/bug_report_11545_spec.rb", "spec/rspec/mocks/bug_report_496_spec.rb", "spec/rspec/mocks/bug_report_600_spec.rb", "spec/rspec/mocks/bug_report_7611_spec.rb", "spec/rspec/mocks/bug_report_8165_spec.rb", "spec/rspec/mocks/bug_report_830_spec.rb", "spec/rspec/mocks/bug_report_957_spec.rb", "spec/rspec/mocks/double_spec.rb", "spec/rspec/mocks/failing_argument_matchers_spec.rb", "spec/rspec/mocks/hash_excluding_matcher_spec.rb", "spec/rspec/mocks/hash_including_matcher_spec.rb", "spec/rspec/mocks/mock_ordering_spec.rb", "spec/rspec/mocks/mock_space_spec.rb", "spec/rspec/mocks/mock_spec.rb", "spec/rspec/mocks/multiple_return_value_spec.rb", "spec/rspec/mocks/nil_expectation_warning_spec.rb", "spec/rspec/mocks/null_object_mock_spec.rb", "spec/rspec/mocks/once_counts_spec.rb", "spec/rspec/mocks/options_hash_spec.rb", "spec/rspec/mocks/partial_mock_spec.rb", "spec/rspec/mocks/partial_mock_using_mocks_directly_spec.rb", "spec/rspec/mocks/passing_argument_matchers_spec.rb", "spec/rspec/mocks/precise_counts_spec.rb", "spec/rspec/mocks/record_messages_spec.rb", "spec/rspec/mocks/serialization_spec.rb", "spec/rspec/mocks/stash_spec.rb", "spec/rspec/mocks/stub_chain_spec.rb", "spec/rspec/mocks/stub_implementation_spec.rb", "spec/rspec/mocks/stub_spec.rb", "spec/rspec/mocks/stubbed_message_expectations_spec.rb", "spec/rspec/mocks/test_double_spec.rb", "spec/rspec/mocks/to_ary_spec.rb", "spec/rspec/mocks/twice_counts_spec.rb", "spec/rspec/mocks_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_development_dependency(%q<cucumber>, ["~> 1.1.9"])
      s.add_development_dependency(%q<aruba>, ["~> 0.4.11"])
    else
      s.add_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_dependency(%q<cucumber>, ["~> 1.1.9"])
      s.add_dependency(%q<aruba>, ["~> 0.4.11"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 0.9.2"])
    s.add_dependency(%q<cucumber>, ["~> 1.1.9"])
    s.add_dependency(%q<aruba>, ["~> 0.4.11"])
  end
end
