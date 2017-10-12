require 'spec_helper'

describe 'The post group action applier' do
  include ATP::FlowAPI

  before :each do
    self.atp = ATP::Program.new.flow(:sort1) 
  end
end
