module CliTasks
  class ProjectFile
    class << self
      def generate(path=World.instance.path, options={})
        new(path, options).tap(&:generate)
      end

      def generate_and_open(path=World.instance.path, options={})
        new(path, options).tap(&:generate_and_open)
      end

      def generate_and_print(path=World.instance.path, options={})
        new(path, options).tap(&:generate_and_print)
      end
    end

    attr_accessor :original_path, :path, :options

    def initialize(path=world.path, options={})
      @original_path = Dir.pwd
      @path = path
      @options = options
    end

    def generate
      Dir.chdir(path)
      ret = save_file
      Dir.chdir(original_path)
      ret
    end

    def generate_and_open
      generate.tap{
        if $stdout.tty?
          open_file
        else
          print_file
        end
      }
      # Dir.chdir(path)
      # ret = save_file
      # open_file
      # Dir.chdir(original_path)
      # ret
    end

    def generate_and_print
      generate.tap{ print_file }
      # Dir.chdir(path)
      # ret = save_file
      # print_file
      # Dir.chdir(original_path)
      # ret
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
      data = [
        '',
        "Project Directory: %s" % Dir.pwd,
        '',
        file_list,
      ].flatten * "\n"
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

    def print_file
      puts file_data
    end

    def world
      @world ||= World.instance
    end
  end
end
