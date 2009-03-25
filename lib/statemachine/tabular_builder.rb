module Statemachine
  def self.build_with_tables(&block)
    builder = StatemachineBuilder.new

    tab_builder = TabularBuilder.new
    tab_builder.instance_eval(&block)
    tab_builder.apply_to(builder)

    builder.statemachine.reset
    return builder.statemachine
  end

  class TabularBuilder
    def initialize
      @states = []
      @transition_table = []
      @action_events = []
      @action_table = []
      @on_entry_actions = []
      @on_exit_actions = []
    end  
    
    def trans state, *transitions
      @states << state
      @transition_table << transitions
    end

    def on_entry *args
      @on_entry_actions = args
    end

    def on_exit *args
      @on_exit_actions = args
    end

    def act_on event, *actions
      @action_events << event
      @action_table << actions
    end
    
    def context a_context
      @context = a_context
    end

    def legend legend_data
      @legend_data = legend_data
    end

    def apply_to builder
      apply_legend
      apply_noops
      
      @states.each_with_index do |state, i|
        state_events = @transition_table[i]
        state_events.each_with_index do |event, j|
          dest_state = @states[j]
          action = if @action_events.include?(event)
            event_index = @action_events.index(event)
            @action_table[event_index][i]
          end
          builder.trans(state, event, dest_state, action)
        end

        builder.on_entry_of(state, @on_entry_actions[i]) unless @on_entry_actions.empty?
        builder.on_exit_of(state, @on_exit_actions[i]) unless @on_exit_actions.empty?
      end
      
      builder.context(@context)
    end
    
    private
    
    def apply_legend
      if @legend_data
        legend = Proc.new {|s| @legend_data.has_key?(s) ? @legend_data[s] : s}
      
        @states = @states.map &legend 
        @transition_table = @transition_table.map { |transitions| transitions.map &legend }
        
        @on_entry_actions = @on_entry_actions.map &legend
        @on_exit_actions = @on_exit_actions.map &legend
        
        @action_events = @action_events.map &legend
        @action_table = @action_table.map { |actions| actions.map &legend }
      end
    end
    
    def apply_noops
      noop = Proc.new {|a| a == :none ? nil : a}
      
      @action_table = @action_table.map {|actions| actions.map &noop}
      
      @on_entry_actions = @on_entry_actions.map &noop
      @on_exit_actions = @on_exit_actions.map &noop
    end
  end
end
