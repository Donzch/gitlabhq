# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Matches < Lexeme::LogicalOperator
            PATTERN = /=~/.freeze

            def evaluate(variables = {})
              text = @left.evaluate(variables)
              regexp = @right.evaluate(variables)

              return false unless regexp

              if ::Feature.enabled?(:ci_fix_rules_if_comparison_with_regexp_variable)
                # All variables are evaluated as strings, even if they are regexp strings.
                # So, we need to convert them to regexp objects.
                regexp = Lexeme::Pattern.build_and_evaluate(regexp, variables)
              end

              regexp.scan(text.to_s).present?
            end

            def self.build(_value, behind, ahead)
              new(behind, ahead)
            end

            def self.precedence
              10 # See: https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html
            end
          end
        end
      end
    end
  end
end
