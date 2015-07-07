# This file defines the users associated with your project, it is basically the 
# mailing list for release notes.
#
# You can split your users into "admin" and "user" groups, the main difference 
# between the two is that admin users will get all tag emails, users will get
# emails on external/official releases only.
#
# Users are also prohibited from running the "origen rc tag" command, but this is 
# really just to prevent a casual user from executing it inadvertently and is
# not intended to be a serious security gate.
module Origen
  module Users
    def users
      @users ||= [

        # Admins - Notified on every tag
        User.new("stephen", "stephen", :admin),

        # Users - Notified on official release tags only
        #User.new("Stephen McGinty", "r49409"),
        # The r-number attribute can be anything that can be prefixed to an 
        # @freescale.com email address, so you can add mailing list references
        # as well like this:
        #User.new("Origen Users", "origen"),  # The Origen mailing list
        
      ]
    end
  end
end
