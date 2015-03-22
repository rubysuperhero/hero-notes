module CliTasks
  class Commands
    class << self
      def edit(*args)
        edit_files grep(*args)
      end

      def edit_files(*files)
        system(ENV['EDITOR'] || 'vim', *files)
      end

      def search(*args)
        if (args[0] || '').strip =~ /-(s|-simple)/i
          puts grep(*args.tap(&:shift))
        else
          Viewer.print(*grep(*args))
        end
      end

      def next_filename(runs=0)
        filename = '%s/%s.rb' % [world.task_path, Time.now.to_i]
        File.exist?(filename) ? next_filename(runs + 1) : filename
      end

      def write(file, taskname='TASK NAME GOES HERE')
        FileUtils.mkdir_p(world.task_path)
        checklog("Creating '#{file}'"){ IO.write(file, template(taskname)) }
        file
      end

      def mcreate(*tasks)
        edit_files *(tasks.flat_map do|taskname|
          next_filename.tap do |fn|
            write fn, taskname
          end
        end)
      end

      def create(*args)
        name = args.join ' '
        names = split_unescaped(name, ?;, trim: true)
        mcreate *names
      rescue => e
        binding.pry
        puts 'some kind of exception happened'
      end

      def index
        file = File.join(world.path, 'all_tasks')
        %x{ find #{world.path} | sed 's/^#{world.path.gsub(/./, ?.)}//' | egrep -v '[.]tasks|/all/'  >#{file} }
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
          Viewer.print '%s/*' % world.task_path
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
