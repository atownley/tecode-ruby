# Created: Sun  8 Aug 2010 19:59:17 IST

require 'rubygems'
require 'tecode/command'

parser = TECode::Command::Parser.new(__FILE__, "FILE[,FILE...]")
parser.add_options(TECode::Command::OptionGroup.new(
  TECode::Command::Option.new("create", "c",
              :description => "create a new archive") do |create, parser, args|
                if args.length == 0
                  STDERR.puts "error: refusing to create an empty archive."
                  parser.usage
                  exit 1
                end

                if (v = parser["verbose"]).matched? \
                    && (f = parser["file"]).matched?
                  puts "creating archive #{f.value}"
                end

                args.each do |l|
                  puts "adding #{l}" if v.matched?
                end

                if (x = parser["exclude"]).matched?
                  if v.matched?
                    x.value.each do |s|
                      puts "excluded #{s}"
                    end
                  end
                end
              end,

  TECode::Command::Option.new("extract", "x",
              :description => "extract files from the named archive"),

  TECode::Command::Option.new("file", "f",
              :has_arg => true,
              :help => "ARCHIVE",
              :description => "specify the name of the archive (default is stdout)"),

  TECode::Command::Option.new("verbose", "v",
              :description => "print status information during execution"),

  TECode::Command::RepeatableOption.new("exclude", "X",
              :has_arg => true,
              :help => "FILE | DIRECTORY",
              :description => "exclude the named file or directory from the archive")
))

parser.add_constraint(:mutex, 2, "create", "extract")
parser.add_constraint(:requires_any, 3, "file", "create", "extract")

parser.execute(ARGV) do |extras|
end
