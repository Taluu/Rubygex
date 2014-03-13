#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes'

module Compiler
    a = Lexeme.union(Lexeme.repeat(Lexeme.union(Lexeme.char('a'), Lexeme.char('b'))), Lexeme.option(Lexeme.char('c')))
    puts a # prints ((a|b)+)|c?
end
