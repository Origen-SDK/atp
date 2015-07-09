module ATP
  module AST
    class Builder
      def flow
        n0(:flow)
      end

      def name(str)
        n(:name, [str.to_s])
      end

      def description(str)
        n(:description, [str.to_s])
      end

      def id(symbol)
        n(:id, [symbol.to_sym])
      end

      def if_failed(symbol)
        n(:if_failed, [symbol.to_sym])
      end

      def test(name, options = {})
        children = [self.name(name)]
        children << on_fail(options[:on_fail] || {})
        children << on_pass(options[:on_pass] || {})
        d = options[:description] || options[:desc]
        children << description(d) if d
        children << id(options[:id]) if options[:id]
        children << if_failed(options[:if_failed]) if options[:if_failed]
        n(:test, children)
      end

      def on_fail(options = {})
        children = []
        children << bin(options[:bin]) if options[:bin]
        children << softbin(options[:softbin]) if options[:softbin]
        children << continue if options[:continue]
        n(:on_fail, children)
      end

      def on_pass(options = {})
        children = []
        children << bin(options[:bin]) if options[:bin]
        children << softbin(options[:softbin]) if options[:softbin]
        children << continue if options[:continue]
        n(:on_pass, children)
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
