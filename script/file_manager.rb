require 'yaml'
require 'rubygems'
require 'couchrest'
require 'json'
require 'digest/md5'

PROJECT_ROOT = "#{File.dirname(__FILE__)}/.."
DBNAME = JSON.load( open("#{PROJECT_ROOT}/config.json").read )["db"]

LANGS = {"rb" => "ruby", "js" => "javascript"}

# parse the file structure to load the public files, controllers, and views into a hash with the right shape for coucdb
couch = {}

couch["public"] = Dir["#{File.expand_path(File.dirname("."))}/public/**/*.*"].collect do |f|
  {f.split("public/").last => open(f).read}
end

couch["controllers"] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/controllers/**/*.*"].collect do |c|
  path_parts = c.split("/")
  
  controller_name = path_parts[path_parts.length - 2]
  action_name = path_parts[path_parts.length - 1].split(".").first

  couch["controllers"][controller_name] ||= {"actions" => {}}
  couch["controllers"][controller_name]["actions"][action_name] = open(c).read
  
end

couch["designs"] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/views/**/*.*"].collect do |design_doc|
  design_doc_parts = design_doc.split('/')
  pre_normalized_view_name = design_doc_parts.last.split("-")
  view_name = pre_normalized_view_name[0..pre_normalized_view_name.length-2].join("-")

  folder = design_doc.split("app/views").last.split("/")[1]

  couch["designs"][folder] ||= {}
  couch["designs"][folder]["views"] ||= {}
  couch["designs"][folder]["language"] ||= LANGS[design_doc_parts.last.split(".").last]
  
  if design_doc_parts.last =~ /-map/
    couch["designs"][folder]["views"]["#{view_name}-map"] ||= {}

    couch["designs"][folder]["views"]["#{view_name}-map"]["map"] = open(design_doc).read

    couch["designs"][folder]["views"]["#{view_name}-reduce"] ||= {}
    couch["designs"][folder]["views"]["#{view_name}-reduce"]["map"] = open(design_doc).read
  end
  
  if design_doc_parts.last =~ /-reduce/
    couch["designs"][folder]["views"]["#{view_name}-reduce"] ||= {}

    couch["designs"][folder]["views"]["#{view_name}-reduce"]["reduce"] = open(design_doc).read
  end
end

# cleanup empty maps and reduces
couch["designs"].each do |name, props|
  props["views"].delete("#{name}-reduce") unless props["views"]["#{name}-reduce"].keys.include?("reduce")
end

puts couch.to_yaml

# parsing done, begin posting

# connect to couchdb
cr = CouchRest.new("http://localhost:5984")
@db = cr.database(DBNAME)

def create_or_update(id, fields)
  existing = get(id)
  
  if existing
    updated = fields.merge({"_id" => id, "_rev" => existing["_rev"]})
    puts "----------"
    puts existing.inspect
    puts
    puts updated.inspect
  else
    puts "saving #{id}"
    save(fields.merge({"_id" => id}))
  end
  
  if existing == updated
    puts "no change to #{id}. skipping..."
  else
    puts "replacing #{id}"
    save(updated)
  end

end

def get(id)
  doc = handle_errors do
    @db.get(id)
  end
end

def save(doc)
  handle_errors do
    @db.save(doc)
  end
end

def handle_errors(&block)
  begin
    yield
  rescue Exception => e
    puts e.message
    nil
  end
end

puts
puts "posting views into CouchDB"
puts

couch["designs"].each do |k,v|
  create_or_update("_design/#{k}", v)
end

puts
puts "posting controllers into CouchDB"
puts

couch["controllers"].each do |k,v|
  create_or_update("controller/#{k}", v)
end

puts
puts "posting public docs into CouchDB"
puts



@content_types = {
  "html"       => "text/html",
  "htm"        => "text/html",
  "png"        => "image/png",
  "css"        => "text/css",
  "js"         => "test/javascript"
}

def md5 string
  Digest::MD5.hexdigest(string)
end

@attachments = {}
@signatures = {}
couch["public"].each do |doc|
  @signatures[doc.keys.first] = md5(doc.values.first)
  
  @attachments[doc.keys.first] = {
    "data" => doc.values.first,
    "content_type" => @content_types[doc.keys.first.split('.').last]
  }
end

doc = get("public")
unless doc
  puts "creating public"
  @db.save({"_id" => "public", "_attachments" => @attachments, "signatures" => @signatures})
  exit
end

puts doc.inspect

doc["signatures"].each do |path, sig|
  puts "existing"
  puts "#{path}: #{sig}"
  puts "new"
  puts "#{path}: #{@signatures[path]}"
  puts
  if @signatures[path] == sig
    puts "no change to #{path}. skipping..."
  else
    puts "replacing #{path}"
    doc["signatures"][path] = md5(@attachments[path]["data"])
    doc["_attachments"][path].delete("stub")
    doc["_attachments"][path].delete("length")    
    doc["_attachments"][path]["data"] = @attachments[path]["data"]
    doc["_attachments"][path].merge!({"data" => @attachments[path]["data"]} )
    puts doc.inspect
    begin
      @db.save(doc)
    rescue Exception => e
      puts e.message
    end
  end
end
# create_or_update("public", {"_attachments" => attachments, "signatures" => signatures})
