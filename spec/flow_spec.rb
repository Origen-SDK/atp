require 'spec_helper'

describe 'The flow builder API' do
  
  def new_flow
    ATP::Program.new.flow(:sort1) 
  end

  it 'is alive' do
    prog = ATP::Program.new
    flow = prog.flow(:sort1)
    flow.program.should == prog
    flow.raw.should be
  end

  it "tests can be added" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, on_fail: { bin: 5 }
    flow.test :test2, on_fail: { bin: 6, continue: true }
    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 5)))),
        s(:test,
          s(:object, "test2"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 6)),
            s(:continue))))
  end

  it "conditions can be specified" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, id: :t1
    flow.test :test2, id: "T2" # Test that strings will be accepted for IDs
    flow.test :test3, conditions: { if_enabled: "bitmap" }
    flow.test :test4, conditions: { unless_enabled: "bitmap", if_failed: :t1 }
    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:object, "test3"))),
        s(:test_result, :t1, false,
          s(:flow_flag, "bitmap", false,
            s(:test,
              s(:object, "test4")))))
  end

  it "groups can be added" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1
    flow.group "g1", id: :g1 do
      flow.test :test2
      flow.test :test3
      flow.group "g2" do
        flow.test :test4
        flow.test :test5
      end
    end
    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group, 
          s(:name, "g1"),
          s(:id, :g1),
          s(:test,
            s(:object, "test2")),
          s(:test,
            s(:object, "test3")),
          s(:group, 
            s(:name, "g2"),
            s(:test,
              s(:object, "test4")),
            s(:test,
              s(:object, "test5")))))
  end

  it "group dependencies are applied" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1
    flow.group "g1", id: :g1 do
      flow.test :test2
      flow.test :test3
    end
    flow.group "g2", conditions: { if_failed: :g1 } do
      flow.test :test4
      flow.test :test5
    end
    flow.ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group, 
          s(:name, "g1"),
          s(:id, :g1),
          s(:test,
            s(:object, "test2")),
          s(:test,
            s(:object, "test3")),
          s(:on_fail,
            s(:set_run_flag, "g1_FAILED"),
            s(:continue))),
        s(:run_flag, "g1_FAILED", true,
          s(:group, 
            s(:name, "g2"),
            s(:test,
              s(:object, "test4")),
            s(:test,
              s(:object, "test5")))))
  end

  describe "tests of individual APIs" do
    it "flow.test" do
      f = new_flow
      f.test("test1")
      f.ast.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:test,
            s(:object, "test1")))

    end

    it "flow.test with bin numbers" do
      f = new_flow
      f.test("test1", bin: 1, softbin: 10, continue: true)
      f.ast.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 1),
                s(:softbin, 10)),
              s(:continue))))
    end

    it "flow.test with bin descriptions" do
      f = new_flow
      f.test("test1", bin: 1, softbin: 10, continue: true)
      f.test("test2", bin: 2, bin_description: 'hbin2 fails', softbin: 20, continue: true)
      f.test("test3", bin: 3, softbin: 30, softbin_description: 'sbin3 fails', continue: true)
      f.test("test4", bin: 4, bin_description: 'hbin4 fails', softbin: 40, softbin_description: 'sbin4 fails', continue: true)
   
      f.ast.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 1),
                s(:softbin, 10)),
              s(:continue))),
          s(:test,
            s(:object, "test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 2, "hbin2 fails"),
                s(:softbin, 20)),
              s(:continue))),
          s(:test,
            s(:object, "test3"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 3),
                s(:softbin, 30, "sbin3 fails")),
              s(:continue))),
          s(:test,
            s(:object, "test4"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 4, "hbin4 fails"),
                s(:softbin, 40, "sbin4 fails")),
              s(:continue))))
      
      f.ast.find_all(:test).each do |test_node|
        set_result_node = test_node.find(:on_fail).find(:set_result)
        case test_node.find(:object).try(:value)
          when 'test1'
            set_result_node.find(:bin).try(:value).should == 1
            set_result_node.find(:bin).to_a[1].should == nil
            set_result_node.find(:softbin).try(:value).should == 10
            set_result_node.find(:softbin).to_a[1].should == nil
          when 'test2'
            set_result_node.find(:bin).try(:value).should == 2
            set_result_node.find(:bin).to_a[1].should == 'hbin2 fails'
            set_result_node.find(:softbin).try(:value).should == 20
            set_result_node.find(:softbin).to_a[1].should == nil
          when 'test3'
            set_result_node.find(:bin).try(:value).should == 3
            set_result_node.find(:bin).to_a[1].should == nil
            set_result_node.find(:softbin).try(:value).should == 30
            set_result_node.find(:softbin).to_a[1].should == 'sbin3 fails'
          when 'test4'
            set_result_node.find(:bin).try(:value).should == 4
            set_result_node.find(:bin).to_a[1].should == 'hbin4 fails'
            set_result_node.find(:softbin).try(:value).should == 40
            set_result_node.find(:softbin).to_a[1].should == 'sbin4 fails'
        end
      end
    end

    it "flow.cz with enable words" do
      flow = ATP::Program.new.flow(:sort1) 
      flow.with_condition if_enable: :cz do
        flow.cz :test1, :cz1
      end
      flow.cz :test1, :cz1, conditions: { if_enable: :cz }
      flow.ast.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:flow_flag, "cz", true,
            s(:cz, "cz1",
              s(:test,
                s(:object, "test1"))),
            s(:cz, "cz1",
              s(:test,
                s(:object, "test1")))))
    end
  end
end
