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

# Options parsing function. Returns an hash representing
# the options.
def parse_options
    options = {}
    args = []
    while (option = ARGV.shift)
        # --verbose is a global option
        if option == "--host" && ARGV.length >= 1
            options['host'] = ARGV.shift
        elsif option == "--port" && ARGV.length >= 1
            options['port'] = ARGV.shift.to_i
            if options['port'] == 0
                puts ">>> Invalid port specified."
                exit 1
            end
        elsif option == "--help"
            puts "Usage: gopher2redis --host <host> --port <port> [options]"
            puts "--host <hostname>      Specify the target Redis ip/host"
            puts "--port <port>          Specify the target Redis TCP port"
            puts "--write                Write keys without asking"
            puts "--help                 Show this help"
            exit 0
        else
            puts ">>> Unrecognized option or wrong arity: #{option}"
            exit 1
        end
    end

    # Check that the user specified at least the required arguments
    if !options['host'] || !options['port']
        puts ">>> Please specify at least the --host and --port options."
        puts ">>> Use the --help option for more info."
        exit 1
    end

    return options
end

def dir2keys
end

def main
    $opt = parse_options
end

main
