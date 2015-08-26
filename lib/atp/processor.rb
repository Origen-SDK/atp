require 'ast'
module ATP
  # The base processor, this provides a default handler for
  # all node types and will not make any changes to the AST,
  # i.e. an equivalent AST will be returned by the process method.
  #
  # Child classes of this should be used to implement additional
  # processors to modify or otherwise work with the AST.
  #
  # @see http://www.rubydoc.info/gems/ast/2.0.0/AST/Processor
  class Processor < ::AST::Processor
    attr_reader :tests_with_dependents

    def initialize
      @tests_with_dependents = []
    end

    # Process nodes where all of their children are also nodes
    def on_node_with_node_children(node)
      node.updated(nil, process_all(node))
    end
    alias_method :on_flow, :on_node_with_node_children
    alias_method :on_on_fail, :on_node_with_node_children
    alias_method :on_on_pass, :on_node_with_node_children

    def on_condition(node)
      children = node.children.dup
      name = children.shift
      state = children.shift
      node.updated(nil, [name, state, process_all(children)].flatten)
    end
    alias_method :on_flow_flag, :on_condition
    alias_method :on_test_result, :on_condition

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

    def n(type, children)
      ATP::AST::Node.new(type, children)
    end

    def n0(type)
      n(type, [])
    end
  end
end
