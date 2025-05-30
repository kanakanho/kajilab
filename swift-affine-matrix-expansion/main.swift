//
//  CalculateTransformationMatrix.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/02/07.
//

import simd
import Accelerate

//
//  Extension.swift
//  spatial-painting-rpc
//
//  Created by blueken on 2025/05/12.
//

import simd

/// The type alias to create a new name for SIMD3<Float>.
typealias Float3 = SIMD3<Float>

/// The type alias to create a new name for SIMD4<Float>.
typealias Float4 = SIMD4<Float>

/// The type alias to create a new name for simd_float4x4.
typealias Float4x4 = simd_float4x4

extension Float3 {
    // Initialize Float4 with Float3 inputs.
    init(_ float4: Float4) {
        self.init()
        
        x = float4.x
        y = float4.y
        z = float4.z
    }
}

extension Float4 {
    /// Ignore the W value to convert Float4 into Float3.
    func toFloat3() -> Float3 {
        Float3(self)
    }
}

extension Float4x4 {
    /// The value to access the identity of Float4x4.
    static var identity: Float4x4 {
        matrix_identity_float4x4
    }
    
    /// The translation component of Float4x4 and return as Float3.
    func translation() -> Float3 {
        columns.3.toFloat3()
    }
}

/// Create a mathematical clamp.
func clamp(_ valueX: Float, min minV: Float, max maxV: Float) -> Float {
    return min(maxV, max(minV, valueX))
}


extension simd_float3 {
    var list: [Float] {
        return [x, y, z]
    }
}

extension simd_float4 {
    var codable: [Float] {
        return [x, y, z, w]
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}


extension simd_float4x4 {
    var codable: [[Float]] {
        return [columns.0.codable, columns.1.codable, columns.2.codable, columns.3.codable]
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
    
    var floatList: [[Float]] {
        return [
            [self.columns.0.x, self.columns.0.y, self.columns.0.z, self.columns.0.w],
            [self.columns.1.x, self.columns.1.y, self.columns.1.z, self.columns.1.w],
            [self.columns.2.x, self.columns.2.y, self.columns.2.z, self.columns.2.w],
            [self.columns.3.x, self.columns.3.y, self.columns.3.z, self.columns.3.w]
        ]
     }
    
    var doubleList: [[Double]] {
        return [
            [Double(self.columns.0.x), Double(self.columns.0.y), Double(self.columns.0.z), Double(self.columns.0.w)],
            [Double(self.columns.1.x), Double(self.columns.1.y), Double(self.columns.1.z), Double(self.columns.1.w)],
            [Double(self.columns.2.x), Double(self.columns.2.y), Double(self.columns.2.z), Double(self.columns.2.w)],
            [Double(self.columns.3.x), Double(self.columns.3.y), Double(self.columns.3.z), Double(self.columns.3.w)]
        ]
    }
}

extension Float {
    func toDouble() -> Double {
        Double(self)
    }
}

extension Double {
    func toFloat() -> Float {
        Float(self)
    }
}

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
    
    func tosimd_float4x4() -> simd_float4x4 {
        return simd_float4x4([
            SIMD4<Float>(self[0][0].toFloat(), self[0][1].toFloat(), self[0][2].toFloat(), self[0][3].toFloat()),
            SIMD4<Float>(self[1][0].toFloat(), self[1][1].toFloat(), self[1][2].toFloat(), self[1][3].toFloat()),
            SIMD4<Float>(self[2][0].toFloat(), self[2][1].toFloat(), self[2][2].toFloat(), self[2][3].toFloat()),
            SIMD4<Float>(self[3][0].toFloat(), self[3][1].toFloat(), self[3][2].toFloat(), self[3][3].toFloat())
        ])
    }
}

extension [[Float]] {
    func tosimd_float4x4() -> simd_float4x4 {
        return simd_float4x4([
            SIMD4<Float>(self[0][0], self[0][1], self[0][2], self[0][3]),
            SIMD4<Float>(self[1][0], self[1][1], self[1][2], self[1][3]),
            SIMD4<Float>(self[2][0], self[2][1], self[2][2], self[2][3]),
            SIMD4<Float>(self[3][0], self[3][1], self[3][2], self[3][3])
        ])
    }
    
