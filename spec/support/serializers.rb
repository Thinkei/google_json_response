class UserSerializer < ActiveModel::Serializer
  attributes :key, :name
end

class ManSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class WifeSerializer < ActiveModel::Serializer
  attributes :id, :name, :age
end
