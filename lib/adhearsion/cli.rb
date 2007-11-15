require 'fileutils'

module Adhearsion
  module CLI
    module AhnCommand
      USAGE = <<USAGE
Usage:
   ahn create /path/to/directory
   ahn start [daemon] [directory]
   ahn version|-v|--v|-version|--version
   ahn help|-h|--h|--help|-help

Under development:
   ahn create:projectname /path/to/directory
USAGE
    
      def self.execute!
        CommandHandler.send(*parse_arguments)
      end
      
      def self.parse_arguments(args=ARGV.clone)
        action = args.shift
        case action
          when /^-?-?h(elp)?$/, nil   then [:help]
          when /^-?-?v(ersion)?$/     then [:version]
          when /^create(:([\w_.]+))?$/
            [:create, args.shift, $LAST_PAREN_MATCH || :default]
          when 'start'
            daemon, path = args
            path, daemon = daemon, path if !path || (path && daemon)
            [:start, path, daemon]
          when '-'
            [:start, Dir.pwd]
          else
            [action, *args]
        end
      end
      
      module CommandHandler
        class << self
          def create(path, project=:default)
            raise UnknownProject.new(project) if project != :default # TODO: Support other projects
            require 'rubigen'
            require 'rubigen/scripts/generate'
            source = RubiGen::PathSource.new(:application, 
              File.join(File.dirname(__FILE__), "../../app_generators"))
            RubiGen::Base.reset_sources
            RubiGen::Base.append_sources source
            RubiGen::Scripts::Generate.new.run([path], :generator => 'ahn')
          end
        
          def start(path, daemon=false)
            raise PathInvalid, path unless File.exists? path + "/.ahnrc"
            Adhearsion::Initializer.new path, :daemon => daemon
          end
        
          def version
            puts "Adhearsion v#{Adhearsion::VERSION::STRING}"
          end
        
          def help
            puts USAGE
          end
        
          def method_missing(action, *args)
            raise UnknownCommand, [action, *args] * " "
          end
        end
        
        class UnknownCommand < Exception
          def initialize(cmd)
            super "Unknown command: #{cmd}\n#{USAGE}"
          end
        end
        
        class UnknownProject < Exception
          def initialize(project)
            super "Application #{project} does not exist! Have you installed it?"
          end
        end
        
        class PathInvalid < Exception
          def initialize(path)
            super "Directory #{path} does not contain an Adhearsion project!"
          end
        end
      end
    end
  end
end