#!/usr/bin/env ruby

#module Lexemes
    CAT     = ''
    UNION   = '|'
    OPTION  = '?'
    REPEAT  = '+'
    CLOSURE = '*'

    class Lexeme
        attr_reader :prec

        def initialize(prec)
            @prec = prec
        end
    end

    class Char < Lexeme
        attr_accessor :value

        def initialize(value)
            super(4)
            @value = value
        end

        def to_str
            @value
        end
    end

    class Operator < Lexeme
        @@list = {UNION => 1,
                  CAT   => 2,

                  OPTION  => 3,
                  REPEAT  => 3,
                  CLOSURE => 3}

        
        attr_reader :operator

        def initialize(operator)
            @operator = operator
            @prec     = @@list[operator] 
        end
    end

    class Unop < Operator
        attr_reader :argument

        def initialize(operator, argument)
            super(operator)

            @argument = argument
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
            super(operator)
            
            @left  = left
            @right = right
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
