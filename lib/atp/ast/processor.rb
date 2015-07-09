require 'ast'
module ATP
  module AST
    # The base processor, this provides a default handler for
    # all node types and will not make any changes to the AST, 
    # i.e. an equivalent AST will be returned by the process method.
    #
    # Child classes of this should be used to implement additional
    # processors to modify or otherwise work with certain elements
    # of the AST.
    #
    # @see http://www.rubydoc.info/gems/ast/2.0.0/AST/Processor
    class Processor < ::AST::Processor
      def process_terminal_node(node)
        node
      end
      alias on_continue process_terminal_node
      alias on_bin process_terminal_node
      alias on_softbin process_terminal_node
      alias on_name process_terminal_node

      def process_regular_node(node)
        node.updated(nil, process_all(node))
      end
      alias on_flow process_regular_node
      alias on_test process_regular_node
      alias on_on_fail process_regular_node
      alias on_on_pass process_regular_node
    end
  end
end
