require_relative "lexer"

class LambdaTerm
    def initialize
    end
    def to_s
    end
    def children
    end
end

class Variable < LambdaTerm
    def initialize value
        @value=value
    end

    def set new_value
        @value=new_value
    end

    def to_s
        return @value
    end

    def children
        return []
    end
end

class Abstraction < LambdaTerm
    def initialize param,lambda_term
        @param=param
        @lambda_term=lambda_term
    end

    def to_s
        return "( \\ #{@param} . #{@lambda_term} )"
    end

    def children
        return [@param, @lambda_term]
    end

    def set_lambda_term lambda_term
        @lambda_term=lambda_term
    end
end

class Application < LambdaTerm
    def initialize left_lambda_term,right_lambda_term
        @left_lambda_term=left_lambda_term
        @right_lambda_term=right_lambda_term
    end

    def to_s
        return "[ #{@left_lambda_term} ] [ #{@right_lambda_term} ]"
    end

    def children
        return [@left_lambda_term, @right_lambda_term]
    end

    def set_left_lambda_term lambda_term
        @left_lambda_term=lambda_term
    end

    def set_right_lambda_term lambda_term
        @right_lambda_term=lambda_term
    end
end

class Parser
    def initialize code
        @code=code
        @counter=0
    end

    def error expected, found
        raise "Parser Error: Expected #{expected}, found '#{found}' at position #{@counter+1} (1-indexed)"
    end

    def current_char
        @code[@counter]
    end

    def advance_counter
        @counter += 1
    end

    def get_counter
        @counter
    end

    def expect expectation
        if expectation.include? current_char
            advance_counter
        else
            error expectation, current_char
        end
    end

    def variable
        term = current_char
        expect Token::VARIABLE
        return Variable.new term
    end

    def abstraction 
        expect Token::LEFT_PAREN
        expect Token::LAMBDA
        param = variable
        expect Token::DOT
        body = process 
        expect Token::RIGHT_PAREN
        Abstraction.new param,body
    end

    def application
        expect Token::LEFT_SQUARE
        left_lambda_term = process
        expect Token::RIGHT_SQUARE
        expect Token::LEFT_SQUARE
        right_lambda_term = process
        expect Token::RIGHT_SQUARE
        Application.new left_lambda_term, right_lambda_term
    end

    def process
        c = current_char
        case c
        when Token::VARIABLE
            variable
        when Token::LEFT_PAREN
            abstraction
        when Token::LEFT_SQUARE
            application
        else 
            return error "a known symbol", c
        end
    end

    def parse
        process
    end
end