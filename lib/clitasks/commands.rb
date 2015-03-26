module CliTasks
  class Commands
    class << self
      def commit(message='auto-saving notes')
        puts `git add --all; git commit -m '#{message} @ #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}'`
      end

      def edit(*args)
        edit_files grep(*args)
      end

      def edit_files(*files)
        system(ENV['EDITOR'] || 'vim', *(files.flatten))
      end

      def search(*args)
        if (args[0] || '').strip =~ /-(s|-simple)/i
          puts grep(*args.tap(&:shift))
        else
          Viewer.print(*grep(*args))
        end
      end

      def next_filename(counter=0)
        filename = '%s/%s%02d.rb' % [world.task_path, Time.now.to_i, counter]
        File.exist?(filename) ? next_filename(counter + 1) : filename
      end

      def write(file, data='')
        FileUtils.mkdir_p(world.task_path)
        checklog("Creating '#{file}'"){ File.new(file, 'w').tap{|f| f.write(data) }.close }
        file
      end

      def mcreate(*tasks)
        edit_files *(tasks.flat_map do|task|
          next_filename.tap do |fn|
            write fn, task.data
          end
        end)
      end

      def create(args=ARGV, stdin=$stdin)
        files = save_to_disk collect(args, stdin)
        edit_files *files
      end

      def save(args=ARGV, stdin=$stdin)
        files = save_to_disk collect(args, stdin)
      end

      def save_to_disk(tasks)
        tasks.flat_map do|task|
          next_filename.tap do |fn|
            write fn, task.data
          end
        end
      end

      def test(args=ARGV, stdin=$stdin)
        puts collect(args, stdin).ai(raw: true)
      end

      def collect(args=ARGV, stdin=$stdin)
        notes = args.map(&Note.method(:from_file))
        notes << Note.from_stdin(stdin)
        notes = [Note.from_string('')] if notes.compact.none?
        notes.compact
      end

#       def create(*args)
#         name = args.join ' '
#         names = split_unescaped(name, ?;, trim: true)
#         mcreate *names
#       rescue => e
#         binding.pry
#         puts 'some kind of exception happened'
#       end


      def index_glob(dir='')
        pattern = dir.sub(/\/+$/, ?/) + ?*
        files = []
        dirs = []
        Dir[pattern].each do |f|
          next if File.basename(f)[/^[.]/]
          if File.directory?(f)
            f = f.sub(/\/*$/, ?/)
            dirs += ['', f] + index_glob(f)
          else
            files << f
          end
        end
        files + dirs
      end

      def index
        original_dir = Dir.pwd
        Dir.chdir(world.path)
        file = 'file-index.textile'
        list = index_glob
        IO.write(file, list.unshift(Dir.pwd, '').join("\n").gsub(/^/, '> '))
        system("vim", file)
      end

      def rebuild
        LinkBuilder.all
      end

      def world
        @world ||= World.instance
      end

      def stories
        world.stories
      end

      def list(*args)
        if args.any?
          Viewer.print *args
        else
          Viewer.print '%s' % world.task_path
        end
      end

      private

      def grep(*args)
        args.inject([world.task_path]){|files,arg|
          #pp     "grep -ril '#{arg}' -- '#{files.join "' '"}'"
          grep = `grep -ril '#{arg}' -- '#{files.join "' '"}'`
          lines = grep.lines.map(&:chomp)
        }
      end

      def checklog(msg, &block)
        print "#{msg}..."
        block.call
        puts 'done'
      end

      def named_tags(name='')
        name.scan(/(?<=\s[#])\S\S*/).flatten
      end

      def template(name='CHANGEME', tags=nil)
        tags ||= named_tags name
        data = <<-STORY
          story %q(#{name}) do
            status queued
            #restricted_to weekdays
            #restricted_to weekends

            tags '#{tags * ', '}'

            points 1
            created_by 'unassigned'
            assigned_to :unassigned

            description <<-"__TASK_DESCRIPTION__"

            __TASK_DESCRIPTION__
          end
        STORY
        pattern = data.scan(/\A(\s+)/).uniq.min_by{|s| s.length }.first
        data.gsub(/^#{pattern}/, '')
      end


      def split_unescaped(text, str, opts={}) # &block too
        text.split(/(?<!\\)#{str}/).map do |s|
          s = s.gsub(/\\(?=#{str})/, '')
          s = s.sub(/^\s*/,'').sub(/\s*$/,'') if opts[:trim] == true
          s = yield s if block_given?
          s
        end
      end
    end
  end
end
