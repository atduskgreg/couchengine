dbname = ARGV[0]

PROJECT_ROOT = "#{File.expand_path(File.dirname(__FILE__))}/.." unless defined?(PROJECT_ROOT)

begin

  puts "beginning autosave"
  require 'osx/foundation'
  OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'

  callback = proc do |stream, ctx, numEvents, paths, marks, eventIDs|
    paths.regard_as('*')
    rpaths = []

    numEvents.times { |i| rpaths << paths[i] }

    ["public", "controllers", "views"].each do |dir|
      if rpaths.any?{|p| Regexp.new(dir).match(p)}
        puts `ruby #{PROJECT_ROOT}/script/file_manager.rb #{dir}`
      end
    end
    
  end

  allocator = OSX::KCFAllocatorDefault
  context   = nil
  path      = [Dir.pwd]
  sinceWhen = OSX::KFSEventStreamEventIdSinceNow
  latency   = 1.0
  flags     = 0

  stream   = OSX::FSEventStreamCreate(allocator, callback, context, path, sinceWhen, latency, flags)
  unless stream
    puts "Failed to create stream"
    exit
  end

  OSX::FSEventStreamScheduleWithRunLoop(stream, OSX::CFRunLoopGetCurrent(), OSX::KCFRunLoopDefaultMode)
  unless OSX::FSEventStreamStart(stream)
    puts "Failed to start stream"
    exit 
  end

  OSX::CFRunLoopRun()
rescue Interrupt
  OSX::FSEventStreamStop(stream)
  OSX::FSEventStreamInvalidate(stream)
  OSX::FSEventStreamRelease(stream)

end