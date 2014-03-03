#!/usr/bin/env ruby

require 'lexemes.rb'
require 'ostruct'

class Lexer
    def initialize(input)
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
