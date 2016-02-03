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

The AST can then be rendered by a 3rd party to any required format, for example the
test flow file for a given ATE platform, documentation, etc.

Various validations are automatically performed on a generated AST to ensure that the
logic is valid and will be able to render correctly to a ATE test program file.

A runner is also provided to execute the test flow under a given set of flow conditions
and or a list of tests to assume failure on.

### Examples

Creating a new flow, a program is a top level container for a collection of test
flows:

~~~ruby
program = ATP::Program.new

flow = program.flow(:probe1)
~~~

The flow's AST is initially empty:

~~~ruby
flow.ast   # => (flow)
~~~
