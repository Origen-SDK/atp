require 'spec_helper'

describe 'The Condition Processor' do
  include ATP::FlowAPI

  before :each do
    self.flow = ATP::Program.new.flow(:sort1) 
  end

  it "wraps adjacent nodes that share the same conditions" do
    test :test1, id: :t1
    test :test2, if_enabled: "bitmap"
    test :test3, if_enabled: "bitmap", if_failed: :t1

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2"))),
        s(:if_failed, :t1,
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test3")))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:if_failed, :t1,
            s(:test,
              s(:object, "test3")))))
  end

  it "wraps nested conditions" do
    test :test1
    test :test2, if_flag: "bitmap"
    if_flag "bitmap" do
      test :test3, if_flag: "x"
      if_flag "y" do
        test :test4, if_flag: "x"
      end
    end

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "bitmap",
          s(:test,
            s(:object, "test2"))),
        s(:if_flag, "bitmap",
          s(:if_flag, "x",
            s(:test,
              s(:object, "test3"))),
          s(:if_flag, "y",
            s(:if_flag, "x",
              s(:test,
                s(:object, "test4"))))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:if_flag, "x",
            s(:test,
              s(:object, "test3")),
            s(:if_flag, "y",
              s(:test,
                s(:object, "test4"))))))
  end

  it "optimizes groups too" do
    test :test1
    test :test2, group: :g1
    group :g1 do
      group :g2 do
        test :test3
      end
      group :g2 do
        test :test4, group: :g3
      end
    end

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test2"))),
        s(:group,
          s(:name, "g1"),
          s(:group,
            s(:name, "g2"),
            s(:test,
              s(:object, "test3"))),
          s(:group,
            s(:name, "g2"),
            s(:group,
              s(:name, "g3"),
              s(:test,
                s(:object, "test4"))))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test2")),
          s(:group,
            s(:name, "g2"),
            s(:test,
              s(:object, "test3")),
            s(:group,
              s(:name, "g3"),
              s(:test,
                s(:object, "test4"))))))
  end

  it "combined condition and group test" do
    group :g1 do
      test :test1
      test :test2, if_enable: :bitmap
    end

    if_enable :bitmap do
      group :g1 do
        test :test3, if_flag: :x
        if_flag :y do
          test :test4, if_flag: :x
        end
      end
    end

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")))),
        s(:if_enabled, "bitmap",
          s(:group,
            s(:name, "g1"),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3"))),
            s(:if_flag, "y",
              s(:if_flag, "x",
                s(:test,
                  s(:object, "test4")))))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3")),
              s(:if_flag, "y",
                s(:test,
                  s(:object, "test4")))))))
  end

  it "optimizes jobs" do
    if_job :p1 do
      test :test1
      test :test2, if_enable: :bitmap
    end
    if_enabled :bitmap do
      if_job :p1 do
        test :test3, if_flag: :x
        if_flag :y do
          test :test4, if_flag: :x
        end
      end
    end

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, "p1",
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")))),
        s(:if_enabled, "bitmap",
          s(:if_job, "p1",
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3"))),
            s(:if_flag, "y",
              s(:if_flag, "x",
                s(:test,
                  s(:object, "test4")))))))


    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, "p1",
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3")),
              s(:if_flag, "y",
                s(:test,
                  s(:object, "test4")))))))
  end

  it "job optimization test 2" do
    test :test1, if_job: [:p1, :p2]
    test :test2
    test :test3, if_job: [:p1, :p2]
    test :test4
    test :test5, if_job: [:p1, :p2]
    test :test6
    test :test7, if_job: [:p1, :p2]

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test7"))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test7"))))
  end

  it "job optimization test 3" do
    test :test1, if_job: [:p1, :p2]
    test :test2
    test :test3, if_job: [:p1, :p2]
    test :test4, if_job: [:p1, :p2]
    test :test5
    test :test6, if_job: [:p1, :p2]

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test6"))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test6"))))
  end

  it "test result optimization test" do
    test :test1, id: :ifallb1
    test :test2, id: :ifallb2
    if_failed :ifallb1 do
      test :test3, if_failed: :ifallb2
    end
    if_failed :ifallb2 do
      test :test4, if_failed: :ifallb1
    end
    log "Embedded conditional tests 1"
    test :test1, id: :ect1_1
    test :test2, if_failed: :ect1_1
    test :test3, if_failed: :ect1_1, id: :ect1_3
    if_failed :ect1_3 do
      test :test4, if_failed: :ect1_1
    end

    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifallb1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifallb2")),
        s(:if_failed, "ifallb1",
          s(:if_failed, "ifallb2",
            s(:test,
              s(:object, "test3")))),
        s(:if_failed, "ifallb2",
          s(:if_failed, "ifallb1",
            s(:test,
              s(:object, "test4")))),
        s(:log, "Embedded conditional tests 1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ect1_1")),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test2"))),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test3"),
            s(:id, "ect1_3"))),
        s(:if_failed, "ect1_3",
          s(:if_failed, "ect1_1",
            s(:test,
              s(:object, "test4")))))

    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifallb1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifallb2")),
        s(:if_failed, "ifallb1",
          s(:if_failed, "ifallb2",
            s(:test,
              s(:object, "test3")),
            s(:test,
              s(:object, "test4")))),
        s(:log, "Embedded conditional tests 1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ect1_1")),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test2")),
          s(:test,
            s(:object, "test3"),
            s(:id, "ect1_3")),
          s(:if_failed, "ect1_3",
            s(:test,
              s(:object, "test4")))))

  end
