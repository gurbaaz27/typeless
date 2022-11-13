require_relative "parser"

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
        new_ast = Application.new left_lambda_term,right_lambda_term
    end
    new_ast
end

class Reducer
    def initialize ast
        @counter=0
        @hashmap=Hash[]
        @ast=ast
        @reduced=false
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


class BetaReducer 
    def initialize
        @reduced=false
    end

    def is_beta_reducible
        @reduced
    end

    def evaluate param, body, replacement
        if body.class == Variable
            if body.to_s == param.to_s
                deepcopy replacement
            end
        elsif body.class == Abstraction
            ## TODO
        elsif body.class == Application
            Application.new (evaluate param,body.children[0],replacement), (evaluate param,body.children[1],replacement)
        end 
    end

    def reduction_helper ast
        if ast.class == Variable
            Variable.new ast.to_s
        elsif ast.class == Abstraction
            Abstraction.new ast.children[0], (reduction_helper ast.children[1])
        elsif ast.class == Application
            if ast.children[0].class == Abstraction and not @reduced
                @reduction=true
                evaluate ast.children[0].children[0], ast.children[0].children[1], ast.children[1]
            else
                Application.new (reduction_helper ast.children[0]), (reduction_helper ast.children[1])
            end
        end
    end

    def reduction ast
        @reduced=false
        reduction_helper ast
    end
end