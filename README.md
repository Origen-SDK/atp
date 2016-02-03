# Abstract Test Program (ATP)

ATP provides an API to generate a test-platform agnostic flow model.

The flow model is an abstract syntax tree (AST) representation of the test flow, and
it incorporates the following metadata:

* Test flow order
* Test name, test object(instance) name, test number, bin number, softbin number
* Grouping of a collection of tests under a logical group
* Job-based flow logic (e.g. probe1, ft_hot, etc.) 
* Flow flag (enable word) flow logic (e.g. run_zero_defect_tests)
* Runtime flow logic (e.g. execute this test if some other test failed)
* Flow log statements

The AST can then be rendered by a 3rd party to any required format, for example the
test flow file for a given ATE platform, documentation, etc.

Various validations are automatically performed on a generated AST to ensure that the
logic is valid and will be able to render correctly to a ATE test program file.

A runner is also provided to execute the test flow under a given set of flow conditions
and or a list of tests to assume failure on.

This AST model provides the backbone of the OrigenTesters test program generation API, but it has
been separated out as this could also be generally useful in many other applications. e.g. test program
translation and documentation tools, importing a non-Origen test program into the Origen eco-system.

### Examples

Creating a new flow, a program is a top level container for a collection of test
flows:

~~~ruby
program = ATP::Program.new

flow = program.flow(:probe1)
~~~

The flow's AST is initially empty:

~~~ruby
flow.ast   # => s(:flow)
~~~

Add tests like this:

~~~ruby
flow.test "test1"
flow.test "test2"

flow.ast   # => s(:flow,
           #      s(:test,
           #        s(:object, "test1")),
           #      s(:test,
           #        s(:object, "test2")))
~~~

Additional meta data can be added to a test (note that an ID is required to refer to this test in runtime logic):

~~~ruby
flow.test "test2", name: "MyTest", bin: 3, :softbin: 102, number: 1000, id: :t2

flow.ast   # => s(:flow,
           #      s(:test,
           #        s(:object, "test1")),
           #      s(:test,
           #        s(:object, "test2")))
           #      s(:test,
           #        s(:object, "test2"),
           #        s(:name, "MyTest"),
           #        s(:number, 1000),
           #        s(:id, "t2"),
           #        s(:on_fail,
           #          s(:set_result, "fail",
           #          s(:bin, 3),
           #          s(:softbin, 102)))))
~~~

From here on, only the new part of the AST will be shown...

Conditions can be added to gate a test's execution:

~~~ruby
flow.test "test3", conditions: { if_enable: :bitmap, if_job: :probe1 }
flow.test "test4", conditions: { if_enable: :bitmap, unless_job: :probe1 }

flow.ast   # => s(:flow,
           #       ...
           #      s(:flow_flag, "bitmap", true,
           #        s(:job, "probe1", true,
           #          s(:test,
           #            s(:object, "test3"))),
           #        s(:job, "probe1", false,
           #          s(:test,
           #            s(:object, "test4")))))
~~~

Note in the above case, that ATP has been smart enough to combine the two tests under the shared 'if bitmap' condition.

To help application side coding, a condition wrapper API is also available:

~~~ruby
# Produces the same AST as the previous example...

flow.with_condition if_enable: :bitmap do
  flow.test "test3", conditions: { if_job: :probe1 }
  flow.test "test4", conditions: { unless_job: :probe1 }
end
~~~

Runtime relationships between different tests can be established as shown below:

~~~ruby
flow.test "test1", id: :t1
flow.test "test2"
flow.test "test3", conditions: { if_failed: :t1 }
flow.test "test4", conditions: { if_passed: :t1 }

flow.ast   # => s(:flow,
           #       ...
           #      s(:test,
           #        s(:object, "test1"),
           #        s(:id, "t1"),
           #          s(:on_pass,
           #            s(:set_run_flag, "t1_PASSED")),
           #          s(:on_fail,
           #            s(:continue),
           #            s(:set_run_flag, "t1_FAILED"))),
           #      s(:test,
           #        s(:object, "test2")),
           #      s(:run_flag, "t1_FAILED", true,
           #        s(:test,
           #          s(:object, "test3"))),
           #      s(:run_flag, "t1_PASSED", true,
           #        s(:test,
           #        s(:object, "test4"))))
~~~



