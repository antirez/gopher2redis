#!/usr/bin/env ruby

# gopher2redis.rb
#
# Convert a directory structure into Redis keys suitable to serve
# such content in Redis Gopher mode.
#
# -------------------------------------------------------------------------------
#
# Copyright 2019 Salvatore Sanfilippo <antirez@gmail.com>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'redis'
require 'uri'

# Options parsing function. Returns an hash representing
# the options.
def parse_options
    options = {}
    args = []
    while (option = ARGV.shift)
        # --verbose is a global option
        if option == "--host" && ARGV.length >= 1
            options['host'] = ARGV.shift
        elsif option == "--localhost" && ARGV.length >= 1
            options['localhost'] = ARGV.shift
        elsif option == "--port" && ARGV.length >= 1
            options['port'] = ARGV.shift.to_i
        elsif option == "--localport" && ARGV.length >= 1
            options['localport'] = ARGV.shift.to_i
        elsif option == "--root" && ARGV.length >= 1
            options['root'] = ARGV.shift
        elsif option == "--all"
            options['all'] = true
        elsif option == "--help"
            puts "Usage: gopher2redis --host <host> --port <port> [options]"
            puts "--host <hostname>      Specify the target Redis ip/host"
            puts "--port <port>          Specify the target Redis TCP port"
            puts "--root <path>          Gopher root directory."
            puts "--localhost <hostname> Gopher hostname to generate local links."
            puts "--localport <port>     Gopher port to generate local links."
            puts "--all                  Process all files not just the ones"
            puts "                       starting with <prefix>-... like 0000-FOO"
            puts "                       The current directory otherwise."
            puts "--write                Write keys without asking"
            puts "--help                 Show this help"
            exit 0
        else
            puts ">>> Unrecognized option or wrong arity: #{option}"
            exit 1
        end
    end

    # Check that the user specified at least the required arguments
    if !options['host'] || !options['port'] || !options['localhost'] || \
       !options['localport']
        puts ">>> Please specify at least the --host and --port and "
        puts ">>> --local options. For example:"
        puts ">>>"
        puts ">>> gopher2redis.rb --host redisinstance --port 6379 \\"
        puts ">>> --localhost gopher.redis.io --localport 70"
        puts ">>>"
        puts ">>> Use the --help option for more info."
        exit 1
    end

    return options
end

def dir2keys(r,key,localhost,localport)
    content = ""
    items = Dir.entries(".").select{|e| e[0] != "."}.sort
    items = items.reverse if items.member?('REVERSE')
    items.each{|i|
        tokens = i.split("-")
        # Single words are options / modifiers, like REVERSE or HEADER
        # so let's skip what is not in the form PREFIX-TITLE
        next if tokens.length <= 1 && !$opt['all']

        # Render this entry, both in the listing and materialize it as a key
        # as well if it not a directory or an external link.
        if $opt['all']
            selector = i
        else
            selector = tokens[1..-1].join("-")
        end
        title = selector.gsub("_"," ")
        selector = "#{key}#{selector}/"
        type = title.split(".")[1]
        type.downcase if type
        if File.directory?(i)
            content << "1#{title}\t#{selector}\t#{localhost}\t#{localport}\n"
            # Recrusive call to generate the nested directory.
            puts ">>> Entering #{i}"
            Dir.chdir(i)
            dir2keys(r,selector,localhost,localport)
            Dir.chdir("..")
            puts "<<< Back to parent directory"
        else
            # Here we handle items that are not directories. We do
            # different handlings according to the exntension of the
            # file. The default is to handle such file as binary.
            type = "" if !type
            if ['zip','bin','gz','tgz'].member?(type)
                type = '9'
            elsif ['gif'].member?(type)
                type = 'g'
            elsif ['html','htm'].member?(type)
                type = 'h'
            elsif ['jpg','jpeg','png'].member?(type)
                type = 'I'
            elsif ['link'].member?(type)
                type = 'link'
            else
                # Every unknonw type default to plaintext. It's Gopher
                # after all!
                type = '0'
            end

            if type == 'link'
                uri = File.read(i).strip
                match = URI.regexp.match(uri)
                if !match
                    puts "--- #{i} link discarded, URI can't be parsed"
                else
                    # If there is no path, we have to assume document
                    # type is 1 (Gopher index) and selector the empty
                    # string.
                    if match[7]
                        link_type = match[7][1]
                        link_selector = match[7][2..-1]
                    else
                        link_type = '1'
                        link_selector = ""
                    end

                    # Default port is 70
                    if match[5]
                        link_port = match[5]
                    else
                        link_port = 70
                    end

                    link_host = match[4]
                end
                content << "#{link_type}#{title}\t#{link_selector}\t"+
                           "#{link_host}\t#{link_port}\n"
            else
                content << "#{type}#{title}\t#{selector}\t"+
                           "#{localhost}\t#{localport}\n"
                r.set(selector,File.read(i))
            end
            puts "+++ #{i} OK"
        end
    }
    r.set(key,content)
end

def main
    $opt = parse_options
    Dir.chdir($opt['root']) if $opt['root']
    r = Redis.new(:host => $opt['host'], :port => $opt['port'])
    dir2keys(r,"/",$opt['localhost'],$opt['localport'])
end

main
