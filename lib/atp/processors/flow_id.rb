module ATP
  module Processors
    # Adds the flow ID to all ids and label names
    class FlowID < Processor
      attr_reader :id

      def run(node, id)
        @id = id
        process(node)
      end

      def on_id(node)
        node.updated(nil, ["#{node.value}_#{id}"])
      end

      def on_test_result(node)
        tid, state, nodes = *node
        if tid.is_a?(Array)
          tid = tid.map { |tid| "#{tid}_#{id}" }
        else
          tid = "#{tid}_#{id}"
        end
        node.updated(nil, [tid, state] + [process(nodes)])
      end
      alias_method :on_test_executed, :on_test_result
    end
  end
end
