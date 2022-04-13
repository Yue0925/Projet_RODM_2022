include("building_tree.jl")
include("building_tree_callback.jl")
include("utilities.jl")

function main(cb=false; onethread=false)

    # Pour chaque jeu de données
    for dataSetName in ["iris", "seeds", "wine"] # , "ecoli", "glass"
        
        print("=== Dataset ", dataSetName)

        # Préparation des données
        include("../data/" * dataSetName * ".txt") 
        train, test = train_test_indexes(length(Y))
        X_train = X[train, :]
        Y_train = Y[train]
        X_test = X[test, :]
        Y_test = Y[test]

        println(" (train size ", size(X_train, 1), ", test size ", size(X_test, 1), ", ", size(X_train, 2), ", features count: ", size(X_train, 2), ")")
        
        # Temps limite de la méthode de résolution en secondes
        time_limit = 30 #TODO : change to 60

        # Pour chaque profondeur considérée
        for D in 2:4

            println("  D = ", D)

            ## 1 - Univarié (séparation sur une seule variable à la fois)
            # Création de l'arbre
            if cb
                print("    Univarié(cb)...  \t")
                T, obj, resolution_time, gap = build_tree_callback(X_train, Y_train, D,  multivariate = false, time_limit = time_limit)
            else
                print("    Univarié...  \t")
                T, obj, resolution_time, gap = build_tree(X_train, Y_train, D,  multivariate = false, time_limit = time_limit, one_thread = onethread)
            end

            # Test de la performance de l'arbre
            print(round(resolution_time, digits = 1), "s\t")
            print("gap ", round(gap, digits = 1), "%\t")
            if T != nothing
                print("Erreurs train/test ", prediction_errors(T,X_train,Y_train))
                print("/", prediction_errors(T,X_test,Y_test), "\t")
            end
            println()

            ## 2 - Multivarié
            if cb
                print("    Multivarié(cb)...\t")
                T, obj, resolution_time, gap = build_tree_callback(X_train, Y_train, D, multivariate = true, time_limit = time_limit)
            else
                print("    Multivarié...\t")
                T, obj, resolution_time, gap = build_tree(X_train, Y_train, D, multivariate = true, time_limit = time_limit, one_thread = onethread)
            end
            
            print(round(resolution_time, digits = 1), "s\t")
            print("gap ", round(gap, digits = 1), "%\t")
            if T != nothing
                print("Erreurs train/test ", prediction_errors(T,X_train,Y_train))
                print("/", prediction_errors(T,X_test,Y_test), "\t")
            end
            println("\n")
        end
    end 
end


function table_main()
    cb=false; onethread=true
    fout = open("../res/main_1_thread.tex", "w")

    latex = raw"""\begin{table}[htbp]
    \centering
    \renewcommand{\arraystretch}{1.2}
    \begin{tabular}{|c|c|cc|c|c|c|c|cc|}
    \toprule
    \textbf{Data} & \textbf{Features} & \multicolumn{2}{c|}{\textbf{Size}} & \textbf{Profondeur} & \textbf{Séparation} & \textbf{Temps(s)} & \textbf{Gap} & \multicolumn{2}{c|}{\textbf{Erreur}} \\
    % \cmidrule(r){3-4} \cmidrule(r){9-10}
     & & \textbf{Train} & \textbf{Test} & & & & & \textbf{Train} & \textbf{Test} \\
    \midrule
    
    """
    println(fout, latex)

    # Pour chaque jeu de données
    for dataSetName in ["iris", "seeds", "wine", "ecoli", "glass"]
        
        print("=== Dataset ", dataSetName)
        print(fout, "\\multirow{6}*{\\textbf{" * dataSetName * "}} & ")

        # Préparation des données
        include("../data/" * dataSetName * ".txt") 
        train, test = train_test_indexes(length(Y))
        X_train = X[train, :]
        Y_train = Y[train]
        X_test = X[test, :]
        Y_test = Y[test]

        println(" (train size ", size(X_train, 1), ", test size ", size(X_test, 1), ", ", size(X_train, 2), ", features count: ", size(X_train, 2), ")")
        
        print(fout, "\\multirow{6}*{\\textbf{" * string(size(X_train, 2)) * "}} & \\multirow{6}*{\\textbf{" * string(size(X_train, 1)) * "}} & \\multirow{6}*{\\textbf{" * string(size(X_test, 1)) * "}} & ")
        # Temps limite de la méthode de résolution en secondes
        time_limit = 60 #TODO : change to 60

        # Pour chaque profondeur considérée
        for D in 2:4

            println("  D = ", D)
            if D>2
                print(fout, " & & & & ")
            end
            print(fout, "\\multirow{2}*{\\textbf{" * string(D) * "}} & ")

            ## 1 - Univarié (séparation sur une seule variable à la fois)
            # Création de l'arbre
            print(fout, "Univarié & ")
            if cb
                print("    Univarié(cb)...  \t")
                T, obj, resolution_time, gap = build_tree_callback(X_train, Y_train, D,  multivariate = false, time_limit = time_limit)
            else
                print("    Univarié...  \t")
                T, obj, resolution_time, gap = build_tree(X_train, Y_train, D,  multivariate = false, time_limit = time_limit, one_thread = onethread)
            end

            # Test de la performance de l'arbre
            print(round(resolution_time, digits = 1), "s\t")
            print("gap ", round(gap, digits = 1), "%\t")
            print(fout, round(resolution_time, digits = 1), " & ", round(gap, digits = 1), "\\% & ")

            if T != nothing
                print("Erreurs train/test ", prediction_errors(T,X_train,Y_train))
                print("/", prediction_errors(T,X_test,Y_test), "\t")
                println(fout, prediction_errors(T,X_train,Y_train), " & ", prediction_errors(T,X_test,Y_test), " \\\\")
            else
                println(fout, " &  \\\\")
            end
            println()

            print(fout, " & & & & & Multivarié & ")
            ## 2 - Multivarié
            if cb
                print("    Multivarié(cb)...\t")
                T, obj, resolution_time, gap = build_tree_callback(X_train, Y_train, D, multivariate = true, time_limit = time_limit)
            else
                print("    Multivarié...\t")
                T, obj, resolution_time, gap = build_tree(X_train, Y_train, D, multivariate = true, time_limit = time_limit, one_thread = onethread)
            end
            
            print(round(resolution_time, digits = 1), "s\t")
            print("gap ", round(gap, digits = 1), "%\t")
            print(fout, round(resolution_time, digits = 1), " & ", round(gap, digits = 1), "\\% & ")

            if T != nothing
                print("Erreurs train/test ", prediction_errors(T,X_train,Y_train))
                print("/", prediction_errors(T,X_test,Y_test), "\t")
                println(fout, prediction_errors(T,X_train,Y_train), " & ", prediction_errors(T,X_test,Y_test), "\\\\ \\cline{5-10}")
            else
                println(fout, " &  \\\\ \\cline{5-10}")
            end
            println("\n")
        end
    end 


    latex = raw"""\bottomrule
    \end{tabular}
    \caption{ .}
    \label{tab:main1Thr}
    \end{table}
"""
    println(fout, latex)
    close(fout)

end
