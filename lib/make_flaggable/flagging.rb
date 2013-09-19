module MakeFlaggable
  class Flagging < ActiveRecord::Base
    belongs_to :flaggable, :polymorphic => true
    belongs_to :flagger, :polymorphic => true
    scope :with_flag, lambda { |flag| where(:flag => flag.to_s) }
    scope :with_flaggable, lambda { |flaggable| where(:flaggable_type => flaggable.class.name, :flaggable_id => flaggable.id) }

    def flaggable
      @flaggable
    end

    def flaggable=(value)
      @flaggable = value
    end

    def flagger
      @flagger
    end

    def flagger=(value)
      @flagger = value
    end

    def flag
      @flag
    end

    def flag=(value)
      @flag = value
    end
  end
end
