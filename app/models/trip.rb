class Trip < ActiveRecord::Base
  attr_accessible :comment, :hidden, :name
  has_many :flights, :dependent => :destroy
  
  NULL_ATTRS = %w( comment )
  before_save :nil_if_blank
  
  validates :name, :presence => true
  
  scope :visitor, where("hidden = false")
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
