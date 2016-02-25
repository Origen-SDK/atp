module ATP
  module Processors
    # This optimizes the condition nodes such that any adjacent flow nodes that
    # have the same condition, will be grouped together under a single condition
    # wrapper.
    #
    # For example this AST:
    #
    #   (flow
    #     (group
    #       (name "g1")
    #       (test
    #         (name "test1"))
    #       (flow-flag "bitmap" true
    #         (test
    #           (name "test2"))))
    #     (flow-flag "bitmap" true
    #       (group
    #         (name "g1")
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
    #     (group
    #       (name "g1")
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
        remove_condition << node
        children = extract_common_embedded_conditions(n(:temp, children))
        remove_condition.pop
        if condition_to_be_removed?(node)
          process_all(children)
        else
          node.updated(nil, [name, state] + process_all(children))
        end
      end
      alias_method :on_flow_flag, :on_boolean_condition
      alias_method :on_test_result, :on_boolean_condition
      alias_method :on_test_executed, :on_boolean_condition
      alias_method :on_job, :on_boolean_condition

      def on_group(node)
        children = node.children.dup
        name = children.shift
        remove_condition << node
        children = extract_common_embedded_conditions(n(:temp, children))
        remove_condition.pop
        if condition_to_be_removed?(node)
          process_all(children)
        else
          node.updated(nil, [name] + process_all(children))
        end
      end

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
        remove_condition.any? { |c| equal_conditions?(c, node) }
      end

      def equal_conditions?(node1, node2)
        if node1.type == node2.type
          if node1.type == :group
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
        name, *nodes = *node
        nodes = extract_common_embedded_conditions(nodes)
        node.updated(nil, [name] + nodes)
      end

      def extract_common_embedded_conditions(nodes)
        nodes = [nodes] unless nodes.is_a?(Array)
        result = []
        cond_a = nil
        test_a = nil
        ConditionExtractor.new.run(nodes).each do |cond_b, test_b|
          if cond_a
            common = cond_a & cond_b
            if common.empty?
              result << combine(cond_a, extract_common_embedded_conditions(test_a))
              cond_a = cond_b
              test_a = test_b
            else
              a = combine(cond_a - common, test_a)
              b = combine(cond_b - common, test_b)
              cond_a = common
              test_a = [a, b].flatten
            end
          else
            cond_a = cond_b
            test_a = test_b
          end
        end
        if nodes == [test_a]
          nodes
        else
          result << combine(cond_a, extract_common_embedded_conditions(test_a))
          result.flatten
        end
      end

      def combine(conditions, node)
        if conditions && !conditions.empty?
          conditions.reverse_each do |n|
            node = n.updated(nil, n.children + (node.is_a?(Array) ? node : [node]))
          end
        end
        node
      end

      def remove_condition
        @remove_condition ||= []
      end
    end
  end
end
