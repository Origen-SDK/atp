require 'ast'
module ATP
  module AST
    class Node < ::AST::Node
      include Factories

      def initialize(type, children = [], properties = {})
        # Always use strings instead of symbols in the AST, makes serializing
        # back and forward to a string easier
        children = children.map { |c| c.is_a?(Symbol) ? c.to_s : c }
        super type, children, properties
      end

      # Create a new node from the given S-expression (a string)
      def self.from_sexp(sexp)
        @parser ||= Parser.new
        @parser.string_to_ast(sexp)
      end

      # Adds an empty node of the given type to the children unless another
      # node of the same type is already present
      def ensure_node_present(type)
        if children.any? { |n| n.type == type }
          self
        else
          updated(nil, children + [n0(type)])
        end
      end

      # Add the given nodes to the children
      def add(*nodes)
        updated(nil, children + nodes)
      end
    end
  end
end
