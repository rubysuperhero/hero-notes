module CliTasks
  class Runner
    def self.run(*files)
      world.reset
      files.flat_map{|file|
        Dir[File.directory?(file) && [file,'/*.{s,}hdoc'].join || file]
      }.map{|file|
        begin
          note = Note.from_file(file)
        rescue => e
          ap file: file
          binding.pry
          ap file: file
        end
        note_status = note.metadata['status']
        hide_note = false
        if note_status
          status_path = File.join(world.task_path, note.metadata['status'])
          new_file = File.join(status_path, File.basename(file))
          FileUtils.mkdir_p(status_path)
          FileUtils.cp(file, new_file)
          FileUtils.rm(file)
          file = new_file
          hide_note = true if note_status == 'finished'
        end
        next if hide_note == true
        world.stories << note
        world.stories.last.file = file
      }
    end

    def self.world
      @world ||= World.instance
    end
  end
end
