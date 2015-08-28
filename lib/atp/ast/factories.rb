module ATP
  module AST
    module Factories
      def n(type, children)
        ATP::AST::Node.new(type, children)
      end

      def n0(type)
        n(type, [])
      end

      def n1(arg)
        n(type, [arg])
      end
    end
  end
end
