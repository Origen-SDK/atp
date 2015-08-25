require 'ast'
module ATP
  module Processor
    # The base processor, this provides a default handler for
    # all node types and will not make any changes to the AST,
    # i.e. an equivalent AST will be returned by the process method.
    #
    # Child classes of this should be used to implement additional
    # processors to modify or otherwise work with certain elements
    # of the AST.
    #
    # @see http://www.rubydoc.info/gems/ast/2.0.0/AST/Processor
    class Base < ::AST::Processor
      attr_reader :tests_with_dependents

      def initialize
        @tests_with_dependents = []
      end

      def process_terminal_node(node)
        node
      end
      alias_method :on_continue, :process_terminal_node
      alias_method :on_bin, :process_terminal_node
      alias_method :on_softbin, :process_terminal_node
      alias_method :on_name, :process_terminal_node
      alias_method :on_description, :process_terminal_node
      alias_method :on_id, :process_terminal_node
      alias_method :on_if_failed, :process_terminal_node

      def process_regular_node(node)
        node.updated(nil, process_all(node))
      end
      alias_method :on_flow, :process_regular_node
      alias_method :on_on_fail, :process_regular_node
      alias_method :on_on_pass, :process_regular_node

      def process_condition_node(node)
        node.updated(nil, process_all(node))
      end
      alias_method :on_flow_flag, :process_condition_node
      alias_method :on_test_result, :process_condition_node

      def on_test(node)
        children = process_all(node)
        children.each do |child|
          if child.type == :if_failed
            id = child.children.first
            tests_with_dependents << id unless tests_with_dependents.include?(id)
          end
        end
        node.updated(nil, children)
      end
    end
  end
end
