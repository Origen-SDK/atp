require 'origen'
require_relative '../config/application.rb'
module ATP
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
  autoload :Processor, 'atp/processor'

  module AST
    autoload :Node, 'atp/ast/node'
    autoload :Builder, 'atp/ast/builder'
  end

  module Optimizers
    autoload :Condition, 'atp/optimizers/condition'
  end
end
