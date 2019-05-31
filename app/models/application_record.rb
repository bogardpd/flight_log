# Creates an ApplicationRecord class that database classes can inherit from.
# Created to avoid having to modify ActiveRecord::Base.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
