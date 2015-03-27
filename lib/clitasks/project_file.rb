module CliTasks
  class ProjectFile
    class << self
      def for_dir(path=Dir.pwd, options={})
        original_dir = Dir.pwd
        Dir.chdir(world.path)
      end

      def collect_file_list(dir='')
        pattern = dir.sub(/\/+$/, ?/) + ?*
        files = []
        dirs = []
        Dir[pattern].each do |f|
          next if File.basename(f)[/^[.]/]
          if File.directory?(f)
            f = f.sub(/\/*$/, ?/)
            dirs += ['', f] + collect_file_list(f)
          else
            files << f
          end
        end
        files + dirs
      end

      def file
        'file-index'
      end

      def save_file
        IO.write(file, list.unshift(Dir.pwd, '').join("\n").gsub(/^/, '> '))
      end

      def open_file
        system("vim", file)
      end

      def index
        list = collect_file_list
      end

      def world
        @world ||= World.instance
      end
    end
  end
end
