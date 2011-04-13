Ruby library for integrating with Warwick University's SSO system.

You'll need a provider ID, and you'll also need your system adding to
the SSO whitelist.

Put the ruby files in lib/sso, and the yaml file in config (after you've
filled out your details).

Use it like this

    class ApplicationController < ActionController::Base
      helper :all # include all helpers, all the time

  .   include SSO::Client
      before_filter :sso_filter

...

    class MyController < ApplicationController

...     awesome stuff here


Pull requests gratefully received
