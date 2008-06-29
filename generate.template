require 'fileutils'

class Generate
  class << self
    def view(name)
      FileUtils.mkdir_p "app/views/#{name}"
      new_map(name)
      new_reduce(name)
    end
    
    def controller(name)
      FileUtils.mkdir_p "app/controllers/#{name}"
      File.open("app/controllers/#{name}/action.js", "w") do |f|
        f << "function(params, db, verb){\n}"
      end
    end
    
    private
    
    def new_map(name)
      File.open("app/views/#{name}/#{name}-map.js", "w") do |f|
        f << "function(doc){\n\temit( doc.id, doc );\n}"
      end
    end
    
    def new_reduce(name)
      File.open("app/views/#{name}/#{name}-reduce.js", "w") do |f|
        f << "function(keys,values,combine) {\n\tif (combine) {\n\t\treturn sum(values)\n\t} else {\n\t\treturn values.length}\n}"
      end
    end
  end
end

Generate.send(ARGV[0].to_sym, ARGV[1])