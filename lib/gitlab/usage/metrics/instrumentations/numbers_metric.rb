# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class NumbersMetric < BaseMetric
          # Usage Example
          #
          # class BoardsCountMetric < NumbersMetric
          #   operation :add
          #
          #   data do |time_frame|
          #     [
          #        CountIssuesMetric.new(time_frame: time_frame).value,
          #        CountBoardsMetric.new(time_frame: time_frame).value,
          #     ]
          #   end
          # end

          UnimplementedOperationError = Class.new(StandardError) # rubocop:disable UsageData/InstrumentationSuperclass

          class << self
            IMPLEMENTED_OPERATIONS = %i(add).freeze

            private_constant :IMPLEMENTED_OPERATIONS

            def data(&block)
              return @metric_data&.call unless block_given?

              @metric_data = block
            end

            def operation(symbol)
              raise UnimplementedOperationError unless symbol.in?(IMPLEMENTED_OPERATIONS)

              @metric_operation = symbol
            end

            attr_reader :metric_operation, :metric_data
          end

          def value
            method(self.class.metric_operation).call(*data)
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(:alt)
          end

          private

          def data
            self.class.metric_data.call(time_frame)
          end
        end
      end
    end
  end
end
