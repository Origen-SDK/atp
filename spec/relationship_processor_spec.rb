require 'spec_helper'

describe 'The Relationship Processor' do

  it "updates both sides of the relationship" do
    ast =
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:name, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:bin, 10))),
        s(:test_result, :t1, true,
          s(:test,
            s(:name, "test3"))),
        s(:test_result, :t2, true,
          s(:test,
            s(:name, "test4"))),
        s(:test_result, :t2, false,
          s(:test,
            s(:name, "test5"))))
    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:name, "test1"),
          s(:id, :t1),
          s(:on_pass,
            s(:set_run_flag, "t1_PASSED")),
          s(:on_fail,
            s(:continue))),
        s(:test,
          s(:name, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:bin, 10),
            s(:continue),
            s(:set_run_flag, "t2_FAILED")),
          s(:on_pass,
            s(:set_run_flag, "t2_PASSED"))),
        s(:run_flag, "t1_PASSED", true,
          s(:test,
            s(:name, "test3"))),
        s(:run_flag, "t2_PASSED", true,
          s(:test,
            s(:name, "test4"))),
        s(:run_flag, "t2_FAILED", true,
          s(:test,
            s(:name, "test5"))))

  end

  it "embedded test results are processed" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (object "test1")
          (id "ect1_1"))
        (test-result "ect1_1" false
          (test
            (object "test2"))
          (test
            (object "test3")
            (id "ect1_3"))
          (test-result "ect1_3" false
            (test
              (object "test4")))))
                END

    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    ast2 = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (object "test1")
          (id "ect1_1")
          (on-fail
            (set-run-flag "ect1_1_FAILED")
            (continue)))
        (run-flag "ect1_1_FAILED" true
          (test
            (object "test2"))
          (test
            (object "test3")
            (id "ect1_3")
            (on-fail
              (set-run-flag "ect1_3_FAILED")
              (continue)))
          (run-flag "ect1_3_FAILED" true
            (test
              (object "test4")))))

    END
    p.process(ast).should == ast2
  end

  it "any failed is processed" do
    ast = 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "t2")),
        s(:test_result, ["t1", "t2"], false,
          s(:test,
            s(:object, "test3"))))

    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    ast2 =
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:set_run_flag, "t1_FAILED"),
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:id, "t2"),
          s(:on_fail,
            s(:set_run_flag, "t2_FAILED"),
            s(:continue))),
        s(:run_flag, ["t1_FAILED", "t2_FAILED"], true,
          s(:test,
            s(:object,"test3"))))
    p.process(ast).should == ast2

  end

  it "group-based if_failed is processed" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (group
          (name "group1")
          (id "grp1")
          (test
            (object "test1"))
          (test
            (object "test2")))

        (test-result "grp1" false
          (test
            (object "test3"))
          (test
            (object "test4"))))
                END

    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    ast2 = to_ast <<-END
      (flow
        (name "sort1")
        (group
          (name "group1")
          (id "grp1")
          (test
            (object "test1"))
          (test
            (object "test2"))
          (on-fail
            (set-run-flag "grp1_FAILED")
            (continue)))

        (run-flag "grp1_FAILED" true
          (test
            (object "test3"))
          (test
            (object "test4"))))
    END
    p.process(ast).should == ast2
  end

  it "group-based if_passed is processed" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (group
          (name "group1")
          (id "grp1")
          (test
            (object "test1"))
          (test
            (object "test2")))

        (test-result "grp1" true
          (group
            (name "group2")
            (test
              (object "test3"))
            (test
              (object "test4")))))
                END

    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    ast2 = to_ast <<-END
      (flow
        (name "sort1")
        (group
          (name "group1")
          (id "grp1")
          (test
            (object "test1"))
          (test
            (object "test2"))
          (on-pass
            (set-run-flag "grp1_PASSED"))
          (on-fail
            (continue)))

        (run-flag "grp1_PASSED" true
          (group
            (name "group2")
            (test
              (object "test3"))
            (test
              (object "test4")))))
    END
    p.process(ast).should == ast2
  end
end
