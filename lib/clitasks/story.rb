module CliTasks
  class Story
    attr_accessor :file
    attr_reader :id, :status, :points, :name, :description, :restricted_to
    def initialize(builder)
      builder.instance_variables.each{|name|
        instance_variable_set name, builder.instance_variable_get(name)
      }
    end

    def id
      @id ||= File.basename(file).sub(/[.]s?hdoc$/, '')
    end

    def tags
      return @tags if @tags != nil
      @tags ||= []
      @tags = @tags.sort
    end

    def comments
      @comments ||= []
    end

    def created_by
      @created_by ||= []
      @created_by &&= Array(@created_by)
    end

    def assigned_to
      @assigned_to ||= []
    end

    def self.build(name, &block)
      Story.new StoryReader.new(name, &block)
    end
  end

  def story(name, &block)
    stories << Story.build(name, &block)
  end

  def stories
    CliTasks.world.stories
  end
end

extend CliTasks
