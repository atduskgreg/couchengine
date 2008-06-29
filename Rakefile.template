require 'rake'
require 'json'


namespace :views do
  
  desc "Pull views from coucdb into subdirs of app/views"
  task :pull => :read_config do
    raise "Can't pull without valid db in config.json" unless @config["db"]
    `cd app; ruby ../vendor/couchrest/script/couchview pull #{@config["db"]}`
  end
  
  desc "Push views for app/views into couchdb"
  task :push => :read_config do
    raise "Can't push without valid db in config.json" unless @config["db"]
    `cd app; ruby ../vendor/couchrest/script/couchview push #{@config["db"]}`
  end
end


namespace :autosave do
  desc "Start autosave capacity to load views, controllers, and public docs into couch on save."
  task :start => :read_config do
    raise "Can't start autosave without valid db in config.json" unless @config["db"]
    @pid = fork do
      exec "/usr/bin/ruby vendor/autosave.rb public #{@config["db"]}"
    end
    File.open("log/autosave.pid", "w"){|f| f << @pid}
  end
  
  desc "stop autosave"
  task :stop do
    `kill -9 #{open("log/autosave.pid").read}`
    FileUtils.rm("log/autosave.pid")
  end
  
end

# utils:

task :read_config do
  @config = JSON.load open("config.json")
end