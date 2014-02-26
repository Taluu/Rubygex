#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes.rb'

option  = lambda {|a| Unop.new(OPTION, a)}
repeat  = lambda {|a| Unop.new(REPEAT, a)}
closure = lambda {|a| Unop.new(CLOSURE, a)}

cat   = lambda {|a, b| Binop.new(CAT, a, b)}
union = lambda {|a, b| Binop.new(UNION, a, b)}

a = union.call(repeat.call(union.call(Char.new('a'), Char.new('b'))), option.call(Char.new('c')))
puts a
