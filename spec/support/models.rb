class User < ActiveRecord::Base
  validates :key, presence: { message: 'Please select an key before you submit' }
end
