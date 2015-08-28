module ATP
  # The outputter is responsible for rendering the given AST to the console,
  # a file or a string.
  # A formatter is required to define how each node should be formatted.
  class Outputter < Processor

      #def process(node, options={})
      #  # On first call extract the test_result nodes from the given AST,
      #  # then process as normal thereafter
      #  if @first_call_done
      #    result = super
      #  else
      #    @first_call_done = true
      #    t = ExtractTestResults.new
      #    t.process(node)
      #    @test_results = t.results || {}
      #    result = super
      #    @first_call_done = false
      #  end
      #  result
      #end

  end
end
