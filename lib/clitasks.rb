require 'fileutils'
require 'pry'
require 'pathname'
require 'singleton'
require 'yaml'
require 'active_support'
require 'active_support/core_ext'

if Dir['lib/clitasks.rb'].count > 0 && (Dir['.git'].count > 0 || ENV['CLIT_ENV'] == 'test')
  require './lib/clitasks/configuration'   # $HOME/repos/hnotes/lib/clitasks/configuration.rb
  require './lib/clitasks/world'           # $HOME/repos/hnotes/lib/clitasks/world.rb
  require './lib/clitasks/simple_dsl'      # $HOME/repos/hnotes/lib/clitasks/simple_dsl.rb
  require './lib/clitasks/story_reader'    # $HOME/repos/hnotes/lib/clitasks/story_reader.rb
  require './lib/clitasks/story'           # $HOME/repos/hnotes/lib/clitasks/story.rb
  require './lib/clitasks/runner'          # $HOME/repos/hnotes/lib/clitasks/runner.rb
  require './lib/clitasks/link_builder'    # $HOME/repos/hnotes/lib/clitasks/link_builder.rb
  require './lib/clitasks/viewer'          # $HOME/repos/hnotes/lib/clitasks/viewer.rb
  require './lib/clitasks/version'         # $HOME/repos/hnotes/lib/clitasks/version.rb
  require './lib/clitasks/note'        # $HOME/repos/hnotes/lib/clitasks/commands.rb
  require './lib/clitasks/commands'        # $HOME/repos/hnotes/lib/clitasks/commands.rb
else
  require 'clitasks/configuration'
  require 'clitasks/world'
  require 'clitasks/simple_dsl'
  require 'clitasks/story_reader'
  require 'clitasks/story'
  require 'clitasks/runner'
  require 'clitasks/link_builder'
  require 'clitasks/viewer'
  require 'clitasks/version'
  require 'clitasks/note'        # $HOME/repos/hnotes/lib/clitasks/commands.rb
  require 'clitasks/commands'
end

module CliTasks
end

