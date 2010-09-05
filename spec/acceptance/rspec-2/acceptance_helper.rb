require 'rubygems'
require 'rspec'
require File.dirname(__FILE__) + "/../../../lib/steak"
require 'tempfile'

module RSpec_2
  module Factories
    def create_spec(options)
      options = {:content => options} unless options.is_a?(Hash)
      path = (options[:path] || Dir.tmpdir) + "/#{String.random}_spec.rb"
      File.open(path, "w") do |file|
        file.write options[:content]
      end
      path
    end

    def create_rails_app(options = {})
      path = File.join(Dir.tmpdir, String.random, "rails_app")
      FileUtils.rm_rf path
      `rails new #{path}`
      FileUtils.rm_rf path + '/public/index.html'
      File.open(File.join(path, "Gemfile"), "a") do |file|
        file.write "\ngem 'rspec-rails', '>= 2.0.0.a9'\n" <<
                   "gem 'capybara'\n" <<
                   "gem 'webrat'\n"
      end

      File.open(File.join(path, "Gemfile"), "a") do |file|
        file.write "\ngem 'steak', :path => '#{File.expand_path(File.dirname(__FILE__) + '/../../..')}'\n"
      end
    
      `bundle install`

      Dir.chdir path do
        `rails generate rspec:install`
        if options[:scaffold]
          `rails generate scaffold #{options[:scaffold]}`
          `rake db:create db:migrate db:test:prepare`
        end
      end

      unless options[:setup_steak] == false
        Dir.chdir path do
          `rails generate steak:install`
        end
      end

      path
    end

  end

  module HelperMethods
    def run_spec(file_path, app_base=nil)
      if app_base
        current_dir = Dir.pwd
        Dir.chdir app_base
      end

      output = `rspec #{file_path} 2>&1`

      Dir.chdir current_dir if app_base
      output
    end
  end

  RSpec.configure do |config|
    config.include Factories,     :example_group => {:file_path => /rspec-2/}
    config.include HelperMethods, :example_group => {:file_path => /rspec-2/}
  end
end

class String
  unless const_defined?("CHARS")
    CHARS = ('a'..'z').to_a + ('A'..'Z').to_a
  end

  def self.random(size = 8)
    (0..size).map{ CHARS[rand(CHARS.length)] }.join
  end
end