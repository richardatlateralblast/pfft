#!/usr/bin/env ruby

#!/usr/bin/env ruby

# Name:         pfft (PDF File Fixing Tool)
# Version:      0.0.3
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to fix PDF file that wont open on non Windows platforms
#               This most commonly occurs because of corrput/bad metadata or fonts
#               This tool uses pdfseparate and pdfunite to split and re-unit file
#               into a PDF file that will open in viewer

# Additional notes:
#
# Requires poppler

require 'rubygems'
require 'getopt/long'

# Some variables passed to all functions

script    = $0
pdf_split = %x[which pdfseparate].chomp
pdf_join  = %x[which pdfunite].chomp
work_dir  = "/tmp/"+File.basename(script,".rb")
gs_bin    = %x[which gs].chomp

# Check we have Poppler installed

if !pdf_split.match(/pdfseparate/)
  puts "Poppler tools not installed"
  puts "If you have brew installed, run 'brew install ghostscript'"
  exit
end

# Check we have Ghostscript installed

if !gs_bin.match(/gs/)
  puts "Ghostscript not installed"
  puts "If you have brew installed, run 'brew install poppler'"
  exit
end

# Get version

def get_version()
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version,packager,name
end

# Print script version information

def print_version()
  (version,packager,name) = get_version()
  puts name+" v. "+version+" "+packager
end

# Print uasage

def print_usage(script)
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  puts ""
  puts "Usage: "+script
  puts ""
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\[ "--/)
  option_list.each do |line|
    if !line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/,"").gsub(/\s+/,"")
      short_switch = switches[1].gsub(/\s+/,"")
      if long_switch.gsub(/\s+/,"").length < 7
        puts long_switch+",\t\t"+short_switch+"\t"+help_info
      else
        puts long_switch+",\t"+short_switch+"\t"+help_info
      end
    end
  end
  puts
  return
end

def print_changelog()
  if File.exist?("changelog")
    changelog = File.readlines("changelog")
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /,"")
      if line.match(/^[0-9]/)
        puts line
        puts changelog[index-1].gsub(/^# /,"")
        puts
      end
    end
  end
  return
end

# Get command line arguments
# Print help if given none

if !ARGV[0]
  print_usage(script)
  exit
end

# Try to make sure we have valid long switches

ARGV[0..-1].each do |switch|
  if switch.match(/^-[A-z][A-z]/)
    puts "Invalid command line option: "+switch
    exit
  end
end

begin
  option = Getopt::Long.getopts(
    [ "--input",     "-i", Getopt::REQUIRED ], # Input file
    [ "--verbose",   "-v", Getopt::BOOLEAN ],  # Verbose mode
    [ "--version",   "-V", Getopt::BOOLEAN ],  # Print version
    [ "--help",      "-h", Getopt::BOOLEAN ],  # Print usage
    [ "--changelog", "-c", Getopt::REQUIRED ], # Output file
    [ "--output",    "-o", Getopt::REQUIRED ]  # Output file
  )
rescue
  print_usage(script)
  exit
end

if option["version"]
  print_version()
  exit
end

if option["help"]
  print_usage(script)
  exit
end

if option["verbose"]
  verbose_mode = 1
else
  verbose_mode = 0
end

if !Dir.exist?(work_dir)
  Dir.mkdir(work_dir)
else
  if verbose_mode == 1
    puts "Cleaning up work directory "+work_dir
  end
  file_names = Dir.entries(work_dir)
  if file_names.to_s.match(/[0-9]/)
    %x[cd "#{work_dir}" ; rm *]
  end
end

def join_pdfs(work_dir,output_file,pdf_join,verbose_mode,gs_bin)
  pdf_files  = Dir.entries(work_dir).grep(/\.pdf$/)
  temp_file  = work_dir+"/temp.pdf"
  no_files   = pdf_files.length
  work_files = []
  for count in 1..no_files
    file_name = count.to_s+".pdf"
    work_files.push(file_name)
  end
  work_files = work_files.join(" ")
  command_line = "cd \"#{work_dir}\" ; \"#{pdf_join}\" #{work_files} \"#{temp_file}\""
  if verbose_mode == 1
    puts "Executing: "+command_line
  end
  %x[#{command_line}]
  command_line = "cd \"#{work_dir}\" ; \"#{gs_bin}\" -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -sOutputFile=\"#{output_file}\" \"#{temp_file}\""
  if verbose_mode == 1
    puts "Executing: "+command_line
  end
  %x[#{command_line}]
  return
end

def split_pdf(work_dir,input_file,pdf_split,verbose_mode,gs_bin)
  command_line = "cd \"#{work_dir}\" ; \"#{pdf_split}\" \"#{input_file}\" %d.pdf"
  if verbose_mode == 1
    puts "Executing: "+command_line
  end
  %x[#{command_line}]
  return
end

if option["input"]
  input_file = option["input"]
  if input_file.match(/^\~/)
    home_dir   = ENV["HOME"]
    input_file = input_file.gsub(/\~/,home_dir)
  end
  if !File.exist?(input_file)
    puts "Input file \""+input_file+"\" does not exist"
    exit
  end
  if input_file.match(/\//)
    if input_file.match(/^\./)
      input_dir = Dir.pwd
    else
      input_dir = File.dirname(input_file)
    end
  else
      input_dir = Dir.pwd
  end
else
  puts "No input file specified"
  exit
end

if option["output"]
  output_file = option["output"]
  if output_file.match(/^\~/)
    home_dir    = ENV["HOME"]
    output_file = output_file.gsub(/\~/,home_dir)
  end
  if output_file.match(/\//)
    output_dir = File.dirname(output_file)
    if !File.directory?(output_dir) and !File.symlink?(output_dir)
      puts "Output directory "+output_dir+" does not exist"
      exit
    end
  end
  output_file = output_file.gsub(/\.pdf$|\.PDF$/,"")
else
  output_file = input_file.gsub(/\.pdf$|\.PDF$/,"")
  output_file = output_file+"_fixed.pdf"
  if verbose_mode == 1
    puts "Setting output file name to "+output_file
  end
end

if input_file == output_file
  output_file = input_file.gsub(/\.pdf$|\.PDF$/,"")
  output_file = output_file+"_fixed.pdf"
  if verbose_mode == 1
    puts "Setting output file name to "+output_file
  end
else
  if !output_file.match(/\.pdf$|\.PDF$/)
    output_file = output_file+".pdf"
  end
end

split_pdf(work_dir,input_file,pdf_split,verbose_mode,gs_bin)
join_pdfs(work_dir,output_file,pdf_join,verbose_mode,gs_bin)
