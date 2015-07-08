require 'origen'
require_relative '../config/application.rb'     
module ATP
  autoload :AST, 'atp/ast'
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
end
