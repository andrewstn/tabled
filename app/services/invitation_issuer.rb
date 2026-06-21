class InvitationIssuer
  attr_reader :invitation

  def initialize(organization:, invited_by:, attributes:)
    @organization = organization
    @invitation = organization.invitations.new(attributes.merge(invited_by: invited_by))
  end

  def create
    Invitation.transaction do
      revoke_matching_expired_invitations
      invitation.save!
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    invitation.errors.add(:email, "already has a pending invitation") if invitation.errors.empty?
    false
  end

  private

  def revoke_matching_expired_invitations
    normalized_email = invitation.email.to_s.strip.downcase
    return if normalized_email.blank?

    @organization.invitations.unresolved
      .where("lower(email) = ?", normalized_email)
      .where(expires_at: ...Time.current)
      .update_all(revoked_at: Time.current, updated_at: Time.current)
  end
end
