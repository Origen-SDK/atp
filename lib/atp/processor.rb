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
  class Processor
    include ::AST::Processor::Mixin

    def process(node)
      if node.respond_to?(:to_ast)
        super(node)
      else
        node
      end
    end

    def handler_missing(node)
      node.updated(nil, process_all(node.children))
    end

    def n(type, children)
      ATP::AST::Node.new(type, children)
    end

    def n0(type)
      n(type, [])
    end

    def n1(type, arg)
      n(type, [arg])
    end
  end
end
