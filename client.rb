require 'uri'
require 'net/http'
require 'net/https'
require 'yaml'
require 'sso/user'
require 'sso/memory_cache'

# Performs old-mode SSO against Websignon (i.e.
# checks the WarwickSSO cookie and sends a requestType=1
# to the Websignon sentry to get back user attributes.
#
# Include this module in your ApplicationController.
module SSO
  module Client

    OriginHost = 'websignon.warwick.ac.uk'
    OriginPath = '/origin'

	# cache SSO config in memory for 10 minutes    
    ConfigCacheSeconds = 600

    def sso_filter
      @memcache = MemoryCache.new(:sso_client) unless @memcache

      @sso_config = @memcache.cached("sso_config",ConfigCacheSeconds) do 
        YAML.load_file(File.join(RAILS_ROOT,'config/sso_config.yml'))
      end
      
      @goduserlist = @memcache.cached("goduserlist",ConfigCacheSeconds) do 
        YAML.load_file(File.join(RAILS_ROOT,'config/godusers.yml'))
      end

      # WarwickSSO cookie has gone, so no more logged in for YOU
      if not sso_cookie
        logger.debug "SSO: No cookie, not signed in"
        session[:sso_user] = nil;
      elsif not session[:sso_user]
	      logger.debug "SSO: Cookie: #{sso_cookie}"
	      http = Net::HTTP.new(OriginHost, 443)
	      http.use_ssl = true
	      path = "#{OriginPath}/sentry?requestType=1&token=#{sso_cookie}"
	      resp, data = http.get(path,nil)
	      properties = parse_properties(data)
	      process_properties(properties)
      end
    end

    def force_login_filter
      if not logged_in?
        logger.debug "force_login_filter redirecting to Websignon"
        access_denied
      end
    end

    def access_denied
      if logged_in?
      	redirect_to login_url + "&error=permdenied"
      else
      	redirect_to login_url + "&error=notloggedin"
      end
    end

    def logged_in?
      not current_user.nil?
    end

    def current_user
      session[:sso_user]
    end
    
    def god_user?
      @goduserlist.any? {|user| user==current_user.user_name }
    end

    def login_url
      provider = URI.escape(@sso_config['provider_id'])
      target = URI.escape(current_location)
      "https://#{OriginHost}#{OriginPath}/slogin?providerId=#{provider}&target=#{target}"
    end

    def logout_url
      target = URI.escape(current_location)
      "https://#{OriginHost}#{OriginPath}/logout?target=#{target}"
    end
    
    def validate_user(username)
      user = get_user(username)
      !user.nil? and !user.disabled? and !user.email.nil?
    end
    
    def get_user(username)
      if Rails.cache.exist? "user_properties_" + username
        p = Rails.cache.read "user_properties_" + username
        User.new(p)
      else
        path = "#{OriginPath}/sentry?requestType=4&user=#{username}"
        http = Net::HTTP.new(OriginHost, 443)
        http.use_ssl = true
        resp, data = http.get(path,nil)
        properties = parse_properties(data)
        if properties[:returnType] == '4' and properties[:user]
          Rails.cache.write("user_properties_" + username, properties)
          User.new(properties)
        else
          User.new({:logindisabled=>"true",:user=>username,:name=>"Unknown user",:email=>"no-reply@warwick.ac.uk"})
        end
      end
    end
    
    def find_users(f_name,s_name)
      path = "#{OriginPath}/api/userSearch.htm?f_givenName=#{f_name}&f_sn=#{s_name}"
      http = Net::HTTP.new(OriginHost, 443)
      http.use_ssl = true
      resp, data = http.get(path,nil)
      users = Hash.from_xml(data)["users"]["user"]
      if users.is_a? Array
        users.collect {|u|
          result = {}
          u["attribute"].each {|f|
            result[f["name"]] = f["value"]
          }
          result
        }
      elsif users.nil?
        []
      else
        result = {}
        users["attribute"].each {|f|
          result[f["name"]] = f["value"]
        }
        [result]
      end
    end
    
    protected

    def process_properties(p)
      if p[:returnType] == '1' and p[:user]
        session[:sso_user] = User.new(p)
        logger.info "SSO: Signed in #{current_user.user_name}"
      else
        logger.info "SSO: Sign in failed, token wasn't valid (or no username returned)"
        session[:sso_user] = nil
        clear_sso_cookie
      end
    end

    def current_location
      @sso_config['uri_prefix'] + request.request_uri
    end
    
    # Get the WarwickSSO cookie
    def sso_cookie
      cookies['WarwickSSO']
    end
    
    def clear_sso_cookie
      
    end

    # parse properties format into a hash
    def parse_properties(text)
      properties = {}
      text.each_line do |line|
        line.scan(/^\s*(.+?)=(.+)\s*$/) {|key,val| properties[key.to_sym] = val }
      end 
      properties
    end
    
  end
end

