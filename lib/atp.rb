require 'origen'
require_relative '../config/application.rb'
module ATP
  autoload :AST, 'atp/ast'
  autoload :Processor, 'atp/processor'
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
end
