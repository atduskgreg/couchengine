require 'yaml'

PROJECT_ROOT = "#{File.dirname(__FILE__)}/.."

LANGS = {"rb" => "ruby", "js" => "javascript"}

couch = {}

couch[:public] = Dir["#{File.expand_path(File.dirname("."))}/public/*.*"].collect{|f| {f.split("/").last => open(f).read}}

couch[:controllers] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/controllers/**/*.*"].collect do |c|
  path_parts = c.split("/")
  
  controller_name = path_parts[path_parts.length - 2]
  action_name = path_parts[path_parts.length - 1].split(".").first

  couch[:controllers][controller_name] ||= {:actions => {}}
  couch[:controllers][controller_name][:actions][action_name] = open(c).read
  
end

couch[:designs] = {}
Dir["#{File.expand_path(File.dirname("."))}/app/views/**/*.*"].collect do |design_doc|
  design_doc_parts = design_doc.split('/')
  pre_normalized_view_name = design_doc_parts.last.split("-")
  view_name = pre_normalized_view_name[0..pre_normalized_view_name.length-2].join("-")

  folder = design_doc.split("app/views").last.split("/")[1]

  couch[:designs][folder] ||= {}
  couch[:designs][folder][:views] ||= {}
  couch[:designs][folder][:language] ||= LANGS[design_doc_parts.last.split(".").last]
  
  if design_doc_parts.last =~ /-map/
    couch[:designs][folder][:views]["#{view_name}-map"] ||= {}

    couch[:designs][folder][:views]["#{view_name}-map"][:map] = open(design_doc).read

    couch[:designs][folder][:views]["#{view_name}-reduce"] ||= {}
    couch[:designs][folder][:views]["#{view_name}-reduce"][:map] = open(design_doc).read
  end
  
  if design_doc_parts.last =~ /-reduce/
    couch[:designs][folder][:views]["#{view_name}-reduce"] ||= {}

    couch[:designs][folder][:views]["#{view_name}-reduce"][:reduce] = open(design_doc).read
  end
end

# cleanup empty maps and reduces
couch[:designs].each do |name, props|
  props[:views].delete("#{name}-reduce") unless props[:views]["#{name}-reduce"].keys.include?(:reduce)
end

puts couch.to_yaml
