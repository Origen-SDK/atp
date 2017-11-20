module ATP
  module Processors
    # Removes any empty on_pass and on_fail branches
    class EmptyBranchRemover < Processor
      # Delete any on-fail child if it's 'empty'
      def on_test(node)
        if on_pass = node.find(:on_pass)
          node = node.remove(on_pass) if on_pass.children.empty?
        end
        if on_fail = node.find(:on_fail)
          node = node.remove(on_fail) if on_fail.children.empty?
        end
        node = node.updated(nil, process_all(node.children))
      end
    end
  end
end
