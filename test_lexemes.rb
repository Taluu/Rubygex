#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes.rb'

a = $union.call($repeat.call($union.call(Char.new('a'), Char.new('b'))), $option.call(Char.new('c')))
puts a # prints ((a|b)+)|c?
