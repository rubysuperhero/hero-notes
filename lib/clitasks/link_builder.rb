module CliTasks
  class LinkBuilder
    attr_reader :world
    def initialize
      @world = World.instance
      @path = @world.path
      Runner.run @world.task_path
    end

    def self.all
      LinkBuilder.new.tap do |links|
        links.remove_all_symlinks
        links.by_tag
        links.by_status
        links.by_creator
        links.by_assignment
        links.by_restriction
      end
    end

    def remove_all_symlinks
      Dir[ [@path, '**/*'].join(?/) ].each do |file|
        next unless File.symlink?(file)
        FileUtils.rm(file)
      end
    end

    def create_link(type, dir, story)
      dir = sanitize(dir.to_s.dup) || return
      dest = File.join(@path, type, dir)
      link story, dest
    end

    def by_tag
      world.stories.each do |story|
        story.tags.each do |tag|
          create_link('tags', tag, story)
          create_link('all', tag, story)
        end
      end
    end

    def by_status
      world.stories.each do |story|
        create_link('status', story.status, story)
        create_link('all', story.status, story)
      end
    end

    def by_creator
      world.stories.each do |story|
        Array(story.created_by).each do |creator|
          create_link('created_by', creator, story)
          create_link('all', creator, story)
        end
      end
    end

    def by_restriction
      world.stories.each do |story|
        create_link('restricted_to', story.restricted_to, story)
        create_link('all', story.restricted_to, story)
      end
    end

    def by_assignment
      world.stories.each do |story|
        Array(story.assigned_to).each do |assignment|
          create_link('assigned_to', assignment, story)
          create_link('all', assignment, story)
        end
      end
    end

    private

    def sanitize(name)
      return unless name.is_a?(String) || name.is_a?(Symbol)
      String(name.to_s.dup).gsub(/(\W|_)+/, '_').sub(/^_*/, '').sub(/_*$/, '')
    end

    def link(story, dest)
      FileUtils.mkdir_p File.expand_path(dest)
      src = Pathname.new(File.expand_path(story.file))

      return false if File.exist?(File.join(dest, sanitize(story.name.to_s.dup)))
      FileUtils.ln_s src.relative_path_from(Pathname.new(File.expand_path(dest))), File.join(dest, sanitize(story.name.to_s.dup))
    end
  end
end
