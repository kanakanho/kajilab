extension [[Double]] {
    var transpose4x4: [[Double]] {
        var result = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
        for i in 0..<4 {
            for j in 0..<4 {
                result[i][j] = self[j][i]
            }
        }
        return result
    }
}

func matrixMul4x4(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
    var result = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    for i in 0..<4 {
        for j in 0..<4 {
            for k in 0..<4 {
                result[i][j] += A[i][k] * B[k][j]
            }
        }
    }
    return result
}

func LU(_ A: [[Double]]) -> ([[Double]], [[Double]]) {
    var L = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    var U = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)

    for i in 0..<4 {
        L[i][i] = 1  // 対角成分は1

        for j in i..<4 {
            var sum: Double = 0.0
            for k in 0..<i {
                sum += L[i][k] * U[k][j]
            }
            U[i][j] = A[i][j] - sum
        }

        for j in (i+1)..<4 {
            var sum: Double = 0.0
            for k in 0..<i {
                sum += L[j][k] * U[k][i]
            }
            L[j][i] = (A[j][i] - sum) / (U[i][i])
        }
    }

    print("L:")
    for row in L {
        print(row)
    }
    print("U:")
    for row in U {
        print(row)
    }

    return (L, U)
}

func eqSolve(_ A: [[Double]], _ Q: [[Double]]) -> [[Double]] {
    var (L, U) = LU(A)
    var Y = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    var X = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)

    // 前進代入 L * Y = Q
    for i in 0..<4 {
        var dot = [Double](repeating: 0, count: 4)
        for j in 0..<i {
            for k in 0..<4 {
                dot[k] += L[i][j] * Y[j][k]
            }
        }
        
        print("L[i][k],dot \(i)")
        for k in 0..<4 {
            print("\(Q[i][k]), \(dot[k])")
        }

        for k in 0..<4 {
            Y[i][k] = Q[i][k] - dot[k]
        }
    }

    print("Y:")
    for row in Y {
        print(row)
    }

    // 後退代入 U * X = Y
    for i in stride(from: 3, through: 0, by: -1) {
        if abs(U[i][i]) < 1e-8 {  // 0除算防止
            print("Warning: U[\(i), \(i)] is nearly zero. Adding small value.")
            U[i][i] = 1e-8
        }
        var dot:[Double] = [0, 0, 0]
        for j in stride(from: 3, through: i+1, by: -1) {
            for k in 0..<3 {
                dot[k] += U[i][j] * X[j][k]
            }
        }

        print("Q[i][k],dot \(i)")
        for k in 0..<3 {
            print("\(Y[i][k]), \(dot[k])")
        }

        for k in 0..<3 {
            X[i][k] = (Y[i][k] - dot[k]) / U[i][i]
        }

    }

    print("X:")
    for row in X {
        print(row)
    }

    return X
}

/*
 let A:[[[Double]]] = [
        [[1, 0, 0, 7],[0, 1, 0, 9],[0, 0, 1, 8],[0, 0, 0, 1]],
        [[1, 0, 0, 7],[0, 1, 0, 7],[0, 0, 1, 8],[0, 0, 0, 1]],
        [[1, 0, 0, 23],[0, 1, 0, 25],[0, 0, 1, 23],[0, 0, 0, 1]],
    ]
 
 let B:[[[Double]]] = [
        [[1, 0, 0, 13],[0, 1, 0, 15],[0, 0, 1, 14],[0, 0, 0, 1]],
        [[1, 0, 0, 15],[0, 1, 0, 15],[0, 0, 1, 16],[0, 0, 0, 1]],
        [[1, 0, 0, 33],[0, 1, 0, 35],[0, 0, 1, 33],[0, 0, 0, 1]],
    ]
 
 calcAffineMatrix(A, B)
 */