#
#  it "test result optimization test 2" do
#    ast = 
#      s(:flow,
#        s(:name, "sort1"),
#        s(:log, "Test that if_any_failed works"),
#        s(:test,
#          s(:object, "test1"),
#          s(:id, "ifa1")),
#        s(:test,
#          s(:object, "test2"),
#          s(:id, "ifa2")),
#        s(:test_result, [:ifa1, :ifa2], false,
#          s(:test,
#            s(:object, "test3"))),
#        s(:log, "Test the block form of if_any_failed"),
#        s(:test,
#          s(:object, "test1"),
#          s(:id, "oof_passcode1")),
#        s(:test,
#          s(:object, "test2"),
#          s(:id, "oof_passcode2")),
#        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
#          s(:test,
#            s(:object, "test3"))),
#        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
#          s(:test,
#            s(:object, "test4"))))
#
#    p = ATP::Processors::Condition.new
#    #puts p.process(ast).inspect
#    ast2 =
#      s(:flow,
#        s(:name, "sort1"),
#        s(:log, "Test that if_any_failed works"),
#        s(:test,
#          s(:object, "test1"),
#          s(:id, "ifa1")),
#        s(:test,
#          s(:object, "test2"),
#          s(:id, "ifa2")),
#        s(:test_result, [:ifa1, :ifa2], false,
#          s(:test,
#            s(:object, "test3"))),
#        s(:log, "Test the block form of if_any_failed"),
#        s(:test,
#          s(:object, "test1"),
#          s(:id, "oof_passcode1")),
#        s(:test,
#          s(:object, "test2"),
#          s(:id, "oof_passcode2")),
#        s(:test_result, [:oof_passcode1, :oof_passcode2], false,
#          s(:test,
#            s(:object, "test3")),
#          s(:test,
#            s(:object, "test4"))))
#
#    p.process(ast).should == ast2
#  end
#
#  it "adjacent group optimization test" do
#    ast = 
#      s(:flow,
#        s(:name, "sort1"),
#        s(:group,
#          s(:name, "additional_erase"),
#          s(:flow_flag, "additional_erase", true,
#            s(:job, ["fr"], true,
#              s(:test,
#                s(:object, "erase_all"))))),
#        s(:group,
#          s(:name, "additional_erase"),
#          s(:job, ["fr"], true,
#            s(:test,
#              s(:object, "erase_all")))))
#
#    p = ATP::Processors::Condition.new
#    #puts p.process(ast).inspect
#    ast2 =
#      s(:flow,
#        s(:name, "sort1"),
#        s(:group,
#          s(:name, "additional_erase"),
#          s(:job, ["fr"], true,
#            s(:flow_flag, "additional_erase", true,
#              s(:test,
#                s(:object, "erase_all"))),
#            s(:test,
#              s(:object, "erase_all")))))
#
#    p.process(ast).should == ast2
#  end
#
#  it "Removes duplicate conditions" do
#    ast = 
#      s(:flow,
#        s(:name, "sort1"),
#        s(:flow_flag, "data_collection", true,
#          s(:flow_flag, "data_collection", true,
#            s(:test,
#              s(:object, "nvm_dist_vcg")))))
#
#    p = ATP::Processors::Condition.new
#    p.process(ast).should == 
#      s(:flow,
#        s(:name, "sort1"),
#        s(:flow_flag, "data_collection", true,
#          s(:test,
#            s(:object, "nvm_dist_vcg"))))
#  end
#
#  it "Flags conditions are not optimized when marked as volatile" do
#    flow = ATP::Program.new.flow(:sort1) 
#    flow.with_conditions if_flag: "my_flag" do
#      flow.test :test1, on_fail: { set_flag: "$My_Mixed_Flag", continue: true }
#      flow.test :test2, conditions: { if_flag: "$My_Mixed_Flag" }
#      flow.test :test1, conditions: { if_flag: "my_flag" }
#      flow.test :test2, conditions: { if_flag: "my_flag" }
#    end
#
#    flow.ast.should ==
#      s(:flow,
#        s(:name, "sort1"),
#        s(:run_flag, "my_flag", true,
#          s(:test,
#            s(:object, "test1"),
#            s(:on_fail,
#              s(:set_run_flag, "$My_Mixed_Flag"),
#              s(:continue))),
#          s(:run_flag, "$My_Mixed_Flag", true,
#            s(:test,
#              s(:object, "test2"))),
#          s(:test,
#            s(:object, "test1")),
#          s(:test,
#            s(:object, "test2"))))
#
#    flow.volatile "my_flag", :$my_other_flag
#
#    flow.ast.should ==
#      s(:flow,
#        s(:name, "sort1"),
#        s(:volatile,
#          s(:flag, "my_flag"),
#          s(:flag, "$my_other_flag")),
#        s(:run_flag, "my_flag", true,
#          s(:test,
#            s(:object, "test1"),
#            s(:on_fail,
#              s(:set_run_flag, "$My_Mixed_Flag"),
#              s(:continue)))),
#        s(:run_flag, "my_flag", true,
#          s(:run_flag, "$My_Mixed_Flag", true,
#            s(:test,
#              s(:object, "test2")))),
#        s(:run_flag, "my_flag", true,
#          s(:run_flag, "my_flag", true,
#            s(:test,
#              s(:object, "test1")))),
#        s(:run_flag, "my_flag", true,
#          s(:run_flag, "my_flag", true,
#            s(:test,
#              s(:object, "test2")))))
#  end
end
