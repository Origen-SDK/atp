require 'spec_helper'

describe 'The AST validators' do

  it "positive and negative job conditions can't be mixed" do
    validator = ATP::Validators::Jobs.new(self)

    ast = s(:flow,
            s(:job, "p1",
              s(:test,
                s(:name, "test1"),
                s(:id, "t1"))))

    validator.test_process(ast).should == false  

    ast = s(:flow,
            s(:job, s(:or, "p1", "p2"),
              s(:test,
                s(:name, "test1"),
                s(:id, "t1"))))

    validator.test_process(ast).should == false  
  end

end
