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
        if node.value =~ /^extern/
          node
        else
          node.updated(nil, ["#{node.value}_#{id}"])
        end
      end

      def on_test_result(node)
        tid, state, nodes = *node
        if tid.is_a?(Array)
          tid = tid.map do |tid|
            if tid =~ /^extern/
              tid
            else
              "#{tid}_#{id}"
            end
          end
        else
          if tid !~ /^extern/
            tid = "#{tid}_#{id}"
          end
        end
        node.updated(nil, [tid, state] + [process(nodes)])
      end
      alias_method :on_test_executed, :on_test_result
    end
  end
end
