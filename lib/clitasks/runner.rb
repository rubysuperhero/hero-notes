module CliTasks
  class Runner
    def self.run(*files)
      world.reset
      files.flat_map{|file|
        Dir[File.directory?(file) && [file,'/**/*'].join || file]
      }.map{|file|
        world.stories << Note.from_file(file)
        world.stories.last.file = file
      }
    end

    def self.world
      @world ||= World.instance
    end
  end
end
