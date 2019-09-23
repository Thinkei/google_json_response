class User < ActiveRecord::Base
  validates :key, presence: { message: 'Please select an key before you submit' }
end

class Man < ActiveRecord::Base
  has_many :wives
  accepts_nested_attributes_for :wives
end

class Wife < ActiveRecord::Base
  validates :name, presence: true
end
