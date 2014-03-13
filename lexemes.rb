#!/usr/bin/env ruby

module Compiler
    module Lexeme
        CAT     = ''
        UNION   = '|'
        OPTION  = '?'
        REPEAT  = '+'
        CLOSURE = '*'

        class Symbol
            attr_reader :prec

            def initialize(prec)
                @prec = prec
            end
        end

        class Char < Symbol
            attr_reader :value

            def initialize(value)
                super(4)
                @value = value
            end

            def to_s
                value = @value

                if '*|()+?'.include? value
                    value = '\\' + value
                end

                return value
            end
        end

        class Operator < Symbol
            @@list = {UNION => 1,
                      CAT   => 2,

                      OPTION  => 3,
                      REPEAT  => 3,
                      CLOSURE => 3}

            attr_reader :operator

            def initialize(operator)
                super(@@list[operator])

                @operator = operator
            end
        end

        class Unop < Operator
            attr_reader :argument

            def initialize(operator, argument)
                super(operator)

                @argument = argument
            end

            def to_s
                arg = @argument.to_s

                if (@argument.prec < @prec)
                    arg = "(%s)" % arg
                end

                return arg + @operator
            end
        end

        class Binop < Operator
            attr_reader :left, :right

            def initialize(operator, left, right)
                super(operator)

                @left  = left
                @right = right
            end

            def to_s
                left, right = @left.to_s, @right.to_s

                if (@left.prec < @prec)
                    left = "(%s)" % left
                end

                if (@right.prec < @prec)
                    right = "(%s)" % right
                end

                return left + @operator + right
            end
        end

        class << self
            def option(arg)
                Unop.new(OPTION, arg)
            end

            def repeat(arg)
                Unop.new(REPEAT, arg)
            end

            def closure(arg)
                Unop.new(CLOSURE, arg)
            end

            def cat(left, right)
                Binop.new(CAT, left, right)
            end

            def union(left, right)
                Binop.new(UNION, left, right)
            end

            def char(arg)
                Char.new(arg)
            end
        end
    end
end
