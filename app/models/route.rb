class Route < ActiveRecord::Base
  attr_accessible :airport1_id, :airport2_id, :distance_mi
  
  belongs_to :airport1, :class_name => 'Airport'
  belongs_to :airport2, :class_name => 'Airport'
end
