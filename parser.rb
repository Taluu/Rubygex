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
                return OpenStruct.new(:name => token, :value => token)
            elsif token == '\\'
                return OpenStruct.new(:name => 'CHAR', :value => @iterator.next)
            else
                return OpenStruct.new(:name => 'CHAR', :value => token)
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

        s = 'end of input'

        if current
            s = '"%s"' % current.value
        end

        raise ParseError, "Found %s, expected one of %s" % [s, suggestions.inspect]
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
            @lexer.token # consume |
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
                @lexer.token # consume ?
                ast = $option.call(ast)
            elsif token.name == '*'
                @lexer.token # consume *
                ast = $closure.call(ast)
            elsif token.name == '+'
                @lexer.token # consume +
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
            @lexer.token # consume (
            ast = expr

            raise ParseError, "Unbalanced (" if not @lexer.token # consume )
        elsif token.name == 'CHAR'
            @lexer.token # consume CHAR
            ast = Char.new(token.value)
        else
            error(token, @@first['operand'])
        end

        check_ends('operand')
        return ast
    end
end
