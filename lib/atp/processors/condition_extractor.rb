module ATP
  module Processors
    class ConditionExtractor < Processor
      attr_reader :results, :conditions

      def run(nodes)
        @results = []
        @conditions = []
        process_all(nodes)
        @results
      end

      def on_boolean_condition(node)
        children = node.children.dup
        name = children.shift
        state = children.shift
        conditions << node.updated(nil, [name, state])
        process_all(children)
        conditions.pop
      end
      alias_method :on_flow_flag, :on_boolean_condition
      alias_method :on_test_result, :on_boolean_condition
      alias_method :on_test_executed, :on_boolean_condition
      alias_method :on_job, :on_boolean_condition

      def on_group(node)
        sig = node.children.select { |n| [:id, :name, :on_fail, :on_pass].include?(n.try(:type)) }
        children = node.children.dup
        conditions << node.updated(nil, sig)
        process_all(children - sig)
        conditions.pop
      end

      def on_test(node)
        results << [conditions.uniq, node]
      end
      alias_method :on_log, :on_test
      alias_method :on_enable_flow_flag, :on_test
      alias_method :on_disable_flow_flag, :on_test
      alias_method :on_cz, :on_test
      alias_method :on_set_result, :on_test
      alias_method :on_render, :on_test
    end
  end
end
