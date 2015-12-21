module ATP
  module Processors
    # This optimizes the condition nodes such that any adjacent flow nodes that
    # have the same condition, will be grouped together under a single condition
    # wrapper.
    #
    # For example this AST:
    #
    #   (flow
    #     (group "g1"
    #       (test
    #         (name "test1"))
    #       (flow-flag "bitmap" true
    #         (test
    #           (name "test2"))))
    #     (flow-flag "bitmap" true
    #       (group "g1"
    #         (flow-flag "x" true
    #           (test
    #             (name "test3")))
    #         (flow-flag "y" true
    #           (flow-flag "x" true
    #             (test
    #               (name "test4")))))))
    #
    # Will be optimized to this:
    #
    #   (flow
    #     (group "g1"
    #       (test
    #         (name "test1"))
    #       (flow-flag "bitmap" true
    #         (test
    #           (name "test2"))
    #         (flow-flag "x" true
    #           (test
    #             (name "test3"))
    #           (flow-flag "y" true
    #             (test
    #               (name "test4")))))))
    #
    class Condition < Processor
      CONDITION_NODES = [:flow_flag, :test_result, :test_executed, :group, :job]

      def process(node)
        # Bit of a hack - To get all of the nested conditions optimized away it is necessary
        # to execute this recursively a few times. This guard ensures that the recursion is
        # only performed on the top-level and not on every process operation.
        if @top_level_called
          super
        else
          @top_level_called = true
          ast1 = nil
          ast2 = node
          while ast1 != ast2
            ast1 = super(ast2)
            ast2 = super(ast1)
          end
          @top_level_called = false
          ast1
        end
      end

      def on_boolean_condition(node)
        children = node.children.dup
        name = children.shift
        state = children.shift
        children = optimize_siblings(n(:temp, children))
        if condition_to_be_removed?(node)
          process_all(children)
        else
          node.updated(nil, [name, state] + process_all(children))
        end
      end
      alias_method :on_flow_flag, :on_boolean_condition
      alias_method :on_test_result, :on_boolean_condition
      alias_method :on_test_executed, :on_boolean_condition

      def on_condition(node)
        children = node.children.dup
        name = children.shift
        children = optimize_siblings(n(:temp, children))
        if condition_to_be_removed?(node)
          process_all(children)
        else
          node.updated(nil, [name] + process_all(children))
        end
      end
      alias_method :on_group, :on_condition
      alias_method :on_job, :on_condition

      # Returns true if the given node contains the given condition within
      # its immediate children
      def has_condition?(condition, node)
        ([node] + node.children.to_a).any? do |n|
          if n.is_a?(ATP::AST::Node)
            equal_conditions?(condition, n)
          end
        end
      end

      def condition_to_be_removed?(node)
        remove_condition.last && equal_conditions?(remove_condition.last, node)
      end

      def equal_conditions?(node1, node2)
        if node1.type == node2.type
          if node1.type == :group || node1.type == :job
            node1.to_a.take(1) == node2.to_a.take(1)
          else
            node1.to_a.take(2) == node2.to_a.take(2)
          end
        end
      end

      def condition?(node)
        node.is_a?(ATP::AST::Node) && CONDITION_NODES.include?(node.type)
      end

      def on_flow(node)
        node.updated(nil, optimize_siblings(node))
      end

      def optimize_siblings(top_node)
        children = []
        unprocessed_children = []
        current = nil
        last = top_node.children.size - 1
        top_node.to_a.each_with_index do |node, i|
          # If a condition has been identified in a previous node
          if current
            process_nodes = false
            # If this node has the current condition, then buffer it for later processing
            # and continue to the next node
            if has_condition?(current, node)
              unprocessed_children << node
              node = nil
            else
              process_nodes = true
            end
            if process_nodes || i == last
              remove_condition << current
              current_children = current.children + [process_all(unprocessed_children)].flatten
              unprocessed_children = []
              remove_condition.pop
              children << process(current.updated(nil, current_children))
              if node && (!condition?(node) || i == last)
                current = nil
                children << process(node)
              else
                current = node
              end
            end
          else
            if condition?(node) && i != last
              current = node
            else
              children << process(node)
            end
          end
        end
        children.flatten
      end

      def remove_condition
        @remove_condition ||= []
      end
    end
  end
end
