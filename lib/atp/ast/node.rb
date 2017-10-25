require 'ast'
module ATP
  module AST
    class Node < ::AST::Node
      attr_reader :file, :line_number, :description
      attr_accessor :id

      def initialize(type, children = [], properties = {})
        # Always use strings instead of symbols in the AST, makes serializing
        # back and forward to a string easier
        children = children.map { |c| c.is_a?(Symbol) ? c.to_s : c }
        super type, children, properties
      end

      def source
        if file
          "#{file}:#{line_number}"
        else
          '<Sorry, lost the source file info, please include an example if you report as a bug>'
        end
      end

      # Create a new node from the given S-expression (a string)
      def self.from_sexp(sexp)
        @parser ||= Parser.new
        @parser.string_to_ast(sexp)
      end

      # Adds an empty node of the given type to the children unless another
      # node of the same type is already present
      def ensure_node_present(type, *child_nodes)
        if children.any? { |n| n.type == type }
          self
        else
          if !child_nodes.empty?
            node = updated(type, child_nodes)
          else
            node = updated(type, [])
          end
          updated(nil, children + [node])
        end
      end

      # Returns the value at the root of an AST node like this:
      #
      #   node # => (module-def
      #               (module-name
      #                 (SCALAR-ID "Instrument"))
      #
      #   node.value  # => "Instrument"
      #
      # No error checking is done and the caller is responsible for calling
      # this only on compatible nodes
      def value
        val = children.first
        val = val.children.first while val.respond_to?(:children)
        val
      end

      # Add the given nodes to the children
      def add(*nodes)
        updated(nil, children + nodes)
      end

      # Remove the given nodes from the children
      def remove(*nodes)
        updated(nil, children - nodes)
      end

      # Returns the first child node of the given type(s) that is found
      def find(*types)
        children.find { |c| types.include?(c.try(:type)) }
      end

      # Returns an array containing all child nodes of the given type(s)
      def find_all(*types)
        children.select { |c| types.include?(c.try(:type)) }
      end

      # Returns an array containing all flags which are set within the given node
      def set_flags
        Processors::ExtractSetFlags.new.run(self)
      end
    end
  end
end
