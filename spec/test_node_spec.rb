require 'spec_helper'

describe 'Test nodes' do
  it "can capture limit information" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, limits: [{ value: 5, rule: :lte}, { value: 1, rule: :gt, units: :mV }]

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:limit, 5, "lte"),
           s(:limit, 1, "gt", "mV")))
  end

  it "can capture target pin information" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, pin: { name: :pinx }
    flow.test :test2, pins: [{ name: :pinx}, { name: :piny}]

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:pin, "pinx")),
         s(:test,
           s(:object, "test2"),
           s(:pin, "pinx"),
           s(:pin, "piny")))
  end

  it "can include level information" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, level: { name: :vdd, value: 1.5 }
    flow.test :test2, levels: [{ name: :vdd, value: 1.1}, { name: :vddc, value: 700, units: :mV}]

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:level, "vdd", 1.5)),
         s(:test,
           s(:object, "test2"),
           s(:level, "vdd", 1.1),
           s(:level, "vddc", 700, "mV")))
  end

  it "can include arbitrary attributes/meta data" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, meta: { frequency: 25, cz: true }
    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:meta,
             s(:attribute, "frequency", 25),
             s(:attribute, "cz", true))))
  end

  it "bin nodes can include a description" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, bin: 5, bin_description: "This is bad news"

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:on_fail,
             s(:set_result, "fail",
               s(:bin, 5, "This is bad news")))))
  end

  it "can capture a list of patterns" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, pattern: "my_pattern"
    flow.test :test2, patterns: ["my_pat1", { name: "my_pat2", path: "production/flash" }]

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:pattern, "my_pattern")),
         s(:test,
           s(:object, "test2"),
           s(:pattern, "my_pat1"),
           s(:pattern, "my_pat2", "production/flash")))
  end

  it "can include sub-tests" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, 
      sub_tests: [
        flow.sub_test(:test1_s1, limits: [{ value: 5, rule: :lte}, { value: 1, rule: :gt, units: :mV }]),
        flow.sub_test(:test1_s2, bin: 10),
    ]

    flow.ast.should ==
       s(:flow,
         s(:name, "sort1"),
         s(:test,
           s(:object, "test1"),
           s(:sub_test,
             s(:object, "test1_s1"),
             s(:limit, 5, "lte"),
             s(:limit, 1, "gt", "mV")),
           s(:sub_test,
             s(:object, "test1_s2"),
             s(:on_fail,
               s(:set_result, "fail",
                 s(:bin, 10))))))
  end
end