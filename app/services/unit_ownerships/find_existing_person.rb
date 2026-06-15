# frozen_string_literal: true

module UnitOwnerships
  class FindExistingPerson
    def self.call(**kwargs)
      People::FindExisting.call(**kwargs)
    end
  end
end
