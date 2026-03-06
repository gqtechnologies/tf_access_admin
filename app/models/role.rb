class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  acts_as_tenant(:organization)
  belongs_to :organization

  belongs_to :resource,
             :polymorphic => true,
             :optional => true
  

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true
  
  validates :name, presence: true, inclusion: { in: AvailableRoles::ALL }

  scopify
end
