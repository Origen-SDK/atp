module ATP
  # This class is responsible for executing the given test flow based on a given
  # set of runtime conditions.
  # A subset of the input AST will be returned containing only the nodes that would
  # be hit when the flow is executed under the given conditions.
  class Runner < Processor
    def run(node, options = {})
      @options = options
      @completed = false
      @groups = []
      process(Processors::AddIDs.new.run(node))
    end

    def on_flow(node)
      @flow = []
      process_all(node.children)
      node.updated(nil, @flow)
    end

    def on_flow_flag(node)
      flag, enabled, *nodes = *node
      flag = [flag].flatten
      active = flag.any? { |f| flow_flags.include?(f) }
      if (enabled && active) || (!enabled && !active)
        process_all(nodes)
      end
    end

    def on_run_flag(node)
      flag, enabled, *nodes = *node
      flag = [flag].flatten
      active = flag.any? { |f| run_flags.include?(f) }
      if (enabled && active) || (!enabled && !active)
        process_all(nodes)
      end
    end

    def on_test(node)
      if id = node.find(:id)
        id = id.to_a[0]
        if failed_test_ids.include?(id)
          node = node.add(n0(:failed))
          failed = true
        end
      end
      @flow << node unless completed?
      if failed
        # Give indication to the parent group that at least one test within it failed
        if @groups.last
          @groups.pop
          @groups << false
        end
        if n = node.find(:on_fail)
          @continue = !!n.find(:continue)
          process_all(n)
          @continue = false
        end
      else
        if n = node.find(:on_pass)
          process_all(n)
        end
      end
    end

    def on_group(node)
      @groups << true  # This will be set to false by any tests that fail within the group
      process_all(node.find(:members))
      if !@groups.pop # If failed
        if n = node.find(:on_fail)
          @continue = !!n.find(:continue)
          process_all(n)
          @continue = false
        end
      else
        if n = node.find(:on_pass)
          process_all(n)
        end
      end
    end

    def on_members(node)
      # Do nothing, will be processed directly by the on_group handler
    end

    def on_test_result(node)
      id, passed, *nodes = *node
      if (passed && !failed_test_ids.include?(id)) ||
         (!passed && failed_test_ids.include?(id))
        process_all(nodes)
      end
    end

    def on_set_result(node)
      unless @continue
        @flow << node unless completed?
        @completed = true
      end
    end

    def on_set_run_flag(node)
      run_flags << node.to_a[0]
    end

    def on_enable_flow_flag(node)
      flow_flags << node.value unless flow_flags.include?(node.value)
    end

    def on_disable_flow_flag(node)
      flow_flags.delete(node.value)
    end

    def on_log(node)
      @flow << node unless completed?
    end
    alias_method :on_render, :on_log

    def on_job(node)
      jobs, state, *nodes = *node
      jobs = clean_job(jobs)
      unless job
        fail 'Flow contains JOB-based conditions and no current JOB has been given!'
      end
      if state
        process_all(node) if jobs.include?(job)
      else
        process_all(node) unless jobs.include?(job)
      end
    end

    def clean_job(job)
      [job].flatten.map { |j| j.to_s.upcase }
    end

    def job
      @options[:job].to_s.upcase if @options[:job]
    end

    def failed_test_ids
      @failed_test_ids ||= [@options[:failed_test_id] || @options[:failed_test_ids]].flatten.compact
    end

    def run_flags
      @run_flags ||= []
    end

    # Returns an array of enabled flow flags
    def flow_flags
      @flow_flags ||= [@options[:flow_flag] || @options[:flow_flags]].flatten.compact
    end

    def completed?
      @completed
    end
  end
end