    func toDoubleList() -> [[Double]] {
        return self.map { $0.map { Double($0) } }
    }
}


func matmul(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
    let rowsA = A.count
    let colsA = A[0].count
    let colsB = B[0].count

    var result = Array(repeating: Array(repeating: 0.0, count: colsB), count: rowsA)
    for i in 0..<rowsA {
        for j in 0..<colsB {
            for k in 0..<colsA {
                result[i][j] += A[i][k] * B[k][j]
            }
        }
    }
    return result
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

        for k in 0..<4 {
            Y[i][k] = Q[i][k] - dot[k]
        }
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
        for k in 0..<3 {
            X[i][k] = (Y[i][k] - dot[k]) / U[i][i]
        }
    }

    return X
}

func svd(_ matrix: simd_double3x3) -> (U: simd_double3x3, S: simd_double3, V: simd_double3x3) {
    var a: [Double] = [
        matrix[0][0], matrix[0][1], matrix[0][2],
        matrix[1][0], matrix[1][1], matrix[1][2],
        matrix[2][0], matrix[2][1], matrix[2][2]
    ]
    var s = [Double](repeating: 0, count: 3)
    var u = [Double](repeating: 0, count: 9)
    var vt = [Double](repeating: 0, count: 9)
    var info = __CLPK_integer(0)
    var lwork = __CLPK_integer(-1)
    var work = [Double](repeating: 0, count: 1)
    
    var m = __CLPK_integer(3)
    var n = __CLPK_integer(3)
    var lda = m
    var ldu = m
    var ldvt = n
    var jobu: Int8 = 65 // 'A'
    var jobvt: Int8 = 65 // 'A'
    
    // Query and allocate the optimal workspace
    dgesvd_(&jobu, &jobvt, &m, &n, &a, &lda, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)
    
    lwork = __CLPK_integer(work[0])
    work = [Double](repeating: 0, count: Int(lwork))
    
    // Compute SVD
    dgesvd_(&jobu, &jobvt, &m, &n, &a, &lda, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)
    
    var U = simd_double3x3()
    var V = simd_double3x3()
    var S = simd_double3()
    
    for i in 0..<3 {
        S[i] = s[i]
        for j in 0..<3 {
            U[j][i] = u[i * 3 + j]
            V[i][j] = vt[j * 3 + i]
        }
    }
    
    return (U, S, V)
}

func dotsimd_double3x3(_ a: simd_double3x3,_ b: simd_double3x3) -> simd_double3x3 {
    var result = simd_double3x3()
    for i in 0..<3 {
        for j in 0..<3 {
            result[i][j] = a[i].x * b[0][j] + a[i].y * b[1][j] + a[i].z * b[2][j]
        }
    }
    return result
}

func polar(_ M: simd_double3x3) -> (simd_double3x3,simd_double3x3) {
    let (w,_,vh) = svd(M)
    // 内積を計算
    let u = simd_mul(vh, w)
    let p:simd_double3x3 = .init()
    return (u,p)
}

func removeScaleAffineMatrix(_ matrix: [[Double]]) -> [[Double]] {
    // 3x3 部分行列 (回転 + スケーリング)
    let M = simd_double3x3(
        SIMD3<Double>(matrix[0][0], matrix[1][0], matrix[2][0]),
        SIMD3<Double>(matrix[0][1], matrix[1][1], matrix[2][1]),
        SIMD3<Double>(matrix[0][2], matrix[1][2], matrix[2][2])
    )

    // 特異値分解
    let (R,_)  = polar(M)

    var newMatrix = matrix

    for i in 0..<3 {
        for j in 0..<3 {
            newMatrix[i][j] = Double(R[i][j])
        }
    }

    return newMatrix
}

