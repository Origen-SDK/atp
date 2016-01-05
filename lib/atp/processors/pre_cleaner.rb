module ATP
  module Processors
    # Modifies the AST by performing some basic clean up, mainly to sanitize
    # user input. For example it will ensure that all IDs are symbols, and that
    # all names are lower-cased strings.
    class PreCleaner < Processor
      def initialize
        @group_ids = []
      end

      def on_id(node)
        id = node.to_a.first
        id = id.to_s.downcase.to_sym
        node.updated(nil, [id])
      end

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
    end
  end
end
