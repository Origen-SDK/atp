module ATP
  module Processors
    # Removes any empty on_pass and on_fail branches
    class SubFlowRemover < Processor
      # Delete any on-fail child if it's 'empty'
      def on_sub_flow(node)
        node.updated(:remove, nil)
      end
    end
  end
end