func matmul4x4_4x1(_ A: [[Double]], _ B: [Double]) -> [Double] {
    var result = [Double](repeating: 0, count: 4)
    for i in 0..<4 {
        for j in 0..<3 {
            result[i] += A[i][j] * B[j]
        }
        result[i] += A[i][3]
    }
    return result
}

func rotation(axis: String, _ mine_hand_arrows_shift: [[Double]] ,_ world_hand_arrows_shfit: [[Double]], _ affineMatrix: [[Double]]) -> [[Double]] {
    var world_arrows_shift:[Double] = []
    switch axis {
    case "x":
        world_arrows_shift = world_hand_arrows_shfit[1]
    case "y":
        world_arrows_shift = world_hand_arrows_shfit[2]
    case "z":
        world_arrows_shift = world_hand_arrows_shfit[3]
    default:
        return[]
    }

    // 正規化
    for i in 0..<3 {
        world_arrows_shift[i] = world_arrows_shift[i] / sqrt(pow(world_arrows_shift[0], 2) + pow(world_arrows_shift[1], 2) + pow(world_arrows_shift[2], 2))
    }

    var mine_arrows_shift:[Double] = []
    switch axis {
    case "x":
        mine_arrows_shift = mine_hand_arrows_shift[1]
    case "y":
        mine_arrows_shift = mine_hand_arrows_shift[2]
    case "z":
        mine_arrows_shift = mine_hand_arrows_shift[3]
    default:
        return[]
    }

    // 正規化
    for i in 0..<3 {
        mine_arrows_shift[i] = mine_arrows_shift[i] / sqrt(pow(mine_arrows_shift[0], 2) + pow(mine_arrows_shift[1], 2) + pow(mine_arrows_shift[2], 2))
    }

    if world_arrows_shift.count != 3 {
        print("Error: world_arrows_shift must be 3 elements")
        return []
    }

    if mine_arrows_shift.count != 3 {
        print("Error: mine_arrows_shift must be 3 elements")
        return []
    }

    var theta_x = asin(world_arrows_shift[0])
    if axis == "x" {
        let mine_theta_x = asin(mine_arrows_shift[0])
        theta_x = mine_theta_x - theta_x
    }
    let theta_x_rotation = [
        [1, 0, 0, 0],
        [0, cos(theta_x), -sin(theta_x), 0],
        [0, sin(theta_x), cos(theta_x), 0],
        [0, 0, 0, 1]
    ]

    var theta_y = asin(world_arrows_shift[1])
    if axis == "y" {
        let mine_theta_y = asin(mine_arrows_shift[1])
        theta_y = mine_theta_y - theta_y
    }
    let theta_y_rotation = [
        [cos(theta_y), 0, sin(theta_y), 0],
        [0, 1, 0, 0],
        [-sin(theta_y), 0, cos(theta_y), 0],
        [0, 0, 0, 1]
    ]

    var theta_z = asin(world_arrows_shift[2])
    if axis == "z" {
        let mine_theta_z = asin(mine_arrows_shift[2])
        theta_z = mine_theta_z - theta_z
    }
    let theta_z_rotation = [
        [cos(theta_z), -sin(theta_z), 0, 0],
        [sin(theta_z), cos(theta_z), 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    let rotationMatrix = matmul(matmul(theta_x_rotation, theta_y_rotation), theta_z_rotation)

    switch axis {
    case "x":
        let returnAffineMatrix = [
            [rotationMatrix[0][0], rotationMatrix[0][1], rotationMatrix[0][2], affineMatrix[0][3]],
            [rotationMatrix[1][0], rotationMatrix[1][1], rotationMatrix[1][2], affineMatrix[1][3]],
            [rotationMatrix[2][0], rotationMatrix[2][1], rotationMatrix[2][2], affineMatrix[2][3]],
            [0, 0, 0, 1]
        ]
        return returnAffineMatrix
    case "y":
        let returnAffineMatrix = [
            [rotationMatrix[0][0], rotationMatrix[0][1], rotationMatrix[0][2], affineMatrix[0][3]],
            [rotationMatrix[1][0], rotationMatrix[1][1], rotationMatrix[1][2], affineMatrix[1][3]],
            [rotationMatrix[2][0], rotationMatrix[2][1], rotationMatrix[2][2], affineMatrix[2][3]],
            [0, 0, 0, 1]
        ]
        return returnAffineMatrix
    case "z":
        let returnAffineMatrix = [
            [rotationMatrix[0][0], rotationMatrix[0][1], rotationMatrix[0][2], affineMatrix[0][3]],
            [rotationMatrix[1][0], rotationMatrix[1][1], rotationMatrix[1][2], affineMatrix[1][3]],
            [rotationMatrix[2][0], rotationMatrix[2][1], rotationMatrix[2][2], affineMatrix[2][3]],
            [0, 0, 0, 1]
        ]
        return returnAffineMatrix
    default:
        return []
    }
}

func affineMatrixToAngle(_ matrix: [[Double]]) -> (Double, Double, Double) {
    let x = atan2(matrix[2][1], matrix[2][2])
    let y = atan2(-matrix[2][0], sqrt(pow(matrix[2][1], 2) + pow(matrix[2][2], 2)))
    let z = atan2(matrix[1][0], matrix[0][0])
    return (x, y, z)
}

func shiftRotateAffineMatrix(_ A: [[[Double]]], _ B: [[[Double]]], _ affineMatrix: [[Double]]) -> [[Double]] {
    // Bの位置を取得
    let B_pos = [B[0][0][3], B[0][1][3], B[0][2][3]]
    print("B_pos:", B_pos)

    let (x,y,z) = affineMatrixToAngle(B[0])
    print("x: \(x), y: \(y), z: \(z)")

    // B基準の単位ベクトル群（+X, +Y, +Z 方向）
    let B_vectors: [[Double]] = [
        B_pos,
        [B_pos[0] + cos(x), B_pos[1] + cos(y), B_pos[2] + cos(z)],
        [B_pos[0] + cos(z), B_pos[1] + cos(x), B_pos[2] + cos(y)],
        [B_pos[0] + cos(y), B_pos[1] + cos(z), B_pos[2] + cos(x)]
    ]

    // affineMatrixでB_vectorsをA空間に変換
    let transformedVectors = B_vectors.map { matmul4x4_4x1(affineMatrix, $0) }

    // シフト量（最初の点の差）
    let shift = zip(transformedVectors[0], B_vectors[0]).map { $0 - $1 }
    print("shift_value: \(shift)")

    // B側ベクトルを原点相対にシフト
    let shifted_B_vectors = B_vectors.map { zip($0, shift).map(-) }
    let B_origin = shifted_B_vectors[0]
    let B_relative = shifted_B_vectors.map { zip($0, B_origin).map(-) }

    // A側も同様にシフト
    let shifted_transformed = transformedVectors.map { zip($0, shift).map(-) }
    let A_origin = shifted_transformed[0]
    let A_relative = shifted_transformed.map { zip($0, A_origin).map(-) }

    // 回転補正（Y→Z→Xの順）
    let yMatrix = rotation(axis: "y", B_relative, A_relative, affineMatrix)
    // let zMatrix = rotation(axis: "z", B_relative, A_relative, yMatrix)
    // let xMatrix = rotation(axis: "x", B_relative, A_relative, zMatrix)
    
    // print("x_base_rotate_affine_matrix: \(yMatrix)")
    return yMatrix
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
    print("default")
    print(affineMatrix)

    affineMatrix = removeScaleAffineMatrix(affineMatrix)
    print("removeScaleAffineMatrix")
    print(affineMatrix)

    affineMatrix = shiftRotateAffineMatrix(A, B, affineMatrix)
    print("shiftRotateAffineMatrix")
    print(affineMatrix)

    return affineMatrix
}

// 逆行列を計算する関数
func inverseMatrix(_ matrix: [[Double]]) -> [[Double]] {
    let n = matrix.count
    guard n == 4 else {
        fatalError("Only 4x4 matrices are supported.")
    }

    var augmentedMatrix = matrix
    var identityMatrix = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)

    // 単位行列を作成
    for i in 0..<n {
        identityMatrix[i][i] = 1.0
    }

    // 拡大行列を作成
    for i in 0..<n {
        augmentedMatrix[i].append(contentsOf: identityMatrix[i])
    }

    // ガウス・ジョルダン法で逆行列を計算
    for i in 0..<n {
        // 対角成分を1にする
        let diagElement = augmentedMatrix[i][i]
        if abs(diagElement) < 1e-8 {
            fatalError("Matrix is singular and cannot be inverted.")
        }
        for j in 0..<(2 * n) {
            augmentedMatrix[i][j] /= diagElement
        }

        // 他の行を0にする
        for k in 0..<n {
            if k != i {
                let factor = augmentedMatrix[k][i]
                for j in 0..<(2 * n) {
                    augmentedMatrix[k][j] -= factor * augmentedMatrix[i][j]
                }
            }
        }
    }

    // 逆行列を抽出
    var inverseMatrix = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
    for i in 0..<n {
        inverseMatrix[i] = Array(augmentedMatrix[i][n..<(2 * n)])
    }

    return inverseMatrix
}


let A:[[[Double]]] = [
    [[-0.3128840923309326, 0.12130240350961685, -0.9420132637023926, 0.3145100176334381], [-0.5514543652534485, 0.7843160629272461, 0.2841581702232361, 1.5989069938659668], [0.7733054161071777, 0.6083859801292419, -0.1785074919462204, -0.5932660698890686], [0.0, 0.0, 0.0, 0.9999996423721313]], 
    [[-0.3121284246444702, 0.059167370200157166, -0.9481960535049438, 0.321004718542099], [-0.6517837047576904, 0.7127975225448608, 0.25903356075286865, 1.613938570022583], [0.6911978721618652, 0.698870062828064, -0.18392011523246765, -0.5829172730445862], [0.0, 0.0, 0.0, 1.0000003576278687]], 
    [[-0.2728814482688904, -0.03176158666610718, -0.9615229964256287, 0.32921576499938965], [-0.8450362682342529, 0.4856289029121399, 0.22378070652484894, 1.6123701333999634], [0.45983579754829407, 0.8735877871513367, -0.15935885906219482, -0.556111752986908], [0.0, 0.0, 0.0, 0.9999997019767761]], 
    [[-0.27880045771598816, 0.0018771730829030275, -0.9603473544120789, 0.3656771779060364], [-0.855580747127533, 0.4537019431591034, 0.24927225708961487, 1.6574891805648804], [0.4361794888973236, 0.8911516666412354, -0.12488625198602676, -0.4757072627544403], [0.0, 0.0, 0.0, 0.9999999403953552]]
]

let B:[[[Double]]] = [
    [[0.9211046695709229, 0.004325905814766884, -0.3892906606197357, -0.1078343614935875], [0.12849614024162292, 0.9405245184898376, 0.3144869804382324, 0.8784550428390503], [0.3674979507923126, -0.33969777822494507, 0.8657657504081726, -0.29763084650039673], [0.0, 0.0, 0.0, 0.9999997615814209]], 
    [[0.9291924834251404, -0.035733912140131, -0.3678649961948395, -0.11780022084712982], [0.15072035789489746, 0.9454307556152344, 0.2888677716255188, 0.8854509592056274], [0.3374684453010559, -0.32385849952697754, 0.8838728070259094, -0.2824503481388092], [0.0, 0.0, 0.0, 1.0000001192092896]], 
    [[0.9190733432769775, 0.3613074719905853, -0.15735726058483124, -0.1255972981452942], [-0.2827189564704895, 0.8826756477355957, 0.37543797492980957, 0.8833469748497009], [0.2745439410209656, -0.300567090511322, 0.9133919477462769, -0.27871888875961304], [0.0, 0.0, 0.0, 0.9999999403953552]], 
    [[0.8741697072982788, 0.4179137647151947, -0.24733686447143555, -0.20631766319274902], [-0.3572607636451721, 0.898422360420227, 0.25534653663635254, 0.9283444881439209], [0.3289259076118469, -0.13485242426395416, 0.9346776604652405, -0.22240567207336426], [0.0, 0.0, 0.0, 0.9999999403953552]]
]


print("Affine Matrix:")
print(calcAffineMatrix(A, B))

// let AA =  [
//         [
//             [
//                 0.5562306642532349,
//                 0.5555832386016846,
//                 -0.618008553981781,
//                 -0.24337060749530792,
//             ],
//             [
//                 -0.6506398320198059,
//                 0.7537873983383179,
//                 0.09204696118831635,
//                 0.7893363237380981,
//             ],
//             [
//                 0.5169867277145386,
//                 0.35090163350105286,
//                 0.780764102935791,
//                 -0.5038592219352722,
//             ],
//             [0.0, 0.0, 0.0, 1.0000001192092896],
//         ],
//         [
//             [
//                 -0.4974305033683777,
//                 -0.31042829155921936,
//                 -0.8100600242614746,
//                 -0.39988118410110474,
//             ],
//             [
//                 0.7428818345069885,
//                 -0.6346402764320374,
//                 -0.2129741758108139,
//                 0.7015295624732971,
//             ],
//             [
//                 -0.4479835033416748,
//                 -0.7077187299728394,
//                 0.5463011860847473,
//                 -0.3203715980052948,
//             ],
//             [0.0, 0.0, 0.0, 0.9999997615814209],
//         ],
//         [
//             [
//                 0.1541898101568222,
//                 0.5248171091079712,
//                 -0.8371332287788391,
//                 -0.06998009979724884,
//             ],
//             [
//                 -0.6118054986000061,
//                 0.7160078883171082,
//                 0.33619382977485657,
//                 0.6919271349906921,
//             ],
//             [
//                 0.7758345007896423,
//                 0.4603252410888672,
//                 0.43148720264434814,
//                 -0.5652991533279419,
//             ],
//             [0.0, 0.0, 0.0, 0.9999996423721313],
//         ],
//     ]

// let BB = [
//         [
//             [
//                 0.8661612868309021,
//                 0.361994206905365,
//                 -0.34456488490104675,
//                 -0.416620671749115,
//             ],
//             [
//                 -0.3561864495277405,
//                 0.930767834186554,
//                 0.08247461915016174,
//                 0.9175246953964233,
//             ],
//             [
//                 0.3505653142929077,
//                 0.05129300057888031,
//                 0.9351325035095215,
//                 -0.3071862459182739,
//             ],
//             [0.0, 0.0, 0.0, 0.9999997615814209],
//         ],
//         [
//             [
//                 0.6101363897323608,
//                 0.47927841544151306,
//                 -0.6308925747871399,
//                 -0.27676621079444885,
//             ],
//             [
//                 -0.39316582679748535,
//                 0.8744770884513855,
//                 0.28409498929977417,
//                 0.8279070854187012,
//             ],
//             [
//                 0.6878619194030762,
//                 0.07470865547657013,
//                 0.7219863533973694,
//                 -0.5423091053962708,
//             ],
//             [0.0, 0.0, 0.0, 0.9999997615814209],
//         ],
//         [
//             [
//                 -0.785858154296875,
//                 -0.19526691734790802,
//                 -0.586769163608551,
//                 -0.5836778879165649,
//             ],
//             [
//                 0.5389275550842285,
//                 -0.6815949082374573,
//                 -0.49496009945869446,
//                 0.8163708448410034,
//             ],
//             [
//                 -0.30328965187072754,
//                 -0.7051944136619568,
//                 0.6408713459968567,
//                 -0.20289365947246552,
//             ],
//             [0.0, 0.0, 0.0, 0.9999998807907104],
//         ],
//     ]

// print(calcAffineMatrix(AA, BB))


