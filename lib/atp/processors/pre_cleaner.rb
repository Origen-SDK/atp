module ATP
  module Processors
    # Modifies the AST by performing some basic clean up, mainly to sanitize
    # user input. For example it will ensure that all IDs are symbols, and that
    # all names are lower-cased strings.
    class PreCleaner < Processor
      def initialize
        @group_ids = []
      end

      # Make all IDs lower cased symbols
      def on_id(node)
        id = node.to_a[0]
        node.updated(nil, [clean(id)])
      end

      # Make all ID references use the lower case symbols
      def on_test_executed(node)
        children = node.children.dup
        children[0] = clean(children[0])
        node.updated(nil, process_all(children))
      end
      alias_method :on_test_result, :on_test_executed

      def on_group(node)
        if id = node.children.find { |n| n.type == :id }
          @group_ids << process(id).value
        else
          @group_ids << nil
        end
        group = node.updated(nil, process_all(node.children))
        @group_ids.pop
        group
      end

      def on_test(node)
        # Remove IDs nodes from test nodes if they refer to the ID of a parent group
        if @group_ids.last
          children = node.children.reject do |n|
            if n.type == :id
              @group_ids.last == process(n).value
            end
          end
        else
          children = node.children
        end
        node.updated(nil, process_all(children))
      end

      def clean(id)
        if id.is_a?(Array)
          id.map { |i| clean(i) }
        else
          id.to_s.downcase.to_sym
        end
      end
    end
  end
end
