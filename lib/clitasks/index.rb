module CliTasks
  class Index
    BASE_INDEX = {
      'stories' => {
        # story.file => story.data,
      },
      'tags' => {
        # tag => story_array,
      }
    }

    def self.read
      yaml = IO.read index_file
      data = YAML.load yaml
    end

    def self.build
      world.stories.inject(BASE_INDEX.clone) do |index,story|
        index['stories'].merge!(story.file => story)
        story.tags.each do |tag|
          tag = tag.to_s
          current_tag = index['tags'].fetch(tag, [])
          index['tags'].merge!(tag => current_tag)
          if (downtag = tag.to_s.downcase) != tag
            current_tag = index['tags'].fetch(downtag, [])
            current_tag << story.id
            index['tags'].merge!(downtag => current_tag)
          end
        end
        index
      end
    end

    def self.index_file
      File.join(world.task_path, 'world.yml').tap do |name|
        IO.write name, BASE_INDEX.to_yaml unless File.exist?(name)
      end
    end

    def self.update
      IO.write index_file, build.to_yaml
    end

    def self.world
      @world ||= World.instance
    end
  end

  def self.index
    @@index ||= Index.read
  end
end
