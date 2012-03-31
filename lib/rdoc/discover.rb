begin
  require "rubygems"
rescue LoadError
end

begin
  gem 'rdoc', '~> 3'
  #gem 'shomen'
  require_relative 'generator/shomen'
rescue Gem::LoadError => error
  puts error
rescue LoadError => error
  puts error
end





#puts "RDoc discovered Shomen!" if $DEBUG

# If using Gems put her on the $LOAD_PATH
#begin
#  require "rubygems"
#  gem "rdoc", ">= 2.5"
#  gem "shomen"
#end

#require 'shomen/rdoc/option_fix'

#RDoc.generator_option('shomen') do
#  require 'shomen/rdoc/generator'
#  RDoc::Generator::Shomen
#end

