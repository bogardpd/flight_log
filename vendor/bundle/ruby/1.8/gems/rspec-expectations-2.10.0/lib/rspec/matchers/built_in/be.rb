require 'rspec/matchers/dsl'

module RSpec
  module Matchers
    module BuiltIn
      class BeTrue
        include BaseMatcher

        def matches?(actual)
          super(actual)
        end
      end

      class BeFalse
        include BaseMatcher

        def matches?(actual)
          !super(actual)
        end
      end

      class BeNil
        include BaseMatcher

        def matches?(actual)
          super(actual).nil?
        end

        def failure_message_for_should
          "expected: nil\n     got: #{actual.inspect}"
        end

        def failure_message_for_should_not
          "expected: not nil\n     got: nil"
        end
      end

      class Be
        include RSpec::Matchers::Pretty

        def initialize(*args, &block)
          @args = args
        end

        def matches?(actual)
          @actual = actual
          !!@actual
        end

        def failure_message_for_should
          "expected #{@actual.inspect} to evaluate to true"
        end

        def failure_message_for_should_not
          "expected #{@actual.inspect} to evaluate to false"
        end

        def description
          "be"
        end

        [:==, :<, :<=, :>=, :>, :===].each do |operator|
          define_method operator do |operand|
            BeComparedTo.new(operand, operator)
          end
        end

        private

        def args_to_s
          @args.empty? ? "" : parenthesize(inspected_args.join(', '))
        end

        def parenthesize(string)
          "(#{string})"
        end

        def inspected_args
          @args.collect{|a| a.inspect}
        end

        def expected_to_sentence
          split_words(@expected)
        end

        def args_to_sentence
          to_sentence(@args)
        end
      end

      class BeComparedTo < Be
        def initialize(operand, operator)
          @expected, @operator = operand, operator
            @args = []
        end

        def matches?(actual)
          @actual = actual
          @actual.__send__(@operator, @expected)
        end

        def failure_message_for_should
          "expected: #{@operator} #{@expected.inspect}\n     got: #{@operator.to_s.gsub(/./, ' ')} #{@actual.inspect}"
        end

        def failure_message_for_should_not
          message = <<-MESSAGE
'should_not be #{@operator} #{@expected}' not only FAILED,
it is a bit confusing.
          MESSAGE

          raise message << ([:===,:==].include?(@operator) ?
                            "It might be more clearly expressed without the \"be\"?" :
                            "It might be more clearly expressed in the positive?")
        end

        def description
          "be #{@operator} #{expected_to_sentence}#{args_to_sentence}"
        end
      end

      class BePredicate < Be
        def initialize(*args, &block)
          @expected = parse_expected(args.shift)
          @args = args
          @block = block
        end

        def matches?(actual)
          @actual = actual
          begin
            return @result = actual.__send__(predicate, *@args, &@block)
          rescue NameError => predicate_missing_error
            "this needs to be here or rcov will not count this branch even though it's executed in a code example"
          end

          begin
            return @result = actual.__send__(present_tense_predicate, *@args, &@block)
          rescue NameError
            raise predicate_missing_error
          end
        end

        def failure_message_for_should
          "expected #{predicate}#{args_to_s} to return true, got #{@result.inspect}"
        end

        def failure_message_for_should_not
          "expected #{predicate}#{args_to_s} to return false, got #{@result.inspect}"
        end

        def description
          "#{prefix_to_sentence}#{expected_to_sentence}#{args_to_sentence}"
        end

        private

        def predicate
          "#{@expected}?".to_sym
        end

        def present_tense_predicate
          "#{@expected}s?".to_sym
        end

        def parse_expected(expected)
          @prefix, expected = prefix_and_expected(expected)
          expected
        end

        def prefix_and_expected(symbol)
          symbol.to_s =~ /^(be_(an?_)?)(.*)/
          return $1, $3
        end

        def prefix_to_sentence
          split_words(@prefix)
        end
      end
    end

  end
end
