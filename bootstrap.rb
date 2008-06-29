require 'fileutils'
require 'rubygems'
require 'couchrest'

HERE = File.expand_path(File.dirname(__FILE__))

project_name = ARGV[0]

unless project_name
 puts "Usage: ruby #{__FILE__} <project_name>"
 exit
end

# project_name/
# |-- Rakefile
# |-- app
# |   |-- controllers
# |   `-- views
# |-- config.json
# |-- log
# |-- public
# |-- script
# |   `-- generate.rb
# |-- spec
# `-- vendor
#     |-- autosave.rb
#     `-- couchrest


FileUtils.mkdir_p "#{project_name}/app/controllers"
FileUtils.mkdir_p "#{project_name}/app/views"
FileUtils.mkdir_p "#{project_name}/public"
FileUtils.mkdir_p "#{project_name}/spec"
FileUtils.mkdir_p "#{project_name}/vendor"
FileUtils.mkdir_p "#{project_name}/log"

FileUtils.cp_r "#{HERE}/script", "#{project_name}/"

FileUtils.cp "#{HERE}/Rakefile.template", "#{project_name}/Rakefile"
FileUtils.cp "#{HERE}/config.template", "#{project_name}/config.json"
FileUtils.cp "#{HERE}/autosave.rb", "#{project_name}/vendor/autosave.rb"
FileUtils.cp "#{HERE}/generate.template", "#{project_name}/script/generate.rb"

