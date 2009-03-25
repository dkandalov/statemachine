require File.dirname(__FILE__) + '/spec_helper'

shared_examples_for "minimal FSM" do
  it "handles events and goes through states" do
    vending_machine = create_fsm
    
    vending_machine.state = :waiting
    vending_machine.selection
    vending_machine.state.should == :waiting
    vending_machine.dollar
    vending_machine.state.should == :paid

    vending_machine.state = :paid
    vending_machine.dollar
    vending_machine.state.should == :paid
    vending_machine.selection
    vending_machine.state.should == :waiting
  end
end

describe "Builder with usual syntax" do
  it_should_behave_like "minimal FSM"
  
  def create_fsm
    Statemachine.build do
      trans :waiting, :dollar, :paid
      trans :paid, :selection, :waiting
      trans :waiting, :selection, :waiting
      trans :paid, :dollar, :paid
    end
  end
end

describe "Builder with tabular syntax" do
  it_should_behave_like "minimal FSM"
  
  def create_fsm
    Statemachine.build_with_tables do
                     #  waiting    paid
      trans :waiting, :selection, :dollar
      trans :paid,    :selection, :dollar
    end    
  end
end