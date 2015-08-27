require 'ast'
module ATP
  module AST
    class Node < ::AST::Node

      # Adds an empty node of the given type to the children unless another
      # node of the same type is already present
      def ensure_node_present(type)
        if children.any? { |n| n.type == type}
          self
        else
          updated(nil, children + [n0(type)])
        end
      end

      # Add the given nodes to the children
      def add(*nodes)
        updated(nil, children + nodes) 
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
end
