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

        def to_s
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

        def to_s
            left, right = @left.to_s, @right.to_s

            if (@left.prec < @prec)
                left = "(%s)" % left
            end

            if (@right.prec < @prec)
                right = "(%s)" % right
            end

            left + @operator + right
        end
    end

    $option  = lambda {|a| Unop.new(OPTION, a)}
    $repeat  = lambda {|a| Unop.new(REPEAT, a)}
    $closure = lambda {|a| Unop.new(CLOSURE, a)}

    $cat   = lambda {|a, b| Binop.new(CAT, a, b)}
    $union = lambda {|a, b| Binop.new(UNION, a, b)}
#end
