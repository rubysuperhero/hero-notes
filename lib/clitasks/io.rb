module CliTasks
  module IO
    extend self

    def read_file(filename)
      return filename unless File.exist?(filename)
      return filename if File.directory?(filename)
      IO.read filename
    end

    def read_stdin(io=$stdin)
      return nil if io.tty?
      from_string io.read
    end
  end
end
