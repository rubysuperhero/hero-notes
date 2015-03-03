module CliTasks
  class Commands
    class << self
      def edit(*args)
        files = grep(*args)
        system(ENV['EDITOR'] || 'vim', *files)
      end

      def search(*args)
        if (args[0] || '').strip =~ /-(s|-simple)/i
          puts grep(*args.tap(&:shift))
        else
          Viewer.print(*grep(*args))
        end
      end

      def create(*args)
        name = args.join ' '
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        filename = '%s/%s.rb' % [world.task_path, timestamp] #"./stories/index/#{timestamp}.rb"

        FileUtils.mkdir_p(world.task_path)
        checklog("Creating '#{filename}'"){ IO.write(filename, template(name)) }
        checklog("Opening '#{filename}'"){ system(ENV['EDITOR'] || 'vim', filename) }
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

      def template(name)
        data = <<-STORY
          story %q(#{name}) do
            status queued
            #restricted_to weekdays
            #restricted_to weekends

            tags 'comma,delimited,tags'

            points 1
            created_by '#{world.configuration.created_by || 'unassigned'}'
            assigned_to :unassigned

            description <<-"__TASK_DESCRIPTION__"

            __TASK_DESCRIPTION__
          end
        STORY
        pattern = data.scan(/\A(\s+)/).uniq.min_by{|s| s.length }.first
        data.gsub(/^#{pattern}/, '')
      end
    end
  end
end
