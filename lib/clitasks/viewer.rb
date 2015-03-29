module CliTasks
  class Viewer
    def initialize(*args)
      @files = args
      if args.any?
        Runner.run *args
      else
        Runner.run 'stories/index/*'
      end
    end

    def self.print(*args)
      new(*args).print
    end

    def print
      puts screen
    end

    def screen
      lines = [header]
      lines += stories.reverse.map{|s|
        story(s)
      }
      lines.join(separator)
    end

    def header
      sprintf(" %-80s | %-s\n", :name, :tags)
    end

    def wrap_in_column(str='',width=10)
      str.to_s.scan(/\S.{0,#{width - 1}}(?!\S)/)
    end

    def total_lines(*cols)
      [cols].flatten(1).map(&:length).max
    end

    def separator
      sprintf(" %-80s | %-s\n", ?-*80, ?-*30)
    end

    def story(s)
      # make a method for each of the _col methods
      #status_col = wrap_in_column(s.status, 10)
      #id_col = wrap_in_column(s.id, 20)
      #points_col = wrap_in_column(?* * s.points.to_i, 6)
      name_col = wrap_in_column(s.name, 80)
      tags_col = wrap_in_column(s.tags.sort * "\n", 30)

      #total = total_lines(status_col, id_col, points_col, name_col, tags_col)
      #total = total_lines(id_col, name_col, tags_col)
      total = total_lines(name_col, tags_col)

      lines = Array.new(total).map{ " %-80s | %-s\n" }

      data = lines.zip(name_col, tags_col).map{|r| sprintf(*r) }.join
      data += format(" File: %s\n", s.file)
    end

    def stories
      @stories ||= World.instance.stories
    end
  end
end
