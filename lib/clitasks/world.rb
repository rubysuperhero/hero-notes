module CliTasks
  class World
    include Singleton
    attr_writer :stories
    attr_accessor :use_index

    def configuration
      @configuration ||= Configuration.instance.tap(&:load)
    end
    alias_method :config, :configuration

    def reset
      config.instance_variables.each do |ivar|
        config.instance_variable_set(ivar, nil)
      end

      instance_variables.each do |ivar|
        instance_variable_set(ivar, nil)
      end
    end

    def stories
      @stories ||= []
    end

    def avoid_editor?
      return true if ENV.has_key? 'VIM'
      return true unless $stdout.tty?
      false
    end

    def task_path
      '%s/.index' % path
    end

    def temp_path
      '%s/tempfiles' % task_path
    end

    def path
      @path ||= config.path
    end
  end

  def self.world
    World.instance.tap do |w|
      Runner.run w.task_path
      w.use_index ||= false
    end
  end

  def self.stories
    world.stories
  end
end
