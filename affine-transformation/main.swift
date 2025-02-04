import simd

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension simd_float3 {
    var list: [Float] {
        return [x, y, z]
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        self.columns.3.xyz
    }
    
    init?(floatListStr: [String]) {
        let values = floatListStr.compactMap(Float.init)
        if values.count != 16 { return nil }
        
        self.init([
            SIMD4<Float>(values[0], values[1], values[2], values[3]),
            SIMD4<Float>(values[4], values[5], values[6], values[7]),
            SIMD4<Float>(values[8], values[9], values[10], values[11]),
            SIMD4<Float>(values[12], values[13], values[14], values[15])
        ])
    }
    
    var floatList: [Float] {
        return [
            self.columns.0.x, self.columns.0.y, self.columns.0.z, self.columns.0.w,
            self.columns.1.x, self.columns.1.y, self.columns.1.z, self.columns.1.w,
            self.columns.2.x, self.columns.2.y, self.columns.2.z, self.columns.2.w,
            self.columns.3.x, self.columns.3.y, self.columns.3.z, self.columns.3.w
        ]
      }
}

func generateAffineMatrix3DSelfLU(matrixAffineA: [simd_float4x4], matrixAffineAdash: [simd_float4x4]) -> simd_float4x4 {
    print(matrixAffineA, matrixAffineAdash)
    var pointsA = [simd_float3]()
    var pointsAdash = [simd_float3]()
    for i in 0..<matrixAffineA.count {
        pointsA.append(matrixAffineA[i].position)
        pointsAdash.append(matrixAffineAdash[i].position)
    }
    // let pointsA = matrixAffineA.map { $0.position }
    // let pointsAdash = matrixAffineAdash.map { $0.position }

    print(pointsA, pointsAdash)

    // let P = pointsA.map { SIMD4<Float>($0.x, $0.y, $0.z, 1.0) }
    var P = [simd_float4]()
    for i in 0..<pointsA.count {
        P.append(simd_float4(pointsA[i].x, pointsA[i].y, pointsA[i].z, 1.0))
    }
    let Q = pointsAdash
    print(P, Q)

    let PMatrix = simd_float4x4(columns: (
        SIMD4<Float>(P[0].x, P[1].x, P[2].x, P[3].x),
        SIMD4<Float>(P[0].y, P[1].y, P[2].y, P[3].y),
        SIMD4<Float>(P[0].z, P[1].z, P[2].z, P[3].z),
        SIMD4<Float>(P[0].w, P[1].w, P[2].w, P[3].w)
    ))

    let QMatrix = simd_float3x4(columns: (
        SIMD4<Float>(Q[0].x, Q[1].x, Q[2].x, 1.0),
        SIMD4<Float>(Q[0].y, Q[1].y, Q[2].y, 1.0),
        SIMD4<Float>(Q[0].z, Q[1].z, Q[2].z, 1.0)
    ))

    print("PMatrix, QMatrix")

    let affineMatrix = leastSquaresMethodLU(P: PMatrix, Q: QMatrix)
    return affineMatrix
}

// func LU(_ A: simd_float4x4) -> (L: simd_float4x4, U: simd_float4x4) {
//     var L = matrix_identity_float4x4
//     var U = simd_float4x4()
    
//     for i in 0..<4 {
//         for j in i..<4 {
//             U[i, j] = A[i, j] - dot(simd_float4(L[i, 0..<i]), simd_float4(U[0..<i, j]))
//         }
//         for j in (i+1)..<4 {
//             L[j, i] = (A[j, i] - dot(simd_float4(L[j, 0..<i]), simd_float4(U[0..<i, i]))) / U[i, i]
//         }
//     }
//     return (L, U)
// }

func LU(_ A: simd_float4x4) -> (simd_float4x4, simd_float4x4) {
    var U = A
    var L = matrix_identity_float4x4
    
    for i in 0..<4 {
        if U[i, i] == 0 {
            U[i, i] = 1e-8
        }
        
        for j in 0..<i {
            L[i, j] = U[i, j] / U[j, j]
            for k in j..<4 {
                U[i, k] -= L[i, j] * U[j, k]
            }
        }
    }

    print(L, U)
    
    return (L, U)
}

// func eqSolve(P: simd_float4x4, Q: simd_float3x4) -> simd_float3x4 {
//     let (L, U) = LU(P)
    
//     var Y = simd_float3x4()
//     for i in 0..<4 {
//         Y[i] = Q[i] - simd_mul(L[i, 0..<i], Y[0..<i])
//     }
    
//     var X = simd_float3x4()
//     for i in (0..<4).reversed() {
//         X[i] = (Y[i] - simd_mul(U[i, (i+1)..<4], X[(i+1)..<4])) / U[i, i]
//     }
    
//     return X
// }

func eqSolve(_ P: simd_float4x4, _ Q: simd_float4x4) -> simd_float4x4 {
    let (L, U) = LU(P)
    var Y = simd_float4x4()  // Y行列
    var X = simd_float4x4()  // X行列

    // 前進代入 L * Y = Q
    for i in 0..<4 {
        Y[i] = Q[i]  // Qの値をYの初期値に設定
        for j in 0..<i {
            Y[i] -= L[i, j] * Y[j]  // L * Y = Q を解く
        }
    }

    // 後退代入 U * X = Y
    for i in (0..<4).reversed() {
        X[i] = Y[i]  // YをXにコピー
        for j in (i+1)..<4 {
            X[i] -= U[i, j] * X[j]  // U * X = Y を解く
        }
        X[i] /= U[i, i]  // X[i] = Y[i] / U[i, i]
    }

    print(Y, X)

    return X
}

func leastSquaresMethodLU(P: simd_float4x4, Q: simd_float3x4) -> simd_float4x4 {
    let PTP = simd_mul(P.transpose,P)
    let X = simd_mul(simd_mul(PTP, P.transpose).transpose,Q)
    
    return simd_float4x4(
        SIMD4<Float>(X[0].x, X[1].x, X[2].x, X[3].x),
        SIMD4<Float>(X[0].y, X[1].y, X[2].y, X[3].y),
        SIMD4<Float>(X[0].z, X[1].z, X[2].z, X[3].z),
        SIMD4<Float>(0, 0, 0, 1)
    )
}

let matrixA1 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(1.2, 2.0, 1.6, 1.0)
)

let matrixA2 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(2.0, 1.0, 2.0, 1.0)
)

let matrixA3 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(1.5, 1.8, 1.8, 1.0)
)

let matrixB1 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(1.2, 1.4, 1.5, 1.0)
)

let matrixB2 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(1.3, 1.8, 1.6, 1.0)
)

let matrixB3 = simd_float4x4(
    SIMD4<Float>(1.0, 0.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 1.0, 0.0, 0.0),
    SIMD4<Float>(0.0, 0.0, 1.0, 0.0),
    SIMD4<Float>(1.4, 1.9, 1.7, 1.0)
)

let matrixA = [matrixA1, matrixA2, matrixA3]
let matrixB = [matrixB1, matrixB2, matrixB3]

let affineMatrix = generateAffineMatrix3DSelfLU(matrixAffineA: matrixA, matrixAffineAdash: matrixB)
print(affineMatrix.floatList)
