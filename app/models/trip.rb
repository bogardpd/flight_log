class Trip < ActiveRecord::Base
  has_many :flights, :dependent => :destroy
  
  def self.purposes_list
    purposes = Hash.new
    purposes['business'] = 'Business'
    purposes['mixed'] = 'Mixed'
    purposes['personal'] = 'Personal'
    return purposes
  end
  
  NULL_ATTRS = %w( comment )
  before_save :nil_if_blank
  
  validates :name, :presence => true
  
  scope :visitor, -> { where('hidden = FALSE') }
  
  protected
  
  def nil_if_blank
    NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
