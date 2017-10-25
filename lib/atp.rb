require 'origen'
require_relative '../config/application.rb'

module ATP
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
  autoload :Processor, 'atp/processor'
  autoload :Validator, 'atp/validator'
  autoload :Runner, 'atp/runner'
  autoload :Formatter, 'atp/formatter'
  autoload :Parser, 'atp/parser'
  autoload :FlowAPI, 'atp/flow_api'

  module AST
    autoload :Node, 'atp/ast/node'
    autoload :Factories, 'atp/ast/factories'
    autoload :Extractor, 'atp/ast/extractor'
  end

  # Processors actually modify the AST to clean and optimize the user input
  # and to implement the flow control API
  module Processors
    autoload :Condition,    'atp/processors/condition'
    autoload :Relationship, 'atp/processors/relationship'
    autoload :PreCleaner, 'atp/processors/pre_cleaner'
    autoload :Marshal, 'atp/processors/marshal'
    autoload :AddIDs, 'atp/processors/add_ids'
    autoload :AddSetResult, 'atp/processors/add_set_result'
    autoload :FlowID, 'atp/processors/flow_id'
    autoload :EmptyBranchRemover, 'atp/processors/empty_branch_remover'
    autoload :AppendTo, 'atp/processors/append_to'
    autoload :Flattener, 'atp/processors/flattener'
    autoload :RedundantConditionRemover, 'atp/processors/redundant_condition_remover'
    autoload :ElseRemover, 'atp/processors/else_remover'
    autoload :OnPassFailRemover, 'atp/processors/on_pass_fail_remover'
    autoload :ApplyPostGroupActions, 'atp/processors/apply_post_group_actions'
    autoload :OneFlagPerTest, 'atp/processors/one_flag_per_test'
    autoload :FlagOptimizer, 'atp/processors/flag_optimizer'
    autoload :AdjacentIfCombiner, 'atp/processors/adjacent_if_combiner'
    autoload :ContinueImplementer, 'atp/processors/continue_implementer'
  end

  # Summarizers extract summary data from the given AST
  module Summarizers
  end

  # Validators are run on the processed AST to check it for common errors or
  # logical issues that will prevent it being rendered to a test program format
  module Validators
    autoload :DuplicateIDs, 'atp/validators/duplicate_ids'
    autoload :MissingIDs, 'atp/validators/missing_ids'
    autoload :Condition, 'atp/validators/condition'
    autoload :Jobs, 'atp/validators/jobs'
  end

  # Formatters are run on the processed AST to display the flow or to render
  # it to a different format
  module Formatters
    autoload :Basic,   'atp/formatters/basic'
    autoload :Datalog, 'atp/formatters/datalog'
    autoload :Graph,   'atp/formatters/graph'
  end

  # Maintains a unique ID counter to ensure that all nodes get a unique ID
  def self.next_id
    @next_id ||= 0
    @next_id += 1
  end
end
