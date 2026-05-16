# frozen_string_literal: true

# Ensures belongs_to targets live in the same organization as the record.
# Skips nil optionals. For +belongs_to :organization+ compares associated +id+
# to +organization_id+ (Organization rows have no +organization_id+ column).
module TenantScopedAssociations
  extend ActiveSupport::Concern

  class_methods do
    # @param assoc_names [Array<Symbol>] association names on this model
    def validates_same_tenant(*assoc_names)
      names = assoc_names.flatten.map(&:to_sym).freeze
      validate do
        next if organization_id.blank?

        names.each do |name|
          assoc = public_send(name)
          next if assoc.nil?

          same =
            if assoc.is_a?(Organization)
              assoc.id == organization_id
            elsif assoc.respond_to?(:organization_id) && !assoc.organization_id.nil?
              assoc.organization_id == organization_id
            else
              true
            end

          errors.add(name, "must belong to the same organization") unless same
        end
      end
    end
  end
end
