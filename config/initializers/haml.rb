Haml::Template.options[:format] = :html5

if RUBY_VERSION.match /1\.9/
  Haml::Template.options[:encoding] = 'utf-8'
end
