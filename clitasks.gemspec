require File.expand_path("../lib/clitasks/version", __FILE__)

Gem::Specification.new do |s|
  s.name = 'clitasks'
  s.summary = 'CLI Tasks'
  s.description = 'File-based, command-line project manager.'
  s.version = CliTasks::VERSION
  s.date = '2014-04-26'
  s.authors = ['Joshua "unixsuperhero" Toyota']
  s.email = 'jearsh@gmail.com'
  s.files = [
    'lib/clitasks.rb',
    'lib/clitasks/commands.rb',
    'lib/clitasks/configuration.rb',
    'lib/clitasks/link_builder.rb',
    'lib/clitasks/runner.rb',
    'lib/clitasks/simple_dsl.rb',
    'lib/clitasks/story.rb',
    'lib/clitasks/story_reader.rb',
    'lib/clitasks/viewer.rb',
    'lib/clitasks/world.rb',
    'bin/task',
  ]
  s.executables = ['task']
  s.homepage = 'http://github.com/unixsuperhero/clitasks'
  s.license = 'MIT'
end