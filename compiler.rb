require 'set'

class String
    def colorize(color_code)
      "\e[#{color_code}m#{self}\e[0m"
    end
  
    def red
      colorize(31)
    end
  
    def green
      colorize(32)
    end

    def yellow
      colorize(33)
    end
end

module Token
    NONE = ''
    DOT = '.'
    LAMBDA = '\\'
    LEFT_PAREN = '('
    RIGHT_PAREN = ')'
    LEFT_SQUARE = '['
    RIGHT_SQUARE = ']'
    WHITESPACE = ' '
    VARIABLE = ('a'..'z')
end

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

def free_variable ast
    if ast.class == Variable
        return Set[ast.to_s]
    elsif ast.class == Abstraction
        return (free_variable ast.children[1]) - (free_variable ast.children[0])
    elsif ast.class == Application
        return (free_variable ast.children[0]) + (free_variable ast.children[1])
    else
        raise "Free variables error: Unknown node type encountered in AST"
    end
end

def deepcopy ast
    if ast.class == Variable
        new_ast = Variable.new ast.to_s
    elsif ast.class == Abstraction
        param = deepcopy(ast.children[0])
        lambda_term = deepcopy(ast.children[1])
        new_ast = Abstraction.new param,lambda_term
    elsif ast.class == Application
        left_lambda_term = deepcopy(ast.children[0])
        right_lambda_term = deepcopy(ast.children[1])
        new_ast = Abstraction.new left_lambda_term,right_lambda_term
    end
    new_ast
end

class Reductor
    def initialize ast
        @counter=0
        @hashmap=Hash[]
        @ast=ast
    end

    def save_hashmap ast
        prev_val = ""
        had = false
        if @hashmap.has_key? ast.children[0].to_s 
            prev_val = @hashmap[ast.children[0].to_s]
            had = true
        end

        return prev_val, had
    end

    def restore_hashmap prev_val,had,ast 
        if had 
            @hashmap[ast.children[0].to_s] = prev_val
        elsif @hashmap.has_key? ast.children[0].to_s
            @hashmap.delete ast.children[0].to_s
        end
    end

    def alpha_renaming ast=@ast
        if ast.class == Abstraction
            prev_val, had = save_hashmap ast
            new_label = "v"+@counter.to_s
            @hashmap[ast.children[0].to_s] = new_label
            ast.children[0].set new_label
            @counter += 1
            alpha_renaming ast.children[1]
            restore_hashmap prev_val,had,ast
        elsif ast.class == Application
            alpha_renaming ast.children[0]
            alpha_renaming ast.children[1]
        elsif ast.class == Variable
            if @hashmap.has_key? ast.to_s 
                ast.set @hashmap[ast.to_s]
            end
        else
            raise "Alpha renaming error: Unknown node type encountered in AST"
        end
    end

    def free_variable_substitution fv,sub_ast,ast=@ast
        if ast.class == Abstraction
            lambda_term = ast.children[1]
            if lambda_term.class == Variable and lambda_term.to_s == fv
                ast.set_lambda_term deepcopy sub_ast
            else
                free_variable_substitution fv,sub_ast,ast.children[1]
            end 
        elsif ast.class == Application
            lambda_term = ast.children[0]
            if lambda_term.class == Variable and lambda_term.to_s == fv
                ast.set_left_lambda_term deepcopy sub_ast
            else
                free_variable_substitution fv,sub_ast,ast.children[0]
            end

            lambda_term = ast.children[1]
            if lambda_term.class == Variable and lambda_term.to_s == fv
                ast.set_right_lambda_term deepcopy sub_ast
            else
                free_variable_substitution fv,sub_ast,ast.children[1]
            end
        end
    end
end

def main
    if ARGV.length != 1
        puts "Too few arguments, path of input file needed"
        exit
    end

    filename = ARGV[0]

    code = File.open(filename).map(&:chomp).join(" ").delete(" ")

    parser = Parser.new code

    begin
    ast = parser.parse
    if code.length != parser.get_counter
        puts "Proceeding with only first #{parser.get_counter} character(s) in given lambda expression since they make a valid lambda-term".yellow
    end
    puts "#{ast} is a valid lambda term".green
    rescue Exception => err
        puts err
        puts "Nope, given expression is not a valid lambda-term".red
        exit
    end

    printf "List of free variables :- "
    begin
    fv = free_variable ast
    fv.each { |e| printf "#{e} "}
    printf "\n"
    rescue Exception => err
        puts err
        exit
    end

    reductor = Reductor.new ast

    printf "Alpha Renaming :- "
    begin
    ar = reductor.alpha_renaming
    rescue Exception => err
        puts err
        exit
    end
    puts ast


    puts "Please provide the free variable name along with its substitution. e.g. x:=M denotes replacing free occurences of x with lambda term M. Press ENTER to finish"
    begin
    while true
        substitutions = STDIN.gets.chomp
        if substitutions.empty?
            break
        end
        fv_sub = substitutions.split(":=")

        if fv_sub.length != 2
            puts "Please provide a valid free variable substitution of the form x:=M or press ENTER to finish"
            next
        end

        fv = fv_sub[0] 
        substitution = fv_sub[1] 

        o = Parser.new substitution

        sub_ast = o.parse

        reductor.free_variable_substitution fv,sub_ast

        puts ast
        
        puts "Provide next substitution or press ENTER to finish"
    end
    rescue Exception => err
        puts err
        puts "Given expression M is not a valid lambda-term".red
        puts "Please provide a valid free variable substitution of the form x:=M or press ENTER to finish"
        retry
    end
end

main
