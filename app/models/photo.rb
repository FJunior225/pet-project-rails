class Photo < ActiveRecord::Base
	belongs_to :pet

	validates :pet, presence: true
end
