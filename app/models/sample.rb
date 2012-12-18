class Sample < ActiveRecord::Base
  belongs_to :user
  mount_uploader :file, SampleUploader

  

end
