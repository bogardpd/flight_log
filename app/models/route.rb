class Route < ActiveRecord::Base  
  belongs_to :airport1, :class_name => 'Airport'
  belongs_to :airport2, :class_name => 'Airport'
end
