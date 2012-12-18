Rails.application.config.middleware.use OmniAuth::Builder do
    provider "soundcloud", ENV['SOUNDCLOUD_CLIENT_ID'], ENV['SOUNDCLOUD_CLIENT_SECRET']
end