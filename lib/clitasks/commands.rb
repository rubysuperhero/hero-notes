module CliTasks
  class Commands
    class << self
      def commit(message='auto-saving notes')
        reindex
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

      def reindex
        Index.update
      end

      def backup
        %x{git push origin --all}
      end

      def commit_and_backup
        commit
        backup
      end

      def editor
        ed = ENV['EDITOR']
        ed ||= 'vim -O'
        ed[/^\s*vim\s*$/] ? 'vim -O' : ed
      end

      def scratch
        f = Tempfile.new('tasks')
        open_in_editor! f.path
        f.unlink
        f.close
      end

      def edit(*args)
        open_in_editor grep(*args)
      end

      def print_files(*files)
        files.flatten.tap do |file_list|
          file_list.each{|file| print_file file }
        end
      end

      def print_file(f)
        printf "\n"
        header = sprintf(" %s ", f)
        printf "%s\n", header.gsub(/./, ?-)
        printf "%s\n", header
        printf "%s\n", header.gsub(/./, ?-)
        puts IO.read(f)
        puts
      end

      def open_in_editor(*files)
        unless world.avoid_editor?
          return open_in_editor!(*files)
        end

        puts 'not opening because stdout is not a terminal or you are already in a vim session'
        puts
        print_files *files
      end

      def open_in_editor!(*files)
        files.flatten.tap do |file_list|
          system(sprintf("%s %s", editor, files.flatten.join(" ")))
        end
      end

      def with_tempfile(prefix='notes')
        tmpfile = tempfile
        yield(tempfile) if block_given?
        tempfile.unlink!
        tempfile.close
      end

      def tempfile(prefix='notes')
        Tempfile.new(prefix)
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
        open_in_editor *(tasks.flat_map do|task|
          next_filename.tap do |fn|
            write fn, task.data
          end
        end)
      end

      def create(args=ARGV, stdin=$stdin)
        files = save_to_disk collect(args, stdin)
        open_in_editor *files
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
          system sprintf("%s %s", editor, f.path)
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
        @world ||= CliTasks.world
      end

      def stories
        world.stories
      end

      def tags(*tag_list)
        puts t = if tag_list.any?
          tag_list.flat_map{|tag|
            stories_with_tag = if world.use_index
              stories = CliTasks.index['tags'][tag]
              stories = stories.any? ? stories : CliTasks.index['tags'][tag.downcase]
            else
              world.stories.select{|n| n.tags.any?{|nt| nt[/^#{tag.strip}$/i] } }
            end
            # stories_with_tag = Index.tags[tag] # world.stories.select{|n| n.tags.any?{|nt| nt[/^#{tag.strip}$/i] } }
            next [] unless stories_with_tag.any?
            [
              '',
              Viewer.outer_separator,
              '   TAG: %s' % tag,
              Viewer.outer_separator,
              world.stories.select{|n| n.tags.include?(tag) }.map(&Viewer.method(:story)).join, #(Viewer.separator),
              Viewer.outer_separator,
              '',
            ]
          }
        else
          tags = if world.use_index
            CliTasks.index['tags'].keys.sort
          else
            world.stories.flat_map(&:tags).sort.uniq
          end
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
        if world.use_index == true
          args.inject(CliTasks::Index.read['stories']){|results,query|
            results.select{|story| story.data =~ [/#{query.downcase}/i] }
          }.map{|s| s.file }
        else
          args.inject([world.task_path]){|files,arg|
            #pp     "grep -ril '#{arg}' -- '#{files.join "' '"}'"
            grep = `grep -ril '#{arg}' -- '#{files.join "' '"}'`
            lines = grep.lines.map(&:chomp)
          }
        end
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
