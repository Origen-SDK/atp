module ATP
  module Optimizers
    # This optimizes the condition nodes such that any adjacent flow nodes that
    # have the same condition, will be grouped together under a single condition
    # wrapper.
    class Condition < Processor

      CONDITION_NODES = [:flow_flag, :test_result]

      def on_condition(node)
        children = node.children.dup
        name = children.shift
        state = children.shift
        n = ATP::AST::Node.new(:temp, children)
        children = optimize_siblings(n)
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
          if n.is_a?(ATP::AST::Node) || n.is_a?(::AST::Node)
            equal_conditions?(condition, n)
          end
        end
      end

      def condition_to_be_removed?(node)
        remove_condition.last && equal_conditions?(remove_condition.last, node)
      end

      def equal_conditions?(node1, node2)
        node1.to_a.take(2) == node2.to_a.take(2)
      end

      def condition?(node)
        CONDITION_NODES.include?(node.type)
      end

      def on_flow(node)
        node.updated(nil, optimize_siblings(node))
      end

      def optimize_siblings(top_node)
        children = []
        unprocessed_children = []
        current = nil
        top_node.to_a.each_with_index do |node, i|
          if current
            process_nodes = false
            if has_condition?(current, node) 
              unprocessed_children << node
              node = nil
            else
              process_nodes = true
            end
            if process_nodes || i == top_node.children.size - 1
              remove_condition << current
              current_children = current.children + [process_all(unprocessed_children)].flatten
              unprocessed_children = []
              remove_condition.pop
              children << current.updated(nil, current_children)
              if node && (!condition?(node) || i == top_node.children.size - 1)
                children << process(node)
              else
                current = node
              end
            end
          else
            if condition?(node) && i != top_node.children.size - 1
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
