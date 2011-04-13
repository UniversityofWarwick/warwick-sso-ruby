# Mix-in module that aliases map entries to an accessor method.
# You could define all the getters yourself, but this makes
# the class itself nice and neat.
module EasyAttributes
  def self.append_features(base)
    super
    # this is needed to make them available as static methods
    base.extend(EasyAttributes)
  end

  # map user[property] to user.method
  def make_property(property, method)
    define_method(method) do
      self[property]
    end
  end
  
  # alias a parameter that's either "true" or not, to
  # an accessor that returns an actual boolean
  def make_boolean_property(property, method)
    define_method(method) do
      if !self[property].nil?
        'true' == self[property].downcase
      else
        false
      end
    end
  end
end

