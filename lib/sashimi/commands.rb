require 'optparse'

module Sashimi
  module Commands
    class Command
      attr_reader :script_name
      
      def initialize
        @script_name = File.basename($0)
      end
      
      def options
        OptionParser.new do |o|
          o.set_summary_indent('  ')
          o.banner =    "Usage: #{@script_name} [OPTIONS] command"
          o.define_head "Rails plugin manager."

          o.separator ""        
          o.separator "GENERAL OPTIONS"

          o.on("-v", "--verbose", "Turn on verbose output.") { |$verbose| }
          o.on("-h", "--help", "Show this help message.") { puts o; exit }

          o.separator ""
          o.separator "COMMANDS"

          o.separator "  install        Install plugin from known URL."
          o.separator "  uninstall      Uninstall plugin from local repository."
          o.separator "  update         Update installed plugin(s)."

          o.separator ""
          o.separator "EXAMPLES"
          o.separator "  Install a plugin from a subversion URL:"
          o.separator "    #{@script_name} install http://dev.rubyonrails.com/svn/rails/plugins/continuous_builder\n"
          o.separator "  Install a plugin from a git URL:"
          o.separator "    #{@script_name} install git://github.com/jodosha/click-to-globalize.git\n"
          o.separator "  Uninstall a plugin:"
          o.separator "    #{@script_name} uninstall continuous_builder\n"
          o.separator "  Update a plugin:"
          o.separator "    #{@script_name} update click-to-globalize\n"
        end
      end

      def parse!(args=ARGV)
        general, sub = split_args(args)
        options.parse!(general)

        command = general.shift
        if command =~ /^(install|uninstall|update)$/
          command = Commands.const_get(command.capitalize).new(self)
          command.parse!(sub)
        else
          puts "Unknown command: #{command}"
          puts options
          exit 1
        end
      end

      def split_args(args)
        left = []
        left << args.shift while args[0] and args[0] =~ /^-/
        left << args.shift if args[0]
        return [left, args]
      end

      def self.parse!(args=ARGV)
        Command.new.parse!(args)
      rescue Exception => e
        puts e.message
        exit 1
      end
    end
    
    class Install
      def initialize(base_command)
        @base_command = base_command        
      end
      
      def options
        OptionParser.new do |o|
          o.set_summary_indent('  ')
          o.banner =    "Usage: #{@base_command.script_name} install URL"
          o.define_head "Install a plugin."
        end
      end
      
      def parse!(args)
        options.parse!(args)
        args.each do |url|
          Plugin.new(nil, url).install
        end
      end
    end
  
    class Uninstall
      def initialize(base_command)
        @base_command = base_command        
      end
      
      def options
        OptionParser.new do |o|
          o.set_summary_indent('  ')
          o.banner =    "Usage: #{@base_command.script_name} uninstall PLUGIN"
          o.define_head "Remove an installed plugin."
        end
      end
      
      def parse!(args)
        options.parse!(args)
        args.each do |name|
          Plugin.new(name).uninstall
        end
      end
    end
    
    class Update
      def initialize(base_command)
        @base_command = base_command        
      end
      
      def options
        OptionParser.new do |o|
          o.set_summary_indent('  ')
          o.banner =    "Usage: #{@base_command.script_name} update PLUGIN"
          o.define_head "Update an installed plugin."
        end
      end
      
      def parse!(args)
        options.parse!(args)
        args.each do |name|
          Plugin.new(name).update
        end
      end
    end
  end
end
