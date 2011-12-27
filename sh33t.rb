#!/usr/bin/env ruby
# == Synopsis
# This is a script that renders ERBs and inserts boilerplate such as header
# comments, vim modelines, and some basic functions and option parsing in
# some cases. All it takes to add support for a new type of file is to throw
# a file named ${type}.erb in the erb folder. You *must* pass something to -f
# and a type to -t. You can also add arbitrary variables to the .cfg file as
# it is blindly loaded. Note that you can add specific variables for certain
# scripts by adding a filetype.vars.rb file in erb folder. An example is the
# ppfile type, which needs to fill in a source variable.
#
# == Usage
#
# --author (-a)
#   This is the program author.
#
# --copyright (-c)
#   This is the Person or Entity that the Copyright section is pointed to.
#
# --edit (-e)
#   Automatically open file after creation for editing with vi.
#
# --file (-f)
#   Use this to set the output file.
#
# --help (-h)
#   Show this help
#
# --list (-l)
#   List available file types.
#
# --notes (-n)
#   These notes are put into certain templates in a notes section of the
#   comment headers.
#
# --synopsis (-s)
#   Overview of what the script/tool/library is for.
#   
# --type (-t)
#   Use this to set the filetype. Check for available ones with -l.
#
# == Notes
# Written for ruby 1.8, I know it won't work on 1.9.
#
# == Authors
# Joe McDonagh <jmcdonagh@thesilentpenguin.com>
#
# == Copyright
# 2011 The Silent Penguin LLC
#
# == License
# Licensed under the GPLv2 license.
#

require 'erb'
require 'getoptlong'
require 'rdoc/usage'
require 'time'

config_file = File.expand_path(File.dirname(__FILE__)) + File::SEPARATOR + "sh33t.cfg"
TOPLEVEL_BINDING.eval File.read(config_file)

def print_supported_filetypes(erbdir, filetypes)
   puts "Supported Filetypes:"

   filetypes.each do |filetype|
      filetype_desc = IO.readlines(erbdir + File::SEPARATOR + filetype + ".desc").join(" ").tr("\n", "")
      printf("%15s  %79s\n", filetype, filetype_desc)
   end
end

# Show usage if no args are passed.
if ARGV.size == 0
   RDoc::usage
end

# Set these to empty strings, making it necessary to use -f to set this.
chosen_filetype = ""
output_file = ""
editfile = false
notes = "This program sometimes overcooks the pizza."
synopsis = "This is a program that frizzenams the phacelem."

# Get ERB path.
erbdir = File.expand_path(File.dirname(__FILE__)) + "/erb"

if !File.exists? erbdir
   STDERR.puts "Couldn't find the ERB dir, exiting!"
   exit -1
end

# Make sure ERB dir isn't empty
if Dir.entries(erbdir) == [ ".", ".." ]
   STDERR.puts "ERB dir found but is somehow empty"
   exit -2
end

# Get supported filetypes by listing erb dir.
filetypes = Dir.glob(erbdir + "/*.erb")
filetypes.map! { |filetype| filetype = filetype.split(File::SEPARATOR)[-1] }
filetypes.map! { |filetype| filetype.gsub /\.erb$/, '' }

begin
   opts = GetoptLong.new(
      [ '--author',        '-a',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--copyright',     '-c',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--edit',          '-e',   GetoptLong::NO_ARGUMENT        ],
      [ '--file',          '-f',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--help',          '-h',   GetoptLong::NO_ARGUMENT        ],
      [ '--notes',         '-n',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--synopsis',      '-s',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--type',          '-t',   GetoptLong::REQUIRED_ARGUMENT  ],
      [ '--list',          '-l',   GetoptLong::NO_ARGUMENT        ]
   )

   opts.each do |opt, arg|
      case opt
         when '--author'
            author = arg
         when '--copyright'
            copyright = arg
         when '--edit'
            editfile = true
         when '--file'
            output_file = arg
         when '--help'
            RDoc::usage
         when '--list'
            print_supported_filetypes(erbdir, filetypes)
            exit 0
         when '--notes'
            notes = arg
         when '--synopsis'
            synopsis = arg
         when '--type'
            chosen_filetype = arg

            # Raise exception if set type not in available types.
            if !filetypes.member? chosen_filetype
               raise "Invalid filetype (-t)!"
            end
      end
   end

   if chosen_filetype.empty? or output_file.empty?
      raise "You must at minimum pass -t and -f!"
   end
rescue
   puts "Error: #{$!}"
   RDoc::usage
end

# Compute full path of possible extra vars file.
extra_vars_filepath = erbdir + File::SEPARATOR + chosen_filetype + ".vars.rb"

# load extra vars if they exist
if File.exists? extra_vars_filepath
   TOPLEVEL_BINDING.eval File.read(extra_vars_filepath)
end

# This is the full path to the ERB template used
template_filepath = erbdir + File::SEPARATOR + chosen_filetype + ".erb"

# Initialize an empty template var so the upcoming block fills this var in.
template = ""

begin
   File.open(template_filepath) do |f|
      template = f.read
   end
rescue
   STDERR.puts "Fatal Error reading in #{template_filepath}: #{$!}"
   exit -4
end

erb_template = ERB.new(template)

begin
   if !File.exists? output_file
      File.open(output_file, "w") { |f| f.puts erb_template.result(binding) }
   else
      STDERR.puts "You tried to write to a file that already exists!"
   end
rescue
   STDERR.puts "Error opening #{output_file}: #{$!}"
end

if editfile == true
   `vi #{outputfile}`
end

#vim: set expandtab ts=3 sw=3:
