require 'easy_attributes'

module SSO
class User
  include EasyAttributes

  #make_property :returned_parameter, :accessor_name
  make_property :user,            :user_name
  make_property :name,            :name
  make_property :firstname,       :first_name
  make_property :lastname,        :last_name
  make_property :dept,            :department
  make_property :deptshort,       :short_department
  make_property :email,           :email
  make_property :warwickitsclass, :its_class

  make_boolean_property :staff,     :staff?
  make_boolean_property :student,   :student?
  make_boolean_property :member,    :member?
  
  make_boolean_property :logindisabled,  :disabled?

  def initialize(parameters)
    @params = parameters.clone
  end

  protected

  def [](param)
    @params[param]
  end

  module M
  def self.append_features(base)
      super
      base.extend(M)
  end

  def make_property(property, method)
    define_method(method) do
      @params[property]
    end
  end
  
  # alias a parameter that's either "true" or not, to
  # an accessor that returns an actual boolean
  def make_boolean_property(property, method)
    define_method(method) do
      'true' == @params[property]
    end
  end
end
  
end
end



