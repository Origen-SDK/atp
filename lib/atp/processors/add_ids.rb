module ATP
  module Processors
    # Assigns an ID to all test nodes that don't have one
    class AddIDs < Processor
      def run(node)
        @i = 0
        process(node)
      end

      def on_test(node)
        @i += 1
        node = node.ensure_node_present(:id)
        node.updated(nil, process_all(node))
      end

      def on_id(node)
        unless node.value
          node.updated(nil, ["t#{@i}"])
        end
      end
    end
  end
end
