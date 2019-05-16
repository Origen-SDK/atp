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
    autoload :Extractor, 'atp/ast/extractor'

    # This is a shim to help backwards compatibility with ATP v0
    module Builder
      class LazyObject < ::BasicObject
        def initialize(&callable)
          @callable = callable
        end

        def __target_object__
          @__target_object__ ||= @callable.call
        end

        def method_missing(method_name, *args, &block)
          __target_object__.send(method_name, *args, &block)
        end
      end

      # Some trickery to lazy load this to fire a deprecation warning if an app references it
      CONDITION_KEYS ||= LazyObject.new do
        Origen.log.deprecate 'ATP::AST::Builder::CONDITION_KEYS is frozen and is no longer maintained, consider switching to ATP::Flow::CONDITION_KEYS.keys for similar functionality'
        [:if_enabled, :enabled, :enable_flag, :enable, :if_enable, :unless_enabled, :not_enabled,
         :disabled, :disable, :unless_enable, :if_failed, :unless_passed, :failed, :if_passed,
         :unless_failed, :passed, :if_ran, :if_executed, :unless_ran, :unless_executed, :job,
         :jobs, :if_job, :if_jobs, :unless_job, :unless_jobs, :if_any_failed, :unless_all_passed,
         :if_all_failed, :unless_any_passed, :if_any_passed, :unless_all_failed, :if_all_passed,
         :unless_any_failed, :if_flag, :unless_flag, :if_true, :if_false]
      end
    end
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
    autoload :ExtractSetFlags, 'atp/processors/extract_set_flags'
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
    autoload :Flags, 'atp/validators/flags'
  end

  # Formatters are run on the processed AST to display the flow or to render
  # it to a different format
  module Formatters
    autoload :Basic,   'atp/formatters/basic'
    autoload :Datalog, 'atp/formatters/datalog'
  end

  # Maintains a unique ID counter to ensure that all nodes get a unique ID
  def self.next_id
    @next_id ||= 0
    @next_id += 1
  end
end
