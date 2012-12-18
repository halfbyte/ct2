class User < ActiveRecord::Base

  has_many :mods

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"].to_s
      user.name = auth["info"]["name"]
      user.nickname = auth["info"]["nickname"]
      user.token = auth["credentials"]["token"]
      user.image = auth["info"]["image"]
    end
  end
  
  def self.by_oauth(auth)
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"].to_s)
    if user      
      user.update_attribute(:token, auth["credentials"]["token"])
    else 
      user = User.create_with_omniauth(auth)
    end
    user
  end
  
  def to_param
    nickname
  end
  
end
