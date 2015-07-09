module ATP
  module AST
    class Builder
      def flow
        n0(:flow)
      end

      def name(str)
        n(:name, [str.to_s])
      end

      def test(name, options = {})
        children = [self.name(name)]
        children << bin(options[:bin]) if options[:bin]
        children << softbin(options[:softbin]) if options[:softbin]
        children << continue if options[:continue]
        n(:test, children)
      end

      def bin(val)
        n(:bin, [val.to_i])
      end

      def softbin(val)
        n(:softbin, [val.to_i])
      end

      def continue
        n0(:continue)
      end

      private

      def n(type, children)
        Node.new(type, children)
      end

      def n0(type)
        n(type, [])
      end
    end
  end
end
