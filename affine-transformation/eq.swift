import Accelerate

extension [[Float]] {
    var transpose4x4: [[Float]] {
        var result = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
        for i in 0..<4 {
            for j in 0..<4 {
                result[i][j] = self[j][i]
            }
        }
        return result
    }
}

func matrixMul4x4(_ A: [[Float]], _ B: [[Float]]) -> [[Float]] {
    var result = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
    for i in 0..<4 {
        for j in 0..<4 {
            for k in 0..<4 {
                result[i][j] += A[i][k] * B[k][j]
            }
        }
    }
    return result
}

func LU(_ A: [[Float]]) -> ([[Float]], [[Float]], [[Float]]) {
    var L: [[Float]] = []
    var U = A
    var P: [[Float]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    
    // 初期化: P を単位行列に
    for i in 0..<4 {
        P[i][i] = 1.0
        L[i][i] = 1.0  // L の対角成分は 1
    }

    for i in 0..<4 {
        // ピボット選択
        var maxRow = i
        for k in (i+1)..<4 {
            if abs(U[k][i]) > abs(U[maxRow][i]) {
                maxRow = k
            }
        }
        
        // 行の入れ替え (P, U)
        if maxRow != i {
            U.swapAt(i, maxRow)
            P.swapAt(i, maxRow)
            if i > 0 {
                L.swapAt(i, maxRow)
            }
        }

        // U の更新
        for j in i..<4 {
            var sum: Float = 0.0
            for k in 0..<i {
                sum += L[i][k] * U[k][j]
            }
            U[i][j] = A[i][j] - sum
        }

        // L の更新
        for j in (i+1)..<4 {
            var sum: Float = 0.0
            for k in 0..<i {
                sum += L[j][k] * U[k][i]
            }
            if U[i][i] == 0 {
                U[i][i] = 1e-8  // 0割り回避
            }
            L[j][i] = (A[j][i] - sum) / U[i][i]
        }
    }

    print("P:", P)
    print("L:", L)
    print("U:", U)
    return (P, L, U)
}

func eqSolve(_ A: [[Float]], _ Q: [[Float]]) -> [[Float]] {
    let (P, L, U) = LU(A)  // P行列も考慮
    var Y = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
    var X = [[Float]](repeating: [Float](repeating: 0, count: 4), count: 4)
    
    // P * Q を計算
    let PQ = matrixMul4x4(P, Q)

    // 前進代入 L * Y = P * Q
    for i in 0..<4 {
        Y[i] = PQ[i]
        for j in 0..<i {
            for k in 0..<4 { 
                Y[i][k] -= L[i][j] * Y[j][k]
            }
        }
    }

    // 後退代入 U * X = Y
    for i in (0..<4).reversed() {
        X[i] = Y[i]
        for j in (i+1)..<4 {
            for k in 0..<4 {
                X[i][k] -= U[i][j] * X[j][k]
            }
        }
        for k in 0..<4 {
            X[i][k] /= U[i][i]
        }
    }
    
    return X
}

func affineMatrix(_ A: [[[Float]]], _ B: [[[Float]]]) -> [[Float]] {
    var P:[[Float]] = []
    for i in (0..<3) {
        var rowP:[Float] = []
        for j in (0..<3) {
            rowP.append(A[j][i][3])
        }
        rowP.append(1.0)
        P.append(rowP)
    }
    P.append([0, 0, 0, 0])

    var Q:[[Float]] = []
    for i in (0..<3) {
        var rowQ:[Float] = []
        for j in (0..<3) {
            rowQ.append(B[j][i][3])
        }
        rowQ.append(0.0)
        Q.append(rowQ)
    }
    Q.append([0, 0, 0, 0])

    print(P, Q)

    let eqSolveMatrix = matrixMul4x4(eqSolve(matrixMul4x4(P.transpose4x4, P), P.transpose4x4), Q)
    var affineMatrix:[[Float]] = eqSolveMatrix.transpose4x4
    affineMatrix[3][3] = 1.0

    return affineMatrix
}

let A:[[[Float]]] = [
        [[1, 0, 0, 7],[0, 1, 0, 7],[0, 0, 1, 23],[0, 0, 0, 1]],
        [[1, 0, 0, 9],[0, 1, 0, 7],[0, 0, 1, 25],[0, 0, 0, 1]],
        [[1, 0, 0, 8],[0, 1, 0, 8],[0, 0, 1, 23],[0, 0, 0, 1]],
    ]

let B:[[[Float]]] = [
        [[1, 0, 0, 13],[0, 1, 0, 15],[0, 0, 1, 33],[0, 0, 0, 1]],
        [[1, 0, 0, 15],[0, 1, 0, 15],[0, 0, 1, 35],[0, 0, 0, 1]],
        [[1, 0, 0, 14],[0, 1, 0, 16],[0, 0, 1, 33],[0, 0, 0, 1]],
    ]

print(affineMatrix(A, B))