#!/usr/bin/env ruby

#module Lexemes
    CAT     = ''
    UNION   = '|'
    OPTION  = '?'
    REPEAT  = '+'
    CLOSURE = '*'

    class Lexeme
        @@list = {UNION => 1,
                  CAT   => 2,

                  OPTION  => 3,
                  REPEAT  => 3,
                  CLOSURE => 3}

        
        attr_reader :prec
    end

    class Char < Lexeme
        attr_accessor :value

        def initialize(value)
            @prec  = 4
            @value = value
        end

        def to_str
            @value
        end
    end

    class Operator < Lexeme
        attr_reader :operator
    end

    class Unop < Operator
        attr_reader :argument

        def initialize(operator, argument)
            @operator = operator
            @argument = argument
            
            @prec = @@list[operator]
        end

        def to_str
            arg = @argument.to_str

            if (@argument.prec < @prec)
                arg = "(%s)" % arg
            end

            arg + @operator
        end
    end

    class Binop < Operator
        attr_reader :left, :right

        def initialize(operator, left, right)
            @left     = left
            @right    = right
            @operator = operator
            
            @prec = @@list[operator]
        end

        def to_str
            left, right = @left.to_str, @right.to_str

            if (@left.prec < @prec)
                left = "(%s)" % left
            end

            if (@right.prec < @prec)
                right = "(%s)" % right
            end

            left + @operator + right
        end
    end
#end
