require "set"
require_relative "parser"
require_relative "reducer"
require_relative "utils"

def main
    if ARGV.length != 1
        puts "Too few arguments, path of input file needed"
        exit
    end

    filename = ARGV[0]

    if not File.file?(filename)
        puts "File Not Found Error: No such file exists - #{filename}".red
        exit
    end

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
    free_variables_set = free_variable ast
    free_variables_set.each { |e| printf "#{e} "}
    printf "\n"
    rescue Exception => err
        puts err
        exit
    end

    reducer = Reducer.new ast

    printf "Alpha Renaming :- "
    begin
    reducer.alpha_renaming
    puts ast
    rescue Exception => err
        puts err
        exit
    end

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

        reducer.free_variable_substitution fv,sub_ast

        puts ast
        
        puts "Provide next substitution or press ENTER to finish"
    end
    rescue Exception => err
        puts err
        puts "Given expression M is not a valid lambda-term".red
        puts "Please provide a valid free variable substitution of the form x:=M or press ENTER to finish"
        retry
    end

    reducer.beta_reduction
end

main