include("building_tree.jl")
include("building_tree_callback.jl")
include("utilities.jl")
include("merge.jl")

function main_merge(cb=false; onethread=false, fout)
    for dataSetName in ["iris", "seeds", "wine", "ecoli", "glass"]
        
        print("=== Dataset ", dataSetName)
        print(fout, "\\multirow{18}*{"* dataSetName * "} & ")
        
        # Préparation des données
        include("../data/" * dataSetName * ".txt") 
        train, test = train_test_indexes(length(Y))
        X_train = X[train,:]
        Y_train = Y[train]
        X_test = X[test,:]
        Y_test = Y[test]

        println(" (train size ", size(X_train, 1), ", test size ", size(X_test, 1), ", ", size(X_train, 2), ", features count: ", size(X_train, 2), ")")
        print(fout, "\\multirow{18}*{" * string(size(X_train, 1),) * "} & \\multirow{18}*{" * string(size(X_test, 1)) * "} & ")
        # Temps limite de la méthode de résolution en secondes        
        time_limit = 30 #TODO : change to 30

        for D in 2:4
            println("\tD = ", D)
            if D > 2
                print(fout, " & & & \\multirow{12}*{" * string(D) * "} & ")
            else
                print(fout, "\\multirow{12}*{" * string(D) * "} & ")
            end
            
            if cb
                println("\t\tUnivarié(cb)")
            else
                println("\t\tUnivarié")
            end
            # if D > 2
            #     print(fout, " & & & \\multirow{6}*{Univarié} & " )
            # else
                print(fout, "\\multirow{6}*{Univarié} & " )
            # end
            testSimpleMerge(X_train, Y_train, X_test, Y_test, D, time_limit = time_limit, isMultivariate = false, cb=cb, onethread=onethread, fout=fout)
            # break

            if cb
                println("\t\tMultivarié(cb)")
            else
                println("\t\tMultivarié")
            end
            print(fout, " & & & & \\multirow{6}*{Multivarié} & " )
            testSimpleMerge(X_train, Y_train, X_test, Y_test, D, time_limit = time_limit, isMultivariate = true, cb=cb, onethread=onethread, fout=fout)
        end
        # break
    end
end 


function testSimpleMerge(X_train, Y_train, X_test, Y_test, D; time_limit::Int=-1, isMultivariate::Bool = false, cb=false, onethread=false, fout)

    # Pour tout pourcentage de regroupement considéré
    println("\t\t\tGamma\t\t# clusters\tGap")

    for gamma in 0:0.2:1
        if gamma > 0
            print(fout, " & & & & & " * string(gamma) * " & ")
        else
            print(fout, string(gamma) * " & ")
        end
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

        if cb
            T, obj, resolution_time, gap = build_tree_callback(clusters, D, multivariate = isMultivariate, time_limit = time_limit)
        else
            T, obj, resolution_time, gap = build_tree(clusters, D, multivariate = isMultivariate, time_limit = time_limit)
        end
        
        print(round(gap, digits = 1), "%\t") 
        print("Erreurs train/test : ", prediction_errors(T,X_train,Y_train))
        print("/", prediction_errors(T,X_test,Y_test), "\t")
        println(round(resolution_time, digits=1), "s")
        println(fout, string(round(resolution_time, digits=1)) * " & " * string(round(gap, digits = 1)) * " & " *
            string(prediction_errors(T,X_train,Y_train)) * " & " * string(prediction_errors(T,X_test,Y_test)) * "\\\\ ")
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


function table_main_merge(cb=false)
    onethread=true
    if cb
        fout = open("../res/main_merge_callback.tex", "w")
    else
        fout = open("../res/main_merge.tex", "w")
    end

    latex = raw"""\begin{table}[htbp]
    \centering
    \renewcommand{\arraystretch}{1.2}
    \begin{tabular}{|c|cc|c|c|c|c|c|cc|}
    \toprule
    \textbf{Data} & \multicolumn{2}{c|}{\textbf{Size}} & \textbf{Profondeur} & \textbf{Séparation} & $\mathbf{\gamma}$ & \textbf{Temps} & \textbf{Gap} & \multicolumn{2}{c|}{\textbf{Erreur}} \\
    % \cmidrule(r){3-4} \cmidrule(r){9-10}
     & \textbf{Train} & \textbf{Test} & & & & & & \textbf{Train} & \textbf{Test} \\
    \midrule
    """
    println(fout, latex)
    main_merge(cb, onethread=onethread, fout=fout)


    if cb
        latex = raw"""\bottomrule
    \end{tabular}
    \caption{Résultats numériques avec regroupement naïve utilisant callback .}
    \label{tab:mainMergeCallback}
    \end{table}
"""
    else
        latex = raw"""\bottomrule
    \end{tabular}
    \caption{Résultats numériques avec regroupement naïve .}
    \label{tab:mainMerge}
    \end{table}
"""
    end
    
    println(fout, latex)
    close(fout)
end

