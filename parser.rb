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

        @buffer   = nil
        @input    = input
        @iterator = input.each_char.with_index
    end

    def consume
        if not @buffer.nil?
            token, @buffer = @buffer, nil
            return token
        end

        token = nil

        begin
            token = @iterator.next

            if '*|()+?'.include? token[0]
                token = OpenStruct.new(:name => token[0], :value => token[0], :index => token[1])
            elsif token == '\\'
                token = OpenStruct.new(:name => 'CHAR', :value => @iterator.next[0], :index => token[1])
            else
                token = OpenStruct.new(:name => 'CHAR', :value => token[0], :index => token[1])
            end
        rescue StopIteration
        end

        return token
    end

    def peek
        if @buffer.nil?
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
               'expr'    => ['(', 'CHAR']}.freeze

    @@following = {'expr'    => [')', nil],
                   'cat'     => ['|', ')', nil],
                   'unop'    => ['(', 'CHAR', '|', ')', nil],
                   'operand' => ['?', '*', '+', '(', 'CHAR', ')', '|', nil]}.freeze

    def initialize(lexer)
        typehint(lexer, Lexer)

        @lexer = lexer
    end

    def parse
        ast = expr
        raise ParseError, "Unbalanced )" if not @lexer.peek.nil?
        return ast
    end

    # Checks that the node can be used by the next token
    private
    def begins(node)
        term = @lexer.peek

        if not term.nil?
            term = term.name
        end

        return @@first[node].include? term
    end

    private
    def error(current, suggestions)
        typehint(suggestions, Array)

        s   = 'end of input'
        pos = ''

        if not current.nil?
            s   = '"%s" on position %d' % [current.value, current.index + 1]
            pos = @lexer.input + "\n" + (' ' * (current.index)) + "^"
        end

        suggested = [];

        suggestions.each do |suggestion|
            case suggestion
                when 'CHAR'
                    suggestion = 'character'
                when nil
                    suggestion = 'end of input'
                else
                    suggestion = '"%s"' % suggestion
            end

            suggested.push(suggestion)
        end

        suggestions = suggestions.replace(suggested)

        suggested = suggestions[0...-1].join(',')

        if (1 < suggestions.length)
            suggested = suggested + ' or '
        end

        suggested = suggested + suggestions[-1]

        raise ParseError, "Found %s, expected %s\n%s" % [s, suggested, pos]
    end

    # Validates a node, as it should end with an expected token
    private
    def check_ends(node)
        term = @lexer.peek

        if not term.nil?
            term = term.name
        end

        error(@lexer.peek, @@following[node].dup) unless @@following[node].include? term
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

        if not token.nil? and token.name == '|'
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

        if not token.nil?
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

        error(token, @@first['operand'].dup) unless token

        ast = nil

        if token.name == '('
            @lexer.consume # consume (
            ast = expr

            raise ParseError, "Unbalanced (" if @lexer.consume.nil? # consume )
        elsif token.name == 'CHAR'
            @lexer.consume # consume CHAR
            ast = Char.new(token.value)
        else
            error(token, @@first['operand'].dup)
        end

        check_ends('operand')
        return ast
    end
end
