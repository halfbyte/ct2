class Mod < ActiveRecord::Base
  scope :public, where(:is_public => true)
end
