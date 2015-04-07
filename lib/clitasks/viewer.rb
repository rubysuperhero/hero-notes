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

    def self.tag_groups(*args)
      new(*args).tag_groups
    end

    def self.screen(*args)
      new(*args).screen
    end

    def self.print(*args)
      new(*args).print
    end

    def print
      puts screen
    end

    def tag_groups
      stories.flat_map do |story|
        story.tagged_notes
      end.group_by do |story|
        story.tag
      end.sort_by{|k,v| k }.flat_map do |group,grouped_stories|
        lines = [
        ]
        lines += grouped_stories.sort_by do |gs|
          gs.name[/[a-z]/i].downcase
        end.map do |s|
          story(s)
        end

        [
          '',
          format(" |  TAG: | %s (%d)\n", group, grouped_stories.count),
          lines.join(separator),
          '',
        ].join(outer_separator)
      end
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
      sprintf(" %-82s-+-%-s\n", ?-*82, ?-*29)
    end

    def outer_separator
      sprintf(" %-111s===\n", ?=*111)
    end

    def story(s)
      # make a method for each of the _col methods
      #status_col = wrap_in_column(s.status, 10)
      #id_col = wrap_in_column(s.id, 20)
      #points_col = wrap_in_column(?* * s.points.to_i, 6)
      name_col = wrap_in_column(s.name, 72)
      name_col << ''
      tags_col = wrap_in_column(s.tags.sort * "\n", 30)

      name_labels = ['Name:']
      #total = total_lines(status_col, id_col, points_col, name_col, tags_col)
      #total = total_lines(id_col, name_col, tags_col)
      total = total_lines(name_col, tags_col)

      lines = Array.new(total).map{ " | %5s | %-72s | %-s\n" }

      data = lines.zip(name_labels, name_col, tags_col)
      # data.push([" ------ + %-72s +\n", ?- * 72])
      data.push([" | File: | %-72s |\n", s.file])
      data.map{|r| sprintf(*r) }.join
      # data += separator
      # data += format(" File: %s\n", s.file)
    end

    def stories
      @stories ||= World.instance.stories
    end
  end
end
