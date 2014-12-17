module MakeFlaggable
  class Flagging < ActiveRecord::Base
    belongs_to :flaggable, polymorphic: true, counter_cache: true
    belongs_to :flagger, polymorphic: true
    scope :with_flag, lambda { |flag| where(flag: flag.to_s) }
    scope :with_flaggable, lambda { |flaggable| where(flaggable_type: flaggable.class.name, flaggable_id: flaggable.id) }
    
    attr_accessible  :flaggable, :flagger, :flag
  end
end
