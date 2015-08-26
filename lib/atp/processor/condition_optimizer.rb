module ATP
  module Processor
    class ConditionOptimizer < Base

      CONDITION_NODES = [:flow_flag, :test_result]

      def on_condition(node)
        children = node.children.dup
        name = children.shift
        state = children.shift
        if condition_to_be_removed?(node)
          process_all(children)
        else
          node.updated(nil, [name, state, process_all(children)].flatten)
        end
      end
      alias_method :on_flow_flag, :on_condition
      alias_method :on_test_result, :on_condition

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
        @remove_condition && equal_conditions?(@remove_condition, node)
      end

      def equal_conditions?(node1, node2)
        node1.to_a.take(2) == node2.to_a.take(2)
      end

      def condition?(node)
        CONDITION_NODES.include?(node.type)
      end

      def on_flow(flow_node)
        children = []
        unprocessed_children = []
        current = nil
        flow_node.children.each_with_index do |node, i|
          if current
            process_nodes = false
            if has_condition?(current, node) 
              unprocessed_children << node
            else
              process_nodes = true
            end
            if process_nodes || i == flow_node.children.size - 1
              @remove_condition = current
              current_children = current.children + [*process_all(unprocessed_children)]
              children << current.updated(nil, current_children)
              @remove_condition = nil
              current = nil
            end
          else
            if condition?(node)
              current = node
            else
              children << process(node)
            end
          end
        end  
        flow_node.updated(nil, children)
      end
    end
  end
end