func calcAffineMatrix(_ A: [[[Double]]], _ B: [[[Double]]]) -> [[Double]] {    
    var P:[[Double]] = []
    for i in (0..<3) {
        var rowP:[Double] = []
        for j in (0..<3) {
            rowP.append(A[i][j][3])
        }
        rowP.append(1.0)
        P.append(rowP)
    }
    P.append([0, 0, 0, 0])

    var Q:[[Double]] = []
    for i in (0..<3) {
        var rowQ:[Double] = []
        for j in (0..<3) {
            rowQ.append(B[i][j][3])
        }
        rowQ.append(0.0)
        Q.append(rowQ)
    }
    Q.append([0, 0, 0, 0])

    let eqSolveMatrix:[[Double]] = matrixMul4x4(eqSolve(matrixMul4x4(P.transpose4x4, P), P.transpose4x4), Q)
    var affineMatrix:[[Double]] = eqSolveMatrix.transpose4x4
    affineMatrix[3][3] = 1.0

    return affineMatrix
}


let A: [[[Double]]] = [
  [
    [0.29195672273635864, 0.20753134787082672, -0.9336443543434143, 0.3406505584716797], [0.10483368486166, 0.9633494019508362, 0.24691641330718994, 1.0227067470550537], [0.950668454170227, -0.16996638476848602, 0.25950002670288086, -0.4758530557155609], [0.0, 0.0, 0.0, 0.9999997019767761]
  ],
  [
    [-0.03469759598374367, 0.003780881641432643, -0.9993905425071716, 0.4099700152873993], [-0.5030160546302795, 0.8640282154083252, 0.02073289453983307, 1.005720853805542], [0.8635802268981934, 0.5034287571907043, -0.028077878057956696, -0.37334659695625305], [0.0, 0.0, 0.0, 0.9999998211860657]
  ],
  [
    [0.8126243948936462, -0.1172361671924591, -0.5708739757537842, 0.25409597158432007], [-0.23279379308223724, -0.9633129239082336, -0.13354729115962982, 1.0099575519561768], [-0.5342738628387451, 0.2414197027683258, -0.8101032972335815, -0.4570466876029968], [0.0, 0.0, 0.0, 0.9999997615814209]
  ]
]

let B: [[[Double]]] = [
  [
    [0.45655980706214905, 0.7681077122688293, 0.44895800948143005, -0.26391538977622986], [-0.23043100535869598, -0.38531294465065, 0.8935520052909851, 0.9078537225723267], [0.8593336939811707, -0.5114138126373291, 0.0010774779366329312, -0.5531684756278992], [0.0, 0.0, 0.0, 1.0]
  ],
  [
    [0.011919788084924221, -0.8203105926513672, -0.5717933177947998, -0.35877254605293274], [0.4230100214481354, -0.5140084028244019, 0.7462285757064819, 0.9013289213180542], [-0.9060462713241577, -0.25076937675476074, 0.34087279438972473, -0.5011917948722839], [0.0, 0.0, 0.0, 0.9999998807907104]
  ],
  [
    [0.4490292966365814, 0.4107557237148285, -0.7935065627098083, -0.29981839656829834], [-0.8199097514152527, 0.5423877835273743, -0.18320521712303162, 0.9066635370254517], [0.35513556003570557, 0.7328680157661438, 0.5803306698799133, -0.6528453826904297], [0.0, 0.0, 0.0, 1.0000001192092896]
  ]
]

//  AからBへのアフィン変換行列を計算
let affineMatrixAtoB = calcAffineMatrix(A, B)

//  BからAへのアフィン変換行列を計算
let affineMatrixBtoA = calcAffineMatrix(B, A)

print("Affine MatrixAtoB:")
for row in affineMatrixAtoB {
    print(row)
}

print("Affine MatrixBtoA:")
for row in affineMatrixBtoA {
    print(row)
}

// A[0] を B[0] に変換
let transformedA0 = matrixMul4x4(affineMatrixAtoB,A[0])
print("Transformed A[0] to B[0]:")
for row in transformedA0 {
    print(row)
}

print("B[0]:")
for row in B[0] {
    print(row)
}