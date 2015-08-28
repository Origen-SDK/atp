require 'spec_helper'

describe 'AST Nodes' do

  it "can be exported to a string and back again" do
    node = 
      s(:flow,
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2")),
          s(:test_result, :t1, false,
            s(:test,
              s(:name, "test3")))))
  
    ATP::AST::Node.from_sexp(node.to_sexp).to_sexp.should == node.to_sexp
  end

end
