module CliTasks
  class Commands
    class << self
      def commit(message='auto-saving notes')
        if $stdout.tty?
          addall = %x{git add --all}
          files = %x{git status -s}.lines.map(&:chomp)
          files = files.map{|f| f.sub(/^.../, '').sub(/.* -> /, '') }
          files_changed = files.count
          csf = files.join(', ')
          commit = %x{git commit -m '#{files_changed} files changed: #{csf.length > 140 ? csf[0,140] + '...' : csf} @ #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}'}
          # puts_remote = %x{git push origin --all &>/dev/null}
        else
          addall = %x{git add --all}
          files = %x{git status -s}.lines.map(&:chomp)
          files = files.map{|f| f.sub(/^.../, '').sub(/.* -> /, '') }
          files_changed = files.count
          csf = files.join(', ')
          commit = %x{git commit -m '#{files_changed} files changed: #{csf.length > 140 ? csf[0,140] + '...' : csf} @ #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}'}
          # puts_remote = %x{git push origin --all &>/dev/null}
        end
      end

      def backup
        %x{git push origin --all}
      end

      def commit_and_backup
        commit
        backup
      end

      def edit(*args)
        edit_files grep(*args)
      end

      def edit_files(*files)
        if $stdout.tty?
          system(ENV['EDITOR'] || 'vim', *(files.flatten))
        else
          puts 'not opening because stdout is not a terminal'
        end
      end

      def search(*args)
        if (args[0] || '').strip =~ /-(s|-simple)/i
          puts grep(*args.tap(&:shift))
        else
          Viewer.print(*grep(*args))
        end
      end

      def next_filename(counter=0)
        filename = '%s/%s%02d.hdoc' % [world.task_path, Time.now.to_i, counter]
        File.exist?(filename) ? next_filename(counter + 1) : filename
      end

      def write(file, data='')
        FileUtils.mkdir_p(world.task_path)
        File.new(file, 'w').tap{|f| f.write(data) }.close
        puts file
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

      # def collect(args=ARGV, stdin=$stdin)
      #   notes = args.map(&Note.method(:from_file))
      #   notes << Note.from_stdin(stdin)
      #   notes = [Note.from_string('')] if notes.compact.none?
      #   notes.compact
      # end

      def collect(args=ARGV, stdin=$stdin)
        notes = []
        notes += args.flat_map do |arg|
          Note.split NoteIO.read_file(arg)
        end
        notes += Note.split NoteIO.read_stdin(stdin)
        collected = notes.flatten.compact
        if collected.count == 0
          f = Tempfile.new('tasks')
          system ENV['EDITOR'] || 'vim', f.path
          collected = Note.split NoteIO.read_file(f.path)
        end
        collected
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
        ProjectFile.generate_and_open(world.path)
      end

      def update_index
        ProjectFile.generate(world.path)
      end

      def print_index
        ProjectFile.generate_and_print(world.path)
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

      def tags(*tag_list)
        puts if tag_list.any?
          tag_list.flat_map do |tag|
            stories_with_tag = world.stories.select{|n| n.tags.any?{|nt| nt[/^#{tag.strip}$/i] } }
            next [] unless stories_with_tag.any?
            [
              '',
              'TAG: %s' % tag,
            ] + world.stories.select{|n| n.tags.include?(tag) }.map(&Viewer.method(:story))
          end.join("\n")
        else
          world.stories.flat_map(&:tags).sort.uniq
        end
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
        return block.call unless $stdout.tty?
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
