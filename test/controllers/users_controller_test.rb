require "test_helper"

describe UsersController do
  describe "auth_callback" do
    it "logs in an existing user and redirects to the root route" do
      # Count the users, to make sure we're not (for example) creating
      # a new user every time we get a login request
      start_count = User.count

      # Get a user from the fixtures
      user = users(:grace)

      # Tell OmniAuth to use this user's info when it sees
      # an auth callback from github
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))

      # Send a login request for that user
      # Note that we're using the named path for the callback, as defined
      # in the `as:` clause in `config/routes.rb`
      get auth_callback_path(:github)

      must_redirect_to root_path

      # Since we can read the session, check that the user ID was set as expected
      session[:user_id].must_equal user.id

      # Should *not* have created a new user
      User.count.must_equal start_count
    end

    it "creates a new user and redirects to the root route" do
      start_count = User.count
      user = User.new(provider: "github", uid: 99999, name: "test_user", email: "test@user.com")

      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
      get auth_callback_path(:github)

      must_redirect_to root_path

      # Should have created a new user
      User.count.must_equal start_count + 2

      # The new user's ID should be set in the session
      session[:user_id].must_equal User.last.id
    end
    
    it "redirects to the login route if given invalid user data" do
      start_count = User.count
      user = User.new(provider: "github", uid: 34343, name: "", email: "test@user.com")
      
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
      get auth_callback_path(:github)
      
      must_redirect_to root_path
      
      User.count.must_equal start_count
      expect(session[:user_id]).must_be_nil
    end
  end
  
  describe "destroy" do
    it "ends a user's session" do
      user = users(:grace)
      perform_login(user)
      
      delete logout_path
    
      
      expect(session[:user_id]).must_be_nil
      
      must_redirect_to root_path
    end
  end
end
