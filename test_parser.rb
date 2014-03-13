#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'parser.rb'

module Compiler
    trap("SIGINT") { raise Interrupt }

    while true do
        begin
            puts ">>> "
            puts Parser.new(Lexer.new(gets.chomp!)).parse
        rescue ParseError => e
            puts "[ERROR] " + e.message
        rescue Interrupt
            break
        end
    end
end

