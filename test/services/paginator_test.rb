require "test_helper"

class PaginatorTest < ActiveSupport::TestCase
  test "paginates an active record relation without loading all records" do
    relation = Organization.order(:id)
    3.times { |index| Organization.create!(name: "Group #{index}", slug: "group-#{index}") }
    paginator = Paginator.new(relation, page: 2, per_page: 2)

    assert_equal 2, paginator.page
    assert_equal 2, paginator.per_page
    assert_equal 5, paginator.total_count
    assert_equal 3, paginator.first_item
    assert_equal 4, paginator.last_item
    assert_equal 1, paginator.previous_page
    assert_equal 3, paginator.next_page
    assert_equal 2, paginator.records.size
  end

  test "normalizes invalid and out of range pages" do
    relation = Organization.order(:id)

    assert_equal 1, Paginator.new(relation, page: -4, per_page: 1).page
    assert_equal relation.count, Paginator.new(relation, page: 999, per_page: 1).page
  end
end
