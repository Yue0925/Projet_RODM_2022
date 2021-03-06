using Random
include("struct/tree.jl")

"""
Création de deux listes d'indices pour les jeux de données d'entrainement et de test
Entrées :\n
    - n le nombre de données dans le dataset
    - p la proportion que représente le jeu de données test
Sorties :\n
    - train, la liste des indices des données d'entrainement
    - test, la liste des indices des données de tesr
"""
function train_test_indexes(n::Int64,p::Float64=0.2)

    # Fixe la graine aléatoire pour assurer la reproductibilité
    Random.seed!(1)
    rd = randperm(n)

    test = rd[1:ceil(Int,n*p)]
    train = rd[ceil(Int,n*p)+1:n]

    return train,test
end

"""
Retourne le nombre d'erreurs de prédiction d'un arbre pour un ensemble de données

Entrées :
- T : l'arbre
- x : les données à prédire
- y : la classe des données

Sortie :
- class::Vector{Int64} : class prédites (class[i] est la classe de la donnée x[i, :])
"""
function prediction_errors(T::Tree, x::Matrix{Float64}, y::Vector{Int64})
    dataCount = length(x[:, 1])
    featuresCount = length(x[1, :])
    
    errors = 0
    
    for i in 1:dataCount
        t = 1
        for d in 1:(T.D+1)
            if T.c[t] != -1
                errors += T.c[t] != y[i]
                break
            else
                if sum(T.a[j, t]*x[i, j] for j in 1:featuresCount) - T.b[t] < 0
                    t = t*2
                else
                    t = t*2 + 1
                end
            end
        end
    end
    return errors
end

"""
Retourne la prédiction d'un arbre pour un ensemble de données

Entrées :
- T : l'arbre
- x : les données à prédire

Sortie :
- class::Vector{Int64} : class prédites (class[i] est la classe de la donnée x[i, :])
"""
function predict_class(T::Tree, x::Matrix{Float64})
    dataCount = length(x[:, 1])
    featuresCount = length(x[1, :])
    class = zeros(Int64, dataCount)
    
    for i in 1:dataCount
        t = 1
        for d in 1:(T.D+1)
            if T.c[t] != -1
                class[i] = T.c[t]
                break
            else
                if sum(T.a[j, t]*x[i, j] for j in 1:featuresCount) - T.b[t] < 0
                    t = t*2
                else
                    t = t*2 + 1
                end
            end
        end
    end
    return class
end


"""
Change l'échelle des caractéristiques d'un dataset pour les situer dans [0, 1]

Entrée :
- X: les caractéristiques du dataset d'origine

Sortie :
- caractéristiques entre 0 et 1
"""
function centerData(X)

    result = Matrix{Float64}(X)

    # Pour chaque caractéristique
    for j in 1:size(result, 2)
        
        m = minimum(result[:, j])
        M = maximum(result[:, j])
        result[:, j] .-= m
        result[:, j] ./= M
    end

    return result
end

function centerAndSaveDataSet(X, Y::Vector{Int64}, outputFile::String; center=true)
    if center
        centeredX = centerData(X)
    else
        centeredX = X
    end
    

    open(outputFile, "w") do fout
        println(fout, "X = ", centeredX)
        println(fout, "Y = ", Y)
    end    
end 



function readingData(fileName::String, delim::String)

    datafile = open(fileName)
    data = readlines(datafile)

    m = size(data, 1)
    line = filter(x -> x ≠ "" , split(data[1], delim))
    n = size(line, 1)
    
    X = zeros(m, n-2)
    Y = zeros(Int, ((m)))
    label = Dict("" => 0)
    max_class = 0

    l = 0
    for eachLine in data
        l += 1
        line = filter(x -> x ≠ "" , split(eachLine, delim))
        X[l, : ] .= parse.(Float64, line[2:n-1])

        if !haskey(label, line[n])
            max_class += 1
            label[line[n]] = max_class
        end

        Y[l] = label[line[n]]
    end

    # @show X[3, :]
    # @show Y[3]

    close(datafile)
    return X, Y
end


function transferData()
    X, Y = readingData("../data/ecoli.data", " ")
    centerAndSaveDataSet(X, Y, "../data/ecoli.txt", center=false)

    X, Y = readingData("../data/glass.data", ",")
    centerAndSaveDataSet(X, Y, "../data/glass.txt")
end
