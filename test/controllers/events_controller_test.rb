require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "organization member can view upcoming and past gatherings" do
    sign_in_as(users(:member))

    get organization_events_path(organizations(:film_society))

    assert_response :success
    assert_select "h1", "Gatherings"
    assert_select "h2", "Upcoming gatherings"
    assert_select "h2", "Past gatherings"
    assert_select "h3", events(:upcoming_film_night).title
    assert_select "h3", events(:past_planning_table).title
    assert_select ".role-tag", text: "Maybe"
  end

  test "non-member cannot view organization gatherings" do
    sign_in_as(users(:member))

    get organization_events_path(organizations(:garden_club))

    assert_response :not_found
  end

  test "organization member can view a gathering" do
    sign_in_as(users(:member))

    get organization_event_path(organizations(:film_society), events(:upcoming_film_night))

    assert_response :success
    assert_select "h1", events(:upcoming_film_night).title
    assert_select "h2", "Gathering details"
    assert_select "h2", "Your RSVP"
    assert_select ".role-tag", text: "Maybe"
    assert_select "p", text: /Organizer access includes/, count: 0
    assert_select "h2", "Who’s coming"
    assert_select "h2", "Your status"
    assert_select "#member-event-status dd", text: "Maybe"
    assert_select "#member-event-status dd", text: "You haven’t checked in yet."
    assert_select "#member-check-in-guidance", text: /Your organizer will share a code/
  end

  test "member attendee list is limited and reports additional members" do
    event = events(:upcoming_film_night)
    8.times do |index|
      user = User.create!(name: "Attending Member #{index}", email_address: "attendee-#{index}@example.test", password: "password1234")
      membership = Membership.create!(organization: organizations(:film_society), user: user, role: :member)
      event.rsvps.create!(membership: membership, status: :attending)
    end
    sign_in_as(users(:member))

    get organization_event_path(organizations(:film_society), event)

    assert_response :success
    assert_select "#member-attendees li", count: 6
    assert_select "#member-attendees p", text: "and 3 more members"
  end

  test "organizer sees RSVP roster context" do
    sign_in_as(users(:owner))

    get organization_event_path(organizations(:film_society), events(:upcoming_film_night))

    assert_response :success
    assert_select "h2", "Event roster"
    assert_select "li", text: users(:owner).name
    assert_select "li", text: users(:member).name
    assert_select "dt", text: "Attending"
    assert_select "dd", text: "1"
    assert_select "a[href=?]", organization_event_attendance_path(organizations(:film_society), events(:upcoming_film_night)), text: "Attendance sheet"
    assert_select "h2", text: /Check-in not started/
    assert_select "[aria-label='Organizer tools']", count: 1
    assert_select "#member-attendees", count: 0
    assert_select "#member-event-status", count: 0
    assert_select "#member-check-in-guidance", count: 0
  end

  test "ordinary member cannot view the event roster" do
    events(:upcoming_film_night).attendance_records.create!(membership: memberships(:film_owner), status: :absent)
    sign_in_as(users(:member))

    get organization_event_path(organizations(:film_society), events(:upcoming_film_night))

    assert_response :success
    assert_select "h2", { text: "Event roster", count: 0 }
    assert_select "a[href=?]", organization_event_attendance_path(organizations(:film_society), events(:upcoming_film_night)), count: 0
    assert_select "[aria-label='Organizer tools']", count: 0
    assert_select "a[href=?]", edit_organization_event_path(organizations(:film_society), events(:upcoming_film_night)), count: 0
    assert_select "form[action=?]", organization_event_path(organizations(:film_society), events(:upcoming_film_night)), count: 0
    assert_select "a[href$='.csv']", count: 0
    assert_select ".role-tag", text: "Absent", count: 0
  end

  test "member sees open check in form and their attendance status" do
    event = events(:upcoming_film_night)
    event.regenerate_check_in_code
    event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    event.attendance_records.create!(membership: memberships(:film_member), status: :late, checked_in_at: Time.current)
    sign_in_as(users(:member))

    get organization_event_path(organizations(:film_society), event)

    assert_response :success
    assert_select "h2", "Member check-in"
    assert_select "input[name='check_in_code']"
    assert_select ".role-tag", text: "Late"
    assert_select "#member-event-status dd", text: "Late"
    assert_select "#member-event-status dd", text: /Checked in/
    assert_select "#member-check-in-guidance", text: /You’re checked in/
  end

  test "member sidebar shows open and closed check in guidance" do
    event = events(:upcoming_film_night)
    event.regenerate_check_in_code
    event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    sign_in_as(users(:member))

    get organization_event_path(organizations(:film_society), event)
    assert_select "#member-check-in-guidance", text: /Enter the shared code/

    event.update!(check_in_opens_at: 2.hours.ago, check_in_closes_at: 1.hour.ago)
    get organization_event_path(organizations(:film_society), event)
    assert_select "#member-check-in-guidance", text: /Check-in has closed for this gathering/
  end

  test "attendance sidebar shows a simple empty state before check in" do
    sign_in_as(users(:owner))

    get organization_event_path(organizations(:film_society), events(:upcoming_film_night))

    assert_response :success
    assert_select "h2", text: /Check-in not started/
    assert_select "p", text: "Attendance has not been recorded yet."
    assert_select "p", text: /Present 0/, count: 0
  end

  test "attendance sidebar shows open state and real checked in count" do
    event = events(:upcoming_film_night)
    event.regenerate_check_in_code
    event.update!(check_in_opens_at: 1.minute.ago, check_in_closes_at: 1.hour.from_now)
    event.attendance_records.create!(membership: memberships(:film_member), status: :present, checked_in_at: Time.current)
    sign_in_as(users(:owner))

    get organization_event_path(organizations(:film_society), event)

    assert_response :success
    assert_select "h2", text: /Check-in is open/
    assert_select "p", text: "1 member checked in."
  end

  test "attendance sidebar shows compact summary when records exist" do
    sign_in_as(users(:owner))

    get organization_event_path(organizations(:film_society), events(:past_planning_table))

    assert_response :success
    assert_select "p", text: /Present\s+1\s+·\s+Late\s+1\s+·\s+Excused\s+0\s+·\s+Absent\s+0/
  end

  test "non-member cannot view an organization gathering" do
    sign_in_as(users(:member))
    garden_event = Event.create!(
      organization: organizations(:garden_club),
      created_by: users(:owner),
      title: "Garden work day",
      starts_at: 1.week.from_now
    )

    get organization_event_path(organizations(:garden_club), garden_event)

    assert_response :not_found
  end

  test "owner can create a gathering" do
    sign_in_as(users(:owner))

    assert_difference("Event.count") do
      post organization_events_path(organizations(:film_society)), params: {
        event: { title: "Camera Workshop", starts_at: 1.week.from_now, location: "Media lab" }
      }
    end

    event = Event.order(:created_at).last
    assert_redirected_to organization_event_path(organizations(:film_society), event)
    assert_equal users(:owner), event.created_by
  end

  test "officer can create a gathering" do
    memberships(:film_member).update!(role: :officer)
    sign_in_as(users(:member))

    assert_difference("Event.count") do
      post organization_events_path(organizations(:film_society)), params: {
        event: { title: "Editing night", starts_at: 1.week.from_now }
      }
    end
  end

  test "coordinator can create and edit a gathering" do
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    assert_difference("Event.count") do
      post organization_events_path(organizations(:film_society)), params: {
        event: { title: "Location scout", starts_at: 1.week.from_now }
      }
    end
    event = Event.order(:created_at).last

    patch organization_event_path(organizations(:film_society), event), params: {
      event: { title: "Campus location scout" }
    }

    assert_redirected_to organization_event_path(organizations(:film_society), event)
    assert_equal "Campus location scout", event.reload.title
  end

  test "member cannot create a gathering" do
    sign_in_as(users(:member))

    assert_no_difference("Event.count") do
      post organization_events_path(organizations(:film_society)), params: {
        event: { title: "Unapproved gathering", starts_at: 1.week.from_now }
      }
    end

    assert_response :forbidden
  end

  test "coordinator cannot delete a gathering" do
    memberships(:film_member).update!(role: :coordinator)
    sign_in_as(users(:member))

    assert_no_difference("Event.count") do
      delete organization_event_path(organizations(:film_society), events(:upcoming_film_night))
    end

    assert_response :forbidden
  end

  test "owner can delete a gathering" do
    sign_in_as(users(:owner))

    assert_difference("Event.count", -1) do
      delete organization_event_path(organizations(:film_society), events(:past_planning_table))
    end

    assert_redirected_to organization_events_path(organizations(:film_society))
  end

  test "invalid gathering renders helpful errors" do
    sign_in_as(users(:owner))

    post organization_events_path(organizations(:film_society)), params: {
      event: { title: "", starts_at: "" }
    }

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Title can't be blank/
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end
end
