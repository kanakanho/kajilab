import simd

// MARK: - SIMD Extensions
extension SIMD4 {
    var xyz: SIMD3<Scalar> { self[SIMD3(0, 1, 2)] }
}

extension simd_float3 {
    var list: [Float] { [x, y, z] }
}

extension simd_float4x4 {
    var position: SIMD3<Float> { columns.3.xyz }
    
    init?(floatListStr: [String]) {
        let values = floatListStr.compactMap(Float.init)
        guard values.count == 16 else { return nil }
        
        self.init([
            SIMD4<Float>(values[0], values[1], values[2], values[3]),
            SIMD4<Float>(values[4], values[5], values[6], values[7]),
            SIMD4<Float>(values[8], values[9], values[10], values[11]),
            SIMD4<Float>(values[12], values[13], values[14], values[15])
        ])
    }
    
    var floatList: [Float] {
        columns.flatMap { [$0.x, $0.y, $0.z, $0.w] }
    }
}

// MARK: - Affine Matrix Calculation
func generateAffineMatrix3DSelfLU(matrixAffineA: [simd_float4x4], matrixAffineAdash: [simd_float4x4]) -> simd_float4x4 {
    let pointsA = matrixAffineA.map { $0.position }
    let pointsAdash = matrixAffineAdash.map { $0.position }
    
    let P = pointsA.map { SIMD4<Float>($0, 1.0) }
    let Q = pointsAdash
    
    let PMatrix = simd_float4x4(columns: (
        SIMD4(P.map { $0.x }),
        SIMD4(P.map { $0.y }),
        SIMD4(P.map { $0.z }),
        SIMD4(P.map { $0.w })
    ))
    
    let QMatrix = simd_float3x4(columns: (
        SIMD4(Q.map { $0.x } + [1.0]),
        SIMD4(Q.map { $0.y } + [1.0]),
        SIMD4(Q.map { $0.z } + [1.0])
    ))
    
    return leastSquaresMethodLU(P: PMatrix, Q: QMatrix)
}

// MARK: - LU Decomposition
func LU(_ A: simd_float4x4) -> (simd_float4x4, simd_float4x4) {
    var U = A
    var L = matrix_identity_float4x4
    
    for i in 0..<4 {
        if abs(U[i, i]) < 1e-8 { U[i, i] = 1e-8 } // 0除算対策
        
        for j in i+1..<4 {
            L[j, i] = U[j, i] / U[i, i]
            for k in i..<4 {
                U[j, k] -= L[j, i] * U[i, k]
            }
        }
    }
    return (L, U)
}

// MARK: - Solve Linear Equations
func eqSolve(P: simd_float4x4, Q: simd_float4x4) -> simd_float4x4 {
    let (L, U) = LU(P)
    var Y = simd_float4x4()
    var X = simd_float4x4()
    
    for i in 0..<4 {
        Y[i] = Q[i] - (0..<i).reduce(SIMD4<Float>()) { $0 + L[i, $1] * Y[$1] }
    }
    
    for i in (0..<4).reversed() {
        X[i] = (Y[i] - (i+1..<4).reduce(SIMD4<Float>()) { $0 + U[i, $1] * X[$1] }) / U[i, i]
    }
    return X
}

// MARK: - Least Squares Method
func leastSquaresMethodLU(P: simd_float4x4, Q: simd_float3x4) -> simd_float4x4 {
    let PTP = simd_mul(P.transpose, P)
    let PTP_inv = eqSolve(P: PTP, Q: matrix_identity_float4x4) // PTPの逆行列を求める
    let X = simd_mul(simd_mul(PTP_inv, P.transpose), Q)
    
    return simd_float4x4(
        SIMD4(X[0].x, X[1].x, X[2].x, X[3].x),
        SIMD4(X[0].y, X[1].y, X[2].y, X[3].y),
        SIMD4(X[0].z, X[1].z, X[2].z, X[3].z),
        SIMD4(0, 0, 0, 1)
    )
}

// MARK: - Test Matrices
let matricesA = [
    simd_float4x4(translation: SIMD3(1.2, 2.0, 1.6)),
    simd_float4x4(translation: SIMD3(2.0, 1.0, 2.0)),
    simd_float4x4(translation: SIMD3(1.5, 1.8, 1.8))
]

let matricesB = [
    simd_float4x4(translation: SIMD3(1.2, 1.4, 1.5)),
    simd_float4x4(translation: SIMD3(1.3, 1.8, 1.6)),
    simd_float4x4(translation: SIMD3(1.4, 1.9, 1.7))
]

// 計算実行
let affineMatrix = generateAffineMatrix3DSelfLU(matrixAffineA: matricesA, matrixAffineAdash: matricesB)
print(affineMatrix.floatList)
