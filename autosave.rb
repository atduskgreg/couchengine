dirname = ARGV[0]
dbname = ARGV[1]

begin

  require 'osx/foundation'
  OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'

  callback = proc do |stream, ctx, numEvents, paths, marks, eventIDs|
    paths.regard_as('*')
    rpaths = []

    numEvents.times { |i| rpaths << paths[i] }

    if rpaths.any?{|p|/#{dirname}/.match(p)}
      puts `script/couchdir #{dirname} #{dbname}`
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