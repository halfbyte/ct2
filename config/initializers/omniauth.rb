Rails.application.config.middleware.use OmniAuth::Builder do
  unless Rails.env.production?
    provider :developer, :fields => [:nickname, :email], :uid_field => :nickname
  end
  provider "soundcloud", ENV['SOUNDCLOUD_CLIENT_ID'], ENV['SOUNDCLOUD_CLIENT_SECRET']
end