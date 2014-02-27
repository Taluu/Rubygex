#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes.rb'

def from_postfix(input)
    unops = {'*' => $closure,
             '+' => $repeat,
             '?' => $option}

    binops = {'.' => $cat,
              '|' => $union}

    stack = []

    input.split("").each do |c|
        if binops.include? c
            right, left = stack.pop, stack.pop
            stack << binops[c].call(left, right)
        elsif unops.include? c
            arg = stack.pop
            stack << unops[c].call(arg)
        else
            stack << Char.new(c)
        end
    end

    stack.pop
end
        
trap("SIGINT") { exit! }

while true do
    begin
        puts ">>> "
        puts from_postfix(gets.chomp!)
    rescue IndexError
        puts "[ERROR] malformed expression"
    end
end
