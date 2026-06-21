require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email addresses" do
    user = User.new(name: "Taylor", email_address: " TAYLOR@Example.com ", password: "password1234")

    assert user.valid?
    assert_equal "taylor@example.com", user.email_address
  end

  test "requires a name and valid unique email" do
    user = User.new(email_address: users(:owner).email_address, password: "password1234")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:email_address], "has already been taken"
  end
end
