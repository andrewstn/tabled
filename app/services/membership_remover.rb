class MembershipRemover
  def initialize(membership:)
    @membership = membership
  end

  def remove
    success = false

    Membership.transaction do
      owners = @membership.organization.memberships.owner.lock.to_a

      if @membership.owner? && owners.one?
        @membership.errors.add(:base, "Every organization needs at least one owner")
        raise ActiveRecord::Rollback
      end

      success = @membership.destroy
      raise ActiveRecord::Rollback unless success
    end

    success
  end
end
