class StoryReader < SimpleDSL
  def initialize(name, &block)
    @name = name
    instance_eval &block
  end

  values :queued, :started, :finished,
         :accepted, :rejected, :delivered,
         :weekdays, :weekends

  fields :id, :status, :points, :description, :restricted_to, :created_by
  groups :assigned_to

  # groups :tags
  custom :tags do |*args|
    args.flat_map do |tags|
      tags.to_s.split(/(?<!\\),/).map(&:strip)
    end
  end

  custom :comment do |author, body| (@comments ||= []) << {author: author, body: body} end
end
