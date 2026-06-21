class OrganizationCreator
  attr_reader :organization

  def initialize(owner:, attributes:)
    @owner = owner
    @organization = Organization.new(attributes)
  end

  def create
    organization.slug = available_slug

    Organization.transaction do
      organization.save!
      organization.memberships.create!(user: @owner, role: :owner)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def available_slug
    base = organization.name.to_s.parameterize.presence || "organization"
    candidate = base
    suffix = 2

    while Organization.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    candidate
  end
end
