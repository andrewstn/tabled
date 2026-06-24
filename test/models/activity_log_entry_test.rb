require "test_helper"

class ActivityLogEntryTest < ActiveSupport::TestCase
  test "requires organization action summary and occurred at" do
    entry = ActivityLogEntry.new

    assert_not entry.valid?
    assert_includes entry.errors[:organization], "must exist"
    assert_includes entry.errors[:action], "can't be blank"
    assert_includes entry.errors[:summary], "can't be blank"
  end

  test "belongs to an organization and can have an actor" do
    entry = ActivityLogEntry.create!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "settings.updated",
      summary: "Alex updated organization settings."
    )

    assert_equal organizations(:film_society), entry.organization
    assert_equal users(:owner), entry.actor
  end

  test "can reference a subject" do
    entry = ActivityLogEntry.create!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "event.created",
      subject: events(:upcoming_film_night),
      summary: "Alex created First Friday Film Night."
    )

    assert_equal events(:upcoming_film_night), entry.subject
  end

  test "defaults occurred at and metadata" do
    entry = ActivityLogEntry.create!(
      organization: organizations(:film_society),
      action: "system.note",
      summary: "A system note was recorded."
    )

    assert_not_nil entry.occurred_at
    assert_equal({}, entry.metadata)
  end

  test "stores minimal jsonb metadata" do
    entry = ActivityLogEntry.create!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "member.role_changed",
      summary: "Alex changed Jordan from member to coordinator.",
      metadata: { "from_role" => "member", "to_role" => "coordinator" }
    )

    assert_equal "member", entry.metadata["from_role"]
    assert_equal "coordinator", entry.metadata["to_role"]
  end
end
