require 'spec_helper'

describe 'The Condition Processor' do

  it "wraps adjacent nodes that share the same conditions" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, id: :t1
    flow.test :test2, conditions: { if_enabled: "bitmap" }
    flow.test :test3, conditions: { if_enabled: "bitmap", if_failed: :t1 }
    flow.raw.should ==
      s(:flow,
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:object, "test2"))),
        s(:test_result, :t1, false,
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:object, "test3")))))
    p = ATP::Processors::Condition.new
    #puts p.process(flow.raw).inspect
    p.process(flow.raw).should ==
      s(:flow,
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:object, "test2")),
          s(:test_result, :t1, false,
            s(:test,
              s(:object, "test3")))))
  end

  it "wraps nested conditions" do
    ast =
      s(:flow,
        s(:test,
          s(:object, "test1")),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:object, "test2"))),
        s(:flow_flag, "bitmap", true,
          s(:flow_flag, "x", true,
            s(:test,
              s(:object, "test3"))),
          s(:flow_flag, "x", true,
            s(:flow_flag, "y", true,
              s(:test,
                s(:object, "test4"))))))
    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:test,
          s(:object, "test1")),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:object, "test2")),
          s(:flow_flag, "x", true,
            s(:test,
              s(:object, "test3")),
            s(:flow_flag, "y", true,
              s(:test,
                s(:object, "test4"))))))
  end

  it "optimizes groups too" do
    ast =
      s(:flow,
        s(:test,
          s(:object, "test1")),
        s(:group, "g1",
          s(:test,
            s(:object, "test2"))),
        s(:group, "g1",
          s(:group, "g2",
            s(:test,
              s(:object, "test3"))),
          s(:group, "g2",
            s(:group, "g3",
              s(:test,
                s(:object, "test4"))))))
    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:test,
          s(:object, "test1")),
        s(:group, "g1",
          s(:test,
            s(:object, "test2")),
          s(:group, "g2",
            s(:test,
              s(:object, "test3")),
            s(:group, "g3",
              s(:test,
                s(:object, "test4"))))))
  end

  it "combined condition and group test" do
    ast =
      s(:flow,
        s(:group, "g1",
          s(:test,
            s(:object, "test1")),
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:object, "test2")))),
        s(:flow_flag, "bitmap", true,
          s(:group, "g1",
            s(:flow_flag, "x", true,
              s(:test,
                s(:object, "test3"))),
            s(:flow_flag, "y", true,
              s(:flow_flag, "x", true,
                s(:test,
                  s(:object, "test4")))))))

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:group, "g1",
          s(:test,
            s(:object, "test1")),
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:object, "test2")),
            s(:flow_flag, "x", true,
              s(:test,
                s(:object, "test3")),
              s(:flow_flag, "y", true,
                s(:test,
                  s(:object, "test4")))))))
  end

  it "optimizes jobs" do
    ast =
      s(:flow,
        s(:job, "p1", true,
          s(:test,
            s(:object, "test1")),
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:object, "test2")))),
        s(:flow_flag, "bitmap", true,
          s(:job, "p1", true,
            s(:flow_flag, "x", true,
              s(:test,
                s(:object, "test3"))),
            s(:flow_flag, "y", true,
              s(:flow_flag, "x", true,
                s(:test,
                  s(:object, "test4")))))))

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:job, "p1", true,
          s(:test,
            s(:object, "test1")),
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:object, "test2")),
            s(:flow_flag, "x", true,
              s(:test,
                s(:object, "test3")),
              s(:flow_flag, "y", true,
                s(:test,
                  s(:object, "test4")))))))
  end

  it "job optimization test 2" do
    ast =
      s(:flow,
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test_1"))),
        s(:test,
          s(:object, "test2")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test7"))))

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    ast2 =
      s(:flow,
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test_1"))),
        s(:test,
          s(:object, "test2")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test7"))))
    p.process(ast).should == ast2
  end

  it "job optimization test 3" do
    ast =
      s(:flow,
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test_1"))),
        s(:test,
          s(:object, "test2")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test3"))),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test6"))))

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    ast2 =
      s(:flow,
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test_1"))),
        s(:test,
          s(:object, "test2")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:job, ["p1", "p2"], true,
          s(:test,
            s(:object, "test6"))))
    p.process(ast).should == ast2
  end

  it "test result optimization test" do
    ast = to_ast <<-END
      (flow
        (test
          (object "test1")
          (id "ifallb1"))
        (test
          (object "test2")
          (id "ifallb2"))
        (test-result "ifallb2" false
          (test-result "ifallb1" false
            (test
              (object "test3"))))
        (test-result "ifallb2" false
          (test-result "ifallb1" false
            (test
              (object "test4"))))
        (log "Embedded conditional tests 1")
        (test
          (object "test1")
          (id "ect1_1"))
        (test-result "ect1_1" false
          (test
            (object "test2")))
        (test-result "ect1_1" false
          (test
            (object "test3")
            (id "ect1_3")))
        (test-result "ect1_3" false
          (test-result "ect1_1" false
            (test
              (object "test4")))))
          END

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    ast2 = to_ast <<-END
      (flow
        (test
          (object "test1")
          (id "ifallb1"))
        (test
          (object "test2")
          (id "ifallb2"))
        (test-result "ifallb2" false
          (test-result "ifallb1" false
            (test
              (object "test3"))
            (test
              (object "test4"))))
        (log "Embedded conditional tests 1")
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
    p.process(ast).should == ast2
  end

  it "test result optimization test 2" do
    ast = 
      s(:flow,
        s(:log, "Test that if_any_failed works"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifa1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifa2")),
        s(:test_result, [:ifa1, :ifa2], false,
          s(:test,
            s(:object, "test3"))),
        s(:log, "Test the block form of if_any_failed"),
        s(:test,
          s(:object, "test1"),
          s(:id, "oof_passcode1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "oof_passcode2")),
        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
          s(:test,
            s(:object, "test3"))),
        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
          s(:test,
            s(:object, "test4"))))

    p = ATP::Processors::Condition.new
    #puts p.process(ast).inspect
    ast2 =
      s(:flow,
        s(:log, "Test that if_any_failed works"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifa1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifa2")),
        s(:test_result, [:ifa1, :ifa2], false,
          s(:test,
            s(:object, "test3"))),
        s(:log, "Test the block form of if_any_failed"),
        s(:test,
          s(:object, "test1"),
          s(:id, "oof_passcode1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "oof_passcode2")),
        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))))

    p.process(ast).should == ast2
  end
end
