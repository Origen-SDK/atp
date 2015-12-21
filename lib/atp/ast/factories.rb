module ATP
  module AST
    module Factories
      def n(type, *children)
        ATP::AST::Node.new(type, children)
      end

      def n0(type)
        ATP::AST::Node.new(type, [])
      end
    end
  end
end
