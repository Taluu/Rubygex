#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes.rb'

$option  = lambda {|a| Unop.new(OPTION, a)}
$repeat  = lambda {|a| Unop.new(REPEAT, a)}
$closure = lambda {|a| Unop.new(CLOSURE, a)}

$cat   = lambda {|a, b| Binop.new(CAT, a, b)}
$union = lambda {|a, b| Binop.new(UNION, a, b)}

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

while true do
    begin
        puts ">>> "
        puts from_postfix(gets.chomp!)
    rescue IndexError
        puts "[ERROR] malformed expression"
    rescue Interrupt
    end
end
