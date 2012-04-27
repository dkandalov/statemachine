require File.dirname(__FILE__) + '/spec_helper'

shared_examples_for "FSM" do
  it "handles :dollar event when :waiting" do
    @mock_context = mock("context")
    @mock_context.should_receive(:sales_mode)

    create_fsm

    @vending_machine.state.should == :waiting

    @mock_context.should_receive(:operation_mode).once.ordered
    @mock_context.should_receive(:activate).once.ordered
    @vending_machine.dollar
    @vending_machine.state.should == :paid
  end

  it "handles :selection event when :waiting" do
    @mock_context = mock("context")
    @mock_context.should_receive(:sales_mode).twice

    create_fsm

    @vending_machine.state.should == :waiting

    @mock_context.should_receive(:operation_mode).once.ordered
#    @mock_context.should_receive(:sales_mode)
    @vending_machine.selection
    @vending_machine.state.should == :waiting
  end

  it "handles :dollar event when :paid" do
    @mock_context = mock("context")
    @mock_context.should_receive(:sales_mode)

    create_fsm

    @vending_machine.state = :paid

    @mock_context.should_receive(:refund).once.ordered
    @vending_machine.dollar
    @vending_machine.state.should == :paid
  end

  it "handles :selection event when :paid" do
    @mock_context = mock("context")
    @mock_context.should_receive(:sales_mode).twice

    create_fsm

    @vending_machine.state = :paid

    @mock_context.should_receive(:release).once.ordered
    @vending_machine.selection
    @vending_machine.state.should == :waiting
  end
end

describe "Builder with tabular syntax and legend" do
  it_should_behave_like "FSM"

  def create_fsm
    mc = @mock_context
    @vending_machine = Statemachine.build_with_tables do
               #    w       p
      trans :w,   :sel,   :dol
      trans :p,   :sel,   :dol
           #    w    p
      on_entry :sm, :__
      on_exit  :om, :__
               #    w      p
      act_on :sel, :__,  :rel
      act_on :dol, :act, :ref

      context mc

      legend({
              :w => :waiting,
              :p => :paid,
              :sel => :selection,
              :dol => :dollar,
              :sm => :sales_mode,
              :om => :operation_mode,
              :act => :activate,
              :rel => :release,
              :ref => :refund,
              :__ => :none
      })
    end
  end
end

describe "Builder with tabular syntax" do
  it_should_behave_like "FSM"

  def create_fsm
    mc = @mock_context
    @vending_machine = Statemachine.build_with_tables do
      #                 waiting    paid
      trans :waiting, :selection, :dollar
      trans :paid,    :selection, :dollar
      #           waiting       paid
      on_entry :sales_mode,     :none
      on_exit  :operation_mode, :none
      #                  waiting      paid
      act_on :selection, :none,     :release
      act_on :dollar,    :activate, :refund
      context mc
    end
  end
end   

describe "Miss Grant's Controller" do
  it_should_behave_like "FSM"

  def create_fsm
    controller_context = @controller_context
    @miss_grant_controller = Statemachine.build_with_tables do
      #                       idle        active       waitForDraw    waitForLight    unlocked
      trans :idle,         :none,        :door_closed,  :none,        :none,          :none
      trans :active,       :door_opened, :none,         :light_on,    :draw_opened,   :none
      trans :waitForDraw,  :door_opened, :none,         :none,        :none,          :draw_opened
      trans :waitForLight, :door_opened, :none,         :none,        :none,          :light_on
      trans :unlocked,     :door_opened, :none,         :none,        :none,          :none
      
      #            idle        active       waitForDraw    waitForLight    unlocked
      on_entry :lock_panel,    :none,         :none,          :none,     :unlock_panel
      on_exit  :none,          :none,         :none,          :none,     :none
      
      context controller_context
    end
  end
end

describe "Builder with usual syntax" do
  it_should_behave_like "FSM"

  def create_fsm
    mc = @mock_context
    @vending_machine = Statemachine.build do
      state :waiting do
        event :dollar, :paid, :activate
        event :selection, :waiting
        on_entry :sales_mode
        on_exit :operation_mode
      end
      trans :paid, :selection, :waiting, :release
      trans :paid, :dollar, :paid, :refund
      context mc
    end
  end
end