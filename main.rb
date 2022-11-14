require "set"
require "optparse"
require_relative "parser"
require_relative "reducer"
require_relative "utils"

def main
    options = {}
    optparse = OptionParser.new do |opts|
        opts.banner = "Lambda Calculus Interpreter\n"\
                      "===========================\n" \
                      "Usage: main.rb [options]" \

        opts.on('-i', '--input FILE', 'Input file containing λ-expression') { |o| options[:input] = o }
        opts.on('-o', '--output FILE', '(Optional) Output file to store reduced λ-expression. Default: out.txt') { |o| options[:output] = o }

        options[:help] = opts.help
    end.parse!

    if options[:input].nil?
        abort(options[:help])
    end

    if options[:output].nil?
        options[:output] = "out.txt"
    end

    filename = options[:input]

    if not File.file?(filename)
        puts "FileNotFoundError: No such file exists - #{filename}".red
        exit
    end

    code = File.open(filename).map(&:chomp).join().delete(Token::WHITESPACE)

    parser = Parser.new code

    begin
    ast = parser.parse
    if code.length != parser.get_counter
        puts "Proceeding with only first #{parser.get_counter} character(s) in given lambda expression since they make a valid lambda-term".yellow
    end
    puts "#{ast} is a valid lambda term".green
    rescue Exception => err
        puts err
        puts "Nope, given expression #{code} is not a valid lambda-term".red
        exit
    end

    printf "Free variables :- "
    begin
    free_variables_set = free_variable ast
    if free_variables_set.length == 0
        printf "none"
    end
    free_variables_set.each { |e| printf "#{e} "}
    printf "\n"
    rescue Exception => err
        puts err
        exit
    end

    reducer = Reducer.new ast

    printf "α-renaming :- "
    begin
    reducer.alpha_renaming
    puts ast
    rescue Exception => err
        puts err
        exit
    end

    if free_variables_set.length != 0
        puts "Please provide the free variable name along with its substitution. e.g. x:=M denotes replacing free occurences of x with lambda term M or press ENTER to finish"
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
            
            reducer.alpha_renaming
            puts ast

            free_variables_set = free_variable ast

            if free_variables_set.length != 0
                puts "All free variables have been substituted successfully!".green
                break
            end

            puts "Provide next free variable substitution substitution or press ENTER to finish"
        end
        rescue Exception => err
            puts err
            puts "Given expression M is not a valid lambda-term".red
            puts "Please provide a valid free variable substitution of the form x:=M or press ENTER to finish"
            retry
        end
    end

    beta_reducer = BetaReducer.new reducer.get_counter

    is_beta_reducible = true
    reduced_ast = ast
    i = 1

    puts "β-reduction :- "

    while is_beta_reducible
        reduced_ast = beta_reducer.reduction reduced_ast
        is_beta_reducible = beta_reducer.is_beta_reducible
        if is_beta_reducible
            puts "Step #{i}. #{reduced_ast}"
            i += 1
        end
    end

    puts "No further reduction possible!".green
    puts "Final β-reduced form saved to #{options[:output]}:- ".green
    puts reduced_ast.to_s.green

    File.open(options[:output], "w") { |file| file.write(reduced_ast.to_s) }
end

main
