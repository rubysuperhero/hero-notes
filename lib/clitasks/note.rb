module CliTasks
  class Note
    attr_accessor :data, :lines, :file
    attr_accessor :metadata, :name, :tags

    class << self
      def from_command_line(args=ARGV.clone, stdin=$stdin.clone)
        notes = [*args].push stdin
        notes.map &Note.method(:new)
      end

      def subset(*notes)
        notes.flatten.flat_map do |note|
          next note if note.is_a? Note
          from_file note
        end
      end

      def from_string(data, name=nil)
        Note.new data, name
      end

      def from_file(name)
        if File.exist?(name)
          from_string(IO.read(name), name) unless File.directory?(name)
        else
          from_string(name)
        end
      end

      def from_stdin(io)
        return nil if io.tty?
        from_string io.read
      end

      def split(data='')
        notes = (data || '').split(/(\A|\n)name:\s*|^---\s*next.note\s*---\n/i)
        notes.map do |str|
          from_string(str)
        end
      end
    end

    def initialize(data='', file=nil)
      @data = data
      @file = file
      @lines = @data.lines.map(&:chomp)

      extract_tags
      extract_metadata
      extract_name
    end

    def id
      @id ||= File.basename(file).sub(/[.]s?hdoc$/, '')
    end

    def extract_tags
      @tags ||= data.scan(/(?<=(?<!\S)#)\w\S*/).sort # should match 'nothis #this #also/this/too'
    end

    def extract_metadata
      @metadata ||= lines.take_while do |line|
        line[metadata_line_regex] # /^\w+:\s*\w|^\s*$/]
      end.inject({}) do |h,line|
        md = line.match(/^(\w+)\s*:\s*(\w.*)$/)
        md &&= Hash[md[1], md[2]]
        h.merge md || {}
      end
    end

    def extract_name
      @name ||= extract_body.first
    end

    def short_name
      extract_name[/^\s*(.{0,79}(?!\S))/]
    rescue => e
      puts({file: file}.ai(plain: true, raw: true, index: false))
    end

    def extract_body
      @body ||= lines.drop_while do |line|
        line[metadata_line_regex] # /^[\w\s]+:\s*\w|^\s*$/]
      end
    end

    def tagged_notes
      tags.map do |tag|
        TaggedNote.new(data, file).tap do |tn|
          tn.tag = tag
        end
      end
    end

    private

    def metadata_line_regex
      /^\w+:\s*\w|^\s*$/
    end
  end

  class TaggedNote < Note
    attr_accessor :tag
  end
end

#p = HeroParser.new ARGV.first || $stdin
#ap [:@name, :@metadata, :@tags, :@body].map{|x| p.instance_variable_get(x) }, raw: true, index: false
