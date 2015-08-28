require 'sexpistol'
module ATP
  class Parser < Sexpistol

    def initialize
      self.ruby_keyword_literals = true
    end

    def string_to_ast(string)
      to_sexp(parse_string(string))
    end

    def to_sexp(ast_array)
      children = ast_array.map do |item|
        if( item.is_a?(Array))
          to_sexp(item)
        else
          item
        end
      end
      type = children.shift
      return type if type.is_a?(ATP::AST::Node)
      ATP::AST::Node.new(type, children)
    end
  end
end
