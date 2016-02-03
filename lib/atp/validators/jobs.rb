module ATP
  module Validators
    class Jobs < Validator
      def setup
        @conflicting = []
        @negative = []
      end

      def on_completion
        failed = false
        unless @conflicting.empty?
          Origen.log.error 'if_job and unless_job conditions cannot both be applied to the same tests'
          Origen.log.error "The following conflicts were found in flow #{flow.name}:"
          @conflicting.each do |a, b|
            a_condition = a.to_a[1] ? 'if_job:    ' : 'unless_job:'
            b_condition = b.to_a[1] ? 'if_job:    ' : 'unless_job:'
            Origen.log.error "  #{a_condition} #{a.source}"
            Origen.log.error "  #{b_condition} #{b.source}"
            Origen.log.error ''
          end
          failed = true
        end

        unless @negative.empty?
          Origen.log.error 'Job names should not be negated, use unless_job if you want to specify !JOB'
          Origen.log.error "The following negative job names were found in flow #{flow.name}:"
          @negative.each do |node|
            Origen.log.error "  #{node.to_a[0]} #{node.source}"
          end
          failed = true
        end

        failed
      end

      def on_job(node)
        jobs, state, *nodes = *node
        jobs = [jobs].flatten
        if jobs.any? { |j| j.to_s =~ /^(!|~)/ }
          @negative << node
        end
        @stack ||= []
        if !@stack.empty? && @stack.last[1] != state
          @conflicting << [@stack.last[0], node]
        else
          @stack << [node, state]
          process_all(node)
          @stack.pop
        end
      end
    end
  end
end
