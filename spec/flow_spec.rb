require 'spec_helper'

describe 'The flow builder API' do
  include ATP::FlowAPI
  
  before :each do
    self.atp = ATP::Program.new.flow(:sort1) 
  end

  it 'is alive' do
    atp.program.should be
    atp.raw.should be
  end

  it "tests can be added" do
    test :test1, on_fail: { bin: 5 }
    test :test2, on_fail: { bin: 6, continue: true }
    atp.raw.should ==
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

  it "on_fail can be supplied via a block" do
    test :test1, on_fail: -> do
      bin 5
      continue
    end

    test :test2, on_pass: -> do
      pass 1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 5)),
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:on_pass,
            s(:set_result, "pass",
              s(:bin, 1)))))
  end

  it "conditions can be specified in-line" do
    test :test1, id: :t1
    test :test2, id: "T2" # Test that strings will be accepted for IDs
    test :test3, if_enabled: "bitmap"
    test :test4, unless_enabled: "bitmap", if_failed: :t1

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:object, "test2"),
          s(:id, "T2")),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test3"))),
        s(:if_failed, :t1,
          s(:unless_enabled, "bitmap",
            s(:test,
              s(:object, "test4")))))
  end

  it "conditions can be specified via a block" do
    test :test1, id: :t1
    if_enabled "bitmap", then: -> do
      test :test2
    end, else: -> do
      test :test3, if_failed: :t1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:else, 
            s(:if_failed, :t1,
              s(:test,
                s(:object, "test3"))))))
  end

  it "conditions can be specified via a block 2" do
    test :test1, id: :t1
    if_enabled "bitmap" do
      test :test2
      test :test3, if_failed: :t1
    end

    atp.raw.should ==
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

  it "groups can be added" do
    test :test1
    group "g1", id: :g1 do
      test :test2
      test :test3
      group "g2" do
        test :test4
        test :test5
      end
    end

    atp.raw.should ==
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
    test :test1
    group "g1", id: :g1 do
      test :test2
      test :test3
    end
    group "g2", if_failed: :g1 do
      atp.test :test4
      atp.test :test5
    end
    atp.raw.should ==
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
            s(:object, "test3"))),
        s(:if_failed, :g1,
          s(:group, 
            s(:name, "g2"),
            s(:test,
              s(:object, "test4")),
            s(:test,
              s(:object, "test5")))))
  end

  describe "tests of individual APIs" do
    it "atp.test" do
      test("test1")
      atp.raw.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:test,
            s(:object, "test1")))
    end

    it "atp.test with bin numbers" do
      test("test1", bin: 1, softbin: 10, continue: true)
      atp.raw.should ==
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

    it "atp.test with bin descriptions" do
      test("test1", bin: 1, softbin: 10, continue: true)
      test("test2", bin: 2, bin_description: 'hbin2 fails', softbin: 20, continue: true)
      test("test3", bin: 3, softbin: 30, softbin_description: 'sbin3 fails', continue: true)
      test("test4", bin: 4, bin_description: 'hbin4 fails', softbin: 40, softbin_description: 'sbin4 fails', continue: true)
   
      atp.raw.should ==
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
      
      atp.raw.find_all(:test).each do |test_node|
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

    it "atp.cz with enable words" do
      if_enable :cz do
        cz :test1, :cz1
      end
      cz :test1, :cz1, if_enable: :cz

      atp.raw.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:if_enabled, "cz",
            s(:cz, "cz1",
              s(:test,
                s(:object, "test1")))),
          s(:if_enabled, "cz",
            s(:cz, "cz1",
              s(:test,
                s(:object, "test1")))))
    end

    it "tests of context_changed?" do
      context_changed?.should == false
      context_changed?({}).should == false
      test :test1
      context_changed?({}).should == false
      context_changed?(if_enable: "bitmap").should == true
      context_changed?({}).should == false
      if_enable :blah do
        context_changed?({}).should == true
      end
      context_changed?({}).should == false
      if_enable :blah do
        test :test1
        context_changed?({}).should == false
        context_changed?(if_flag: 'my_flag').should == true
        context_changed?(if_enable: :blah).should == false
        context_changed?(if_enable: 'blah').should == false
      end
    end

    it 'can capture volatile flags and bin descriptions' do
      self.atp = ATP::Program.new.flow(:sort1) 
      volatile :flag1, :flag2
      volatile :flag3

      atp.raw.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:volatile,
            s(:flag, "flag1"),
            s(:flag, "flag2"),
            s(:flag, "flag3"))) 

      self.atp = ATP::Program.new.flow(:sort1) 
      describe_bin 10, 'Bin10'
      describe_softbin 100, 'Soft Bin100'

      atp.raw.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:bin_descriptions,
            s(:hard, 10, "Bin10"),
            s(:soft, 100, "Soft Bin100")))

      # Test case for both

      self.atp = ATP::Program.new.flow(:sort1) 
      volatile :flag1, :flag2
      volatile :flag3
      describe_bin 10, 'Bin10'
      describe_softbin 100, 'Soft Bin100'

      atp.raw.should ==
        s(:flow,
          s(:name, "sort1"),
          s(:volatile,
            s(:flag, "flag1"),
            s(:flag, "flag2"),
            s(:flag, "flag3")), 
          s(:bin_descriptions,
            s(:hard, 10, "Bin10"),
            s(:soft, 100, "Soft Bin100")))
    end
  end
end
