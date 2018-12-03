module ATP
  module Processors
    class VariableOptimizer < Processor
      attr_reader :optimize_when_continue

      def run(node, options = {})
        options = {
          optimize_when_continue: true
        }.merge(options)
        @optimize_when_continue = options[:optimize_when_continue]

        # Pre-process the AST for # of occurrences of each run-flag used
        # t = ExtractRunFlagTable.new
        # t.process(node)
        # @run_flag_table = t.run_flag_table
        # extract_volatiles(node)
        # process(node)
        node
      end
    end
  end
end
