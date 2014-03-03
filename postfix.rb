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

    input.each_char do |c|
        if binops.include? c
            right, left = stack.pop, stack.pop

            raise IndexError if left.nil?
            raise IndexError if right.nil?

            stack << binops[c].call(left, right)
        elsif unops.include? c
            arg = stack.pop
            raise IndexError if arg.nil?

            stack << unops[c].call(arg)
        else
            stack << Char.new(c)
        end
    end

    stack.pop
end

trap("SIGINT") { raise Interrupt }

while true do
    begin
        puts ">>> "
        puts from_postfix(gets.chomp!)
    rescue IndexError
        puts "[ERROR] malformed expression"
    rescue Interrupt
        break
    end
end

