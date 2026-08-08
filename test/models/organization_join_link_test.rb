require "test_helper"

class OrganizationJoinLinkTest < ActiveSupport::TestCase
  test "generates a verifiable token without persisted token data" do
    link = create_join_link

    assert_predicate link.token, :present?
    assert_equal link, OrganizationJoinLink.find_by_token(link.token)
    assert_not OrganizationJoinLink.column_names.any? { |name| name.include?("token") }
  end

  test "only permits member as the public role" do
    link = build_join_link(role: :owner)

    assert_not link.valid?
    assert_includes link.errors[:role], "is not included in the list"
  end

  test "tracks disabled expired and full availability" do
    assert_not build_join_link(active: false).available?
    assert_not build_join_link(expires_at: 1.minute.ago).available?
    assert_not build_join_link(max_uses: 2, uses_count: 2).available?
    assert build_join_link(expires_at: 1.day.from_now, max_uses: 2, uses_count: 1).available?
  end

  test "requires a positive max use limit" do
    link = build_join_link(max_uses: 0)

    assert_not link.valid?
  end

  test "invalid tokens safely return nil" do
    assert_nil OrganizationJoinLink.find_by_token("not-a-real-token")
  end

  private

  def create_join_link(**attributes)
    build_join_link(**attributes).tap(&:save!)
  end

  def build_join_link(**attributes)
    OrganizationJoinLink.new({
      organization: organizations(:film_society),
      created_by: users(:owner),
      label: "Autumn Involvement Fair",
      role: :member
    }.merge(attributes))
  end
end
