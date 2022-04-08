include("building_tree.jl")
include("utilities.jl")
include("merge.jl")

function main_merge()
    for dataSetName in ["iris", "seeds", "wine", "ecoli", "glass"]
        
        print("=== Dataset ", dataSetName)
        
        # Préparation des données
        include("../data/" * dataSetName * ".txt") 
        train, test = train_test_indexes(length(Y))
        X_train = X[train,:]
        Y_train = Y[train]
        X_test = X[test,:]
        Y_test = Y[test]

        println(" (train size ", size(X_train, 1), ", test size ", size(X_test, 1), ", ", size(X_train, 2), ", features count: ", size(X_train, 2), ")")
        
        # Temps limite de la méthode de résolution en secondes        
        time_limit = 10 #TODO : change to 30

        for D in 2:4
            println("\tD = ", D)
            println("\t\tUnivarié")
            testSimpleMerge(X_train, Y_train, X_test, Y_test, D, time_limit = time_limit, isMultivariate = false)
            # break
            println("\t\tMultivarié")
            testSimpleMerge(X_train, Y_train, X_test, Y_test, D, time_limit = time_limit, isMultivariate = true)
        end
        # break
    end
end 


function testSimpleMerge(X_train, Y_train, X_test, Y_test, D; time_limit::Int=-1, isMultivariate::Bool = false)

    # Pour tout pourcentage de regroupement considéré
    println("\t\t\tGamma\t\t# clusters\tGap")

    for gamma in 0:0.2:1
        print("\t\t\t", gamma * 100, "%\t\t")

        clusters = simpleMerge(X_train, Y_train, gamma)

        print(length(clusters), " clusters\t")

        # println("\n\n")
        # @show clusters[1].dataIds

        # println("\n\n")
        # @show clusters[1].lBounds

        # println("\n\n")
        # @show clusters[1].uBounds

        # println("\n\n")
        # @show clusters[1].x

        # println("\n\n")
        # @show size(clusters[1].x, 1)

        # println("\n\n")
        # @show clusters[1].class
        # break

        T, obj, resolution_time, gap = build_tree(clusters, D, multivariate = isMultivariate, time_limit = time_limit)

        print(round(gap, digits = 1), "%\t") 
        print("Erreurs train/test : ", prediction_errors(T,X_train,Y_train))
        print("/", prediction_errors(T,X_test,Y_test), "\t")
        println(round(resolution_time, digits=1), "s")
    end
    println() 
end 


"""
Stocker les groupes en fonction γ dans "res/clusters/"
"""
function pre_processing()
    resFolder = "../res/clusters/"
    gamma0 = Dict("iris" => 3, "seeds" => 3, "wine" => 3, "ecoli" => 8, "glass" => 6)

    for dataSetName in ["iris", "seeds", "wine", "ecoli", "glass"]

        folder = resFolder * dataSetName
        if !isdir(folder)
            mkdir(folder)
        end

        print("=== Dataset ", dataSetName)
        
        # Préparation des données
        include("../data/" * dataSetName * ".txt") 
        train, test = train_test_indexes(length(Y))
        X_train = X[train,:]
        Y_train = Y[train]
        X_test = X[test,:]
        Y_test = Y[test]

        println(" (train size ", size(X_train, 1), ", test size ", size(X_test, 1), ", ", size(X_train, 2), ", features count: ", size(X_train, 2), ")")
        

        for gamma in 0:0.2:1
            print("\t\t\t", gamma * 100, "%\t\t")

            outputFile = folder * "/gamma_" * string(gamma)

            # if not solved
            if !isfile(outputFile)
                groups, groups_class = cplexFLPMerge(X_train, Y_train, gamma, gamma0[dataSetName])

                open(outputFile, "w") do fout
                    println(fout, "groups = ", groups)
                    println(fout, "groups_class = ", groups_class)
                end  
            end

        end

    end
end
