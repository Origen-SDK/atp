require 'ast'
module ATP
  module AST
    # Generally like this AST lib, but the immutability of its node objects is a pain
    # for this application, these overrides make a mutable version of it.
    class Node < ::AST::Node

      # Constructs a new instance of Node.
      #
      # The arguments `type` and `children` are converted with `to_sym` and
      # `to_a` respectively. Additionally, the result of converting `children`
      # is frozen. While mutating the arguments is generally considered harmful,
      # the most common case is to pass an array literal to the constructor. If
      # your code does not expect the argument to be frozen, use `#dup`.
      #
      # The `properties` hash is passed to {#assign_properties}.
      def initialize(type, children=[], properties={})
        @type, @children = type.to_sym, children.to_a

        assign_properties(properties)

        @hash = [@type, @children, self.class].hash
      end

      # Returns an updated instance of Node where non-nil arguments replace the
      # corresponding fields of `self`.
      #
      # For example, `Node.new(:foo, [ 1, 2 ]).updated(:bar)` would yield
      # `(bar 1 2)`, and `Node.new(:foo, [ 1, 2 ]).updated(nil, [])` would
      # yield `(foo)`.
      #
      # If the resulting node would be identical to `self`, does nothing.
      #
      # @param  [Symbol, nil] type
      # @param  [Array, nil]  children
      # @param  [Hash, nil]   properties
      # @return [AST::Node]
      def updated(type=nil, children=nil, properties=nil)
        new_type       = type       || @type
        new_children   = children   || @children
        new_properties = properties || {}

        if @type == new_type &&
            @children == new_children &&
            properties.nil?
          self
        else
          send :initialize, new_type, new_children, new_properties
        end
      end
    end
  end
end
