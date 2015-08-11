module MakeFlaggable
  class Flagging < ActiveRecord::Base
    belongs_to :flaggable, polymorphic: true, counter_cache: true
    belongs_to :flagger, polymorphic: true
    scope :with_flag, lambda { |flag| where(flag: flag.to_s) }
    scope :with_flaggable, lambda { |flaggable| where(flaggable_type: flaggable.class.name, flaggable_id: flaggable.id) }
    scope :ignored, lambda { where(ignored: true) }
    scope :unignored, lambda { where(ignored: false) }

    def ignore
      self.class.transaction do
        update_attribute(:ignored, true)
        flaggable.class.decrement_counter(:flaggings_count, flaggable.id)
      end
    end

    def unignore
      self.class.transaction do
        update_attribute(:ignored, false)
        flaggable.class.increment_counter(:flaggings_count, flaggable.id)
      end
    end

    def self.ignore_all(conditions = nil)
      if conditions
        where(conditions).ignore_all
      else
        all.each {|object| object.ignore }
      end
    end
  end
end
