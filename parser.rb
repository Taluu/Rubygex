#!/usr/bin/env ruby

require 'lexemes.rb'
require 'ostruct'

module Kernel
    def typehint(argument, klass)
        raise ArgumentError, "Invalid argument. Expected %s, had %s" % [klass, argument.class.name] unless argument.kind_of? klass
    end
end

class Lexer
    def initialize(input)
        typehint(input, String)

        @buffer   = nil
        @iterator = input.each_char
    end

    def token
        if not @buffer.nil?
            token, @buffer = @buffer, nil
            return token
        end

        token = nil

        begin
            token = @iterator.next

            if '*|()+?'.include? token
                token = OpenStruct.new(:name => token, :value => token)
            elsif token == '\\'
                token = OpenStruct.new(:name => 'CHAR', :value => @iterator.next)
            else
                token = OpenStruct.new(:name => 'CHAR', :value => token)
            end
        rescue StopIteration
        end
    end

    def peek
        if not @buffer
            @buffer = self.token
        end

        return @buffer
    end
end

class ParseError < StandardError
end

class Parser
    @@first = {'operand' => ['(', 'CHAR'],
               'unop'    => ['(', 'CHAR'],
               'cat'     => ['(', 'CHAR'],
               'expr'    => ['(', 'CHAR']}

    @@following = {'expr'    => [')', nil],
                   'cat'     => ['|', ')', nil],
                   'unop'    => ['(', 'CHAR', '|', ')', nil],
                   'operand' => ['?', '*', '+', '(', 'CHAR', ')', '|', nil]}

    def initialize(lexer)
        typehint(lexer, Lexer)

        @lexer = lexer
    end

    # Checks that the node can be used by the next token
    private def begins(node)
        token = @lexer.peek
        term  = if token then token.name else nil end

        return @@first[node].include? term
    end

    private def error(current, suggestions)
        typehint(suggestions, Array)

        s = 'end of input'

        if current
            s = '"%s"' % current.value
        end

        raise ParserError, "Found %s, expected one of %s" % [s, suggestions.inspect]
    end

    # Validates a node, as it should end with an expected token
    private def end(node)
        token = @lexer.peek
        term  = if token then token.name else nil end

        error(token, @@following[node]) unless @@following[node].include? term
    end

    # Represents a expr rule
    #
    #   expr ::= cat '|' expr
    #         |  cat
    #
    private def expr
    end

    # Represents a cat rule
    #
    #   cat ::= unop cat
    #        |  unop
    #
    private def cat
    end

    # Represents a unop rule
    #
    #   unop ::= operand '?'
    #         |  operand '*'
    #         |  operand '+'
    #         |  operand
    #
    private def unop
    end

    # Represents a operand rule
    #
    #   operand ::= '(' expr ')'
    #            |  CHAR
    #
    private def operand
    end
end