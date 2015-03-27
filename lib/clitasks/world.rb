module CliTasks
  class World
    include Singleton
    attr_writer :stories

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

    def task_path
      '%s/.index' % path
    end

    def path
      @path ||= config.path
    end
  end
end
