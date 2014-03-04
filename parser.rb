#!/usr/bin/env ruby

$LOAD_PATH << './'
require 'lexemes.rb'
require 'ostruct'

module Kernel
    def typehint(argument, klass)
        raise ArgumentError, "Invalid argument. Expected %s, had %s" % [klass, argument.class.name] unless argument.kind_of? klass
    end
end

class Lexer
    attr_reader :input

    def initialize(input)
        typehint(input, String)

        @index    = 0
        @buffer   = nil
        @input    = input
        @iterator = input.each_char
    end

    def consume
        if not @buffer.nil?
            token, @buffer = @buffer, nil
            return token
        end

        token = nil

        begin
            token = @iterator.next

            if '*|()+?'.include? token
                token = OpenStruct.new(:name => token, :value => token, :index => @index)
            elsif token == '\\'
                token = OpenStruct.new(:name => 'CHAR', :value => @iterator.next, :index => @index)
                @index = @index + 1;
            else
                token = OpenStruct.new(:name => 'CHAR', :value => token, :index => @index)
            end

            @index = @index + 1;
        rescue StopIteration
        end

        return token
    end

    def peek
        if not @buffer
            @buffer = consume
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

    def parse
        ast = expr
        raise ParseError, "Unbalanced )" if @lexer.peek
        return ast
    end

    # Checks that the node can be used by the next token
    private
    def begins(node)
        token = @lexer.peek
        term  = if token then token.name else nil end

        return @@first[node].include? term
    end

    private
    def error(current, suggestions)
        typehint(suggestions, Array)

        s   = 'end of input'
        pos = ''

        if current
            s   = '"%s" on position %d' % [current.value, current.index + 1]
            pos = @lexer.input + "\n" + (' ' * (current.index)) + "^"
        end

        if suggestions.include? 'CHAR'
            suggestions[suggestions.index('CHAR')] = 'character'
        end

        if suggestions.include? nil
            suggestions[suggestions.index(nil)] = 'end of input'
        end

        raise ParseError, "Found %s, expected one of %s\n%s" % [s, suggestions.inspect, pos]
    end

    # Validates a node, as it should end with an expected token
    private
    def check_ends(node)
        token = @lexer.peek
        term  = if token then token.name else nil end

        error(token, @@following[node]) unless @@following[node].include? term
    end

    # Represents a expr rule
    #
    #   expr ::= cat '|' expr
    #         |  cat
    #
    private
    def expr
        ast   = cat
        token = @lexer.peek

        if token and token.name == '|'
            @lexer.consume # consume |
            ast = $union.call(ast, expr)
        end

        check_ends('expr')
        return ast
    end

    # Represents a cat rule
    #
    #   cat ::= unop cat
    #        |  unop
    #
    private
    def cat
        ast = unop

        if begins('cat')
            ast = $cat.call(ast, cat)
        end

        check_ends('cat')
        return ast
    end

    # Represents a unop rule
    #
    #   unop ::= operand '?'
    #         |  operand '*'
    #         |  operand '+'
    #         |  operand
    #
    private
    def unop
        ast   = operand
        token = @lexer.peek

        if token
            if token.name == '?'
                @lexer.consume # consume ?
                ast = $option.call(ast)
            elsif token.name == '*'
                @lexer.consume # consume *
                ast = $closure.call(ast)
            elsif token.name == '+'
                @lexer.consume # consume +
                ast = $repeat.call(ast)
            end
        end

        check_ends('unop')
        return ast
    end

    # Represents a operand rule
    #
    #   operand ::= '(' expr ')'
    #            |  CHAR
    #
    private
    def operand
        token = @lexer.peek

        error(token, @@first['operand']) unless token

        ast = nil

        if token.name == '('
            @lexer.consume # consume (
            ast = expr

            raise ParseError, "Unbalanced (" if not @lexer.consume # consume )
        elsif token.name == 'CHAR'
            @lexer.consume # consume CHAR
            ast = Char.new(token.value)
        else
            error(token, @@first['operand'])
        end

        check_ends('operand')
        return ast
    end
end
