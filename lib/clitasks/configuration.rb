module CliTasks
  class Configuration
    include Singleton
    attr_accessor :created_by
    def load(file=nil)
      @file = file || '%s/.config.yml' % default_path
      @created_by = config[:created_by]
    end

    def config
      @config ||= defaults.merge(YAML.load_file(@file)) rescue defaults
    end

    def path
      config[:path]
    end

    def default_path
      defaults[:path]
    end

  private

    def defaults
      {
        path: '%s/tasks' % ENV['HOME'],
      }.with_indifferent_access
    end
  end
end
