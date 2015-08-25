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

      def flow_flag(name, enabled, node)
        n(:flow_flag, [name, enabled, node])
      end

      def test_result(id, passed, node)
        n(:test_result, [id, passed, node])
      end

      def apply_conditions(node, conditions)
        conditions.each do |key, value|
          key = key.to_s.downcase.to_sym
          case key
          when :if_enabled, :enabled, :enable_flag
            node = flow_flag(value, true, node)
          when :unless_enabled, :not_enabled, :disabled
            node = flow_flag(value, false, node)
          when :if_failed
            node = test_result(value, false, node)
          else
            fail "Unknown test condition attribute - #{key} (#{val})"
          end
        end
        node
      end

      def test(name, options = {})
        children = [self.name(name)]

        d = options[:description] || options[:desc]
        children << description(d) if d
        children << id(options[:id].to_s.downcase.to_sym) if options[:id]

        children << on_fail(options[:on_fail]) if options[:on_fail]
        children << on_pass(options[:on_pass]) if options[:on_pass]

        children << if_failed(options[:if_failed]) if options[:if_failed]

        test = n(:test, children)

        if options[:conditions]
          apply_conditions(test, options[:conditions])
        else
          test
        end
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
