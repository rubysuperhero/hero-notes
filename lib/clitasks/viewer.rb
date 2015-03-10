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
      puts header

      puts stories.reverse.inject({}){|hash,s|
        hash.merge( s.status => hash.fetch(s.status, []) << s )
      }.map{|status,group|
        [separator] + group.flat_map{|s| story(s) }
      }
    end

    def header
      sprintf(" %-10s | %-20s | %-6s | %-60s | %-s", :status, :id, :points, :name, :tags)
    end

    def wrap_in_column(str='',width=10)
      str.to_s.scan(/\S.{0,#{width - 1}}(?!\S)/)
    end

    def total_lines(*cols)
      [cols].flatten(1).map(&:length).max
    end

    def separator
      sprintf(" %-10s | %-20s | %-6s | %-60s | %-s", ?-*10, ?-*20, ?-*6, ?-*60, ?-*30)
    end

    def story(s)
      # make a method for each of the _col methods
      status_col = wrap_in_column(s.status, 10)
      id_col = wrap_in_column(s.id, 20)
      points_col = wrap_in_column(?* * s.points.to_i, 6)
      name_col = wrap_in_column(s.name, 60)
      tags_col = wrap_in_column(s.tags * ', ', 30)

      total = total_lines(status_col, id_col, points_col, name_col, tags_col)

      lines = Array.new(total).map{ " %-10s | %-20s | %-6s | %-60s | %-30s" }

      output = lines.zip(status_col, id_col, points_col, name_col, tags_col).map{|r| sprintf(*r) } << format("%s\n",separator)

      return output.join("\n")

      sprintf(" %-10s | %-20s | %-6s | %-60s | %-s", s.status, s.id, ?* * s.points.to_i, s.name.slice(0,60), Array(s.tags).join(', '))
    end

    def stories
      @stories ||= World.instance.stories
    end
  end
end
