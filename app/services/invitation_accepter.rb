class InvitationAccepter
  attr_reader :membership

  def initialize(invitation:, user:)
    @invitation = invitation
    @user = user
  end

  def accept
    success = false

    Invitation.transaction do
      @invitation.lock!

      unless @invitation.pending?
        @invitation.errors.add(:base, inactive_message)
        raise ActiveRecord::Rollback
      end

      unless @invitation.email.casecmp?(@user.email_address)
        @invitation.errors.add(:base, "Sign in with #{@invitation.email} to accept this invitation")
        raise ActiveRecord::Rollback
      end

      if @invitation.organization.memberships.exists?(user: @user)
        @invitation.errors.add(:base, "You are already on this organization’s roster")
        raise ActiveRecord::Rollback
      end

      @membership = @invitation.organization.memberships.create!(user: @user, role: @invitation.role)
      @invitation.update!(accepted_at: Time.current)
      success = true
    end

    success
  rescue ActiveRecord::RecordNotUnique
    @invitation.errors.add(:base, "You are already on this organization’s roster")
    false
  end

  private

  def inactive_message
    return "This invitation has expired" if @invitation.expired?
    return "This invitation has already been accepted" if @invitation.accepted?

    "This invitation is no longer active"
  end
end
