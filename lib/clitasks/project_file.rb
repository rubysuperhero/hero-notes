module CliTasks
  class ProjectFile
    class << self
      def for_dir(path=Dir.pwd, options={})
        new(path, options)
      end
    end

    attr_accessor :original_dir, :path, :options

    def initialize(path=Dir.pwd, options={})
      @original_dir = Dir.pwd
      @path = path
      @options = options
      Dir.chdir(world.path)
    end

    def generate

    end

    def generate_and_open

    end

    def file_list(dir='')
      pattern = dir.sub(/\/+$/, ?/) + ?*
      files = []
      dirs = []
      Dir[pattern].each do |f|
        next if File.basename(f)[/^[.]/]
        if File.directory?(f)
          f = f.sub(/\/*$/, ?/)
          dirs += ['', f] + file_list(f)
        else
          files << f
        end
      end
      files + dirs
    end

    def file_data
      data = file_list
      data = data.unshift(Dir.pwd, '')
      data = data.join("\n")
      data.gsub(/^/, '> ')
    end

    def filename
      'project-index'
    end

    def absolute_path
      File.join(path, filename)
    end

    def save_file
      IO.write(filename, file_data)
    end

    def open_file
      system("vim", filename)
    end

    def world
      @world ||= World.instance
    end
  end
end
