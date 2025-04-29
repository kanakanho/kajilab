//
//  CalculateTransformationMatrix.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/02/07.
//

import Foundation
import Accelerate
import simd

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

    func tosimd_double4x4() -> simd_double4x4 {
        return simd_double4x4([
            SIMD4<Double>(self[0][0], self[0][1], self[0][2], self[0][3]),
            SIMD4<Double>(self[1][0], self[1][1], self[1][2], self[1][3]),
            SIMD4<Double>(self[2][0], self[2][1], self[2][2], self[2][3]),
            SIMD4<Double>(self[3][0], self[3][1], self[3][2], self[3][3])
        ])
    }

    var position: [Double] {
        return [self[0][3], self[1][3], self[2][3]]
    }
}

extension simd_double3 {
    var toDoubleList: [Double] {
        return [self.x, self.y, self.z]
    }
}

extension simd_double3x3 {
    func toDoubleList() -> [[Double]] {
        return [
            self.columns.0.toDoubleList,
            self.columns.1.toDoubleList,
            self.columns.2.toDoubleList
        ]
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
            // result[i][j] = a[i].dot(b[j])
            result[i][j] = a[i].x * b[0][j] + a[i].y * b[1][j] + a[i].z * b[2][j]
        }
    }
    return result
}

func polar(_ M: simd_double3x3) -> (simd_double3x3,simd_double3x3) {
    let (w,s,vh) = svd(M)
    print("w: \(w)")
    print("s: \(s)")
    print("vh: \(vh)")
    // 内積を計算
    // let u = w * vh
    let u = simd_mul(vh, w)
    // let p = simd_mul(simd_mul(vh.transpose, s),vh)
    // let p = vh.transpose * simd_double3x3(diagonal: s) * vh
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
    print("R: \(R)")

    var newMatrix = matrix

    for i in 0..<3 {
        for j in 0..<3 {
            newMatrix[i][j] = Double(R[i][j])
        }
    }

    return newMatrix
}

func rotation(axis: String, _ world_hand_arrows_shfit: [[Double]], _ affineMatrix: [[Double]]) -> [[Double]] {
    var arrows_shift:[Double] = []
    switch axis {
    case "x":
        arrows_shift = world_hand_arrows_shfit[1]
    case "y":
        arrows_shift = world_hand_arrows_shfit[2]
    case "z":
        arrows_shift = world_hand_arrows_shfit[3]
    default:
        return[]
    }

    if arrows_shift.count != 3 {
        print("Error: arrows_shift must be 3 elements")
        return []
    }

    print("arrows_shift: \(arrows_shift)")

    let theta_x = asin(arrows_shift[0])
    let theta_x_rotation = [
        [1, 0, 0, 0],
        [0, cos(theta_x), -sin(theta_x), 0],
        [0, sin(theta_x), cos(theta_x), 0],
        [0, 0, 0, 1]
    ]

    let theta_y = asin(arrows_shift[1])
    let theta_y_rotation = [
        [cos(theta_y), 0, sin(theta_y), 0],
        [0, 1, 0, 0],
        [-sin(theta_y), 0, cos(theta_y), 0],
        [0, 0, 0, 1]
    ]

    let theta_z = asin(arrows_shift[2])
    let theta_z_rotation = [
        [cos(theta_z), -sin(theta_z), 0, 0],
        [sin(theta_z), cos(theta_z), 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    print("theta_x: \(theta_x)")
    print("theta_x_rotation: \(theta_x_rotation)")
    print("theta_y: \(theta_y)")
    print("theta_y_rotation: \(theta_y_rotation)")
    print("theta_z: \(theta_z)")
    print("theta_z_rotation: \(theta_z_rotation)")

    switch axis {
    case "x":
        return matmul(affineMatrix,theta_y_rotation)
    case "y":
        return matmul(matmul(matmul(affineMatrix, theta_z_rotation), theta_y_rotation), theta_x_rotation)
    case "z":
        return matmul(affineMatrix, theta_y_rotation)
    default:
        return []
    }
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

func shiftRotateAffineMatrix(_ A: [[[Double]]],_ B: [[[Double]]],_ affineMatrix: [[Double]]) -> [[Double]] {
    print("B_right_arrows:")
    print(B[0][0][3], B[0][1][3], B[0][2][3])
    let B_right_potion: [Double] = [B[0][0][3], B[0][1][3], B[0][2][3]]
    let B_right_arrows: [[Double]] = [
        B_right_potion,
        [B_right_potion[0] + 1, B_right_potion[1], B_right_potion[2]],
        [B_right_potion[0], B_right_potion[1] + 1, B_right_potion[2]],
        [B_right_potion[0], B_right_potion[1], B_right_potion[2] + 1]
    ]

    print("B_right_arrows: \(B_right_arrows)")

    var A_to_B_right_arrows: [[Double]] = []
    for i in 0..<4 {
        A_to_B_right_arrows.append(matmul4x4_4x1(affineMatrix, B_right_arrows[i]))
    }

    print("B_right_arrows: \(B_right_arrows)")
    print("A_to_B_right_arrows: \(A_to_B_right_arrows)")

    // 位置を補正する
    let shift_value: [Double] = {
        var shift_value: [Double] = []
        for i in 0..<3 {
            shift_value.append(A_to_B_right_arrows[0][i] - B_right_arrows[0][i])
        }
        return shift_value
    }()

    print("shift_value: \(shift_value)")

    // let A_right_arrows_shift: [[Double]] = [
    //     [A_right_arrows[0][0] - shift_value[0], A_right_arrows[0][1] - shift_value[1], A_right_arrows[0][2] - shift_value[2]],
    //     [A_right_arrows[1][0] - shift_value[0], A_right_arrows[1][1] - shift_value[1], A_right_arrows[1][2] - shift_value[2]],
    //     [A_right_arrows[2][0] - shift_value[0], A_right_arrows[2][1] - shift_value[1], A_right_arrows[2][2] - shift_value[2]],
    //     [A_right_arrows[3][0] - shift_value[0], A_right_arrows[3][1] - shift_value[1], A_right_arrows[3][2] - shift_value[2]]
    // ]

    let A_to_B_right_arrows_shift_value: [[Double]] = [
        [A_to_B_right_arrows[0][0] - shift_value[0], A_to_B_right_arrows[0][1] - shift_value[1], A_to_B_right_arrows[0][2] - shift_value[2]],
        [A_to_B_right_arrows[1][0] - shift_value[0], A_to_B_right_arrows[1][1] - shift_value[1], A_to_B_right_arrows[1][2] - shift_value[2]],
        [A_to_B_right_arrows[2][0] - shift_value[0], A_to_B_right_arrows[2][1] - shift_value[1], A_to_B_right_arrows[2][2] - shift_value[2]],
        [A_to_B_right_arrows[3][0] - shift_value[0], A_to_B_right_arrows[3][1] - shift_value[1], A_to_B_right_arrows[3][2] - shift_value[2]]
    ]

    let A_to_B_right_arrows_shift: [[Double]] = [
        [A_to_B_right_arrows_shift_value[0][0] - A_to_B_right_arrows_shift_value[0][0], A_to_B_right_arrows_shift_value[0][1] - A_to_B_right_arrows_shift_value[0][1], A_to_B_right_arrows_shift_value[0][2] - A_to_B_right_arrows_shift_value[0][2]],
        [A_to_B_right_arrows_shift_value[1][0] - A_to_B_right_arrows_shift_value[0][0], A_to_B_right_arrows_shift_value[1][1] - A_to_B_right_arrows_shift_value[0][1], A_to_B_right_arrows_shift_value[1][2] - A_to_B_right_arrows_shift_value[0][2]],
        [A_to_B_right_arrows_shift_value[2][0] - A_to_B_right_arrows_shift_value[0][0], A_to_B_right_arrows_shift_value[2][1] - A_to_B_right_arrows_shift_value[0][1], A_to_B_right_arrows_shift_value[2][2] - A_to_B_right_arrows_shift_value[0][2]],
        [A_to_B_right_arrows_shift_value[3][0] - A_to_B_right_arrows_shift_value[0][0], A_to_B_right_arrows_shift_value[3][1] - A_to_B_right_arrows_shift_value[0][1], A_to_B_right_arrows_shift_value[3][2] - A_to_B_right_arrows_shift_value[0][2]]
    ]

    print("A_to_B_right_arrows_shift: \(A_to_B_right_arrows_shift)")

    let y_base_rotate_affine_matrix = rotation(axis: "y", A_to_B_right_arrows_shift, affineMatrix)
    print("y_base_rotate_affine_matrix: \(y_base_rotate_affine_matrix)")
    let z_base_rotate_affine_matrix = rotation(axis: "z", A_to_B_right_arrows_shift, y_base_rotate_affine_matrix)
    print("z_base_rotate_affine_matrix: \(z_base_rotate_affine_matrix)")
    let x_base_rotate_affine_matrix = rotation(axis: "x", A_to_B_right_arrows_shift, z_base_rotate_affine_matrix)
    print("x_base_rotate_affine_matrix: \(x_base_rotate_affine_matrix)")
    return x_base_rotate_affine_matrix
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

    let eqSolveMatrix:[[Double]] = matmul(eqSolve(matmul(P.transpose4x4, P), P.transpose4x4), Q)
    var affineMatrix:[[Double]] = eqSolveMatrix.transpose4x4
    affineMatrix[3][3] = 1.0

    print("affineMatrix: \(affineMatrix)")

    affineMatrix = removeScaleAffineMatrix(affineMatrix)
    print("removeScaleAffineMatrix: \(affineMatrix)")

    affineMatrix = shiftRotateAffineMatrix(A, B, affineMatrix)
    print("shiftRotateAffineMatrix: \(affineMatrix)")

    return affineMatrix
}

let A_1 = [
    [
                0.29195672273635864,
                0.20753134787082672,
                -0.9336443543434143,
                0.3406505584716797,
            ],
            [
                0.10483368486166,
                0.9633494019508362,
                0.24691641330718994,
                1.0227067470550537,
            ],
            [
                0.950668454170227,
                -0.16996638476848602,
                0.25950002670288086,
                -0.4758530557155609,
            ],
            [0.0, 0.0, 0.0, 0.9999997019767761]
]

let A_2 = [
    [
                0.8126243948936462,
                -0.1172361671924591,
                -0.5708739757537842,
                0.25409597158432007,
            ],
            [
                -0.23279379308223724,
                -0.9633129239082336,
                -0.13354729115962982,
                1.0099575519561768,
            ],
            [
                -0.5342738628387451,
                0.2414197027683258,
                -0.8101032972335815,
                -0.4570466876029968,
            ],
            [0.0, 0.0, 0.0, 0.9999997615814209]
]

let A_3 = [
    [
                -0.03469759598374367,
                0.003780881641432643,
                -0.9993905425071716,
                0.4099700152873993,
            ],
            [
                -0.5030160546302795,
                0.8640282154083252,
                0.02073289453983307,
                1.005720853805542,
            ],
            [
                0.8635802268981934,
                0.5034287571907043,
                -0.028077878057956696,
                -0.37334659695625305,
            ],
            [0.0, 0.0, 0.0, 0.9999998211860657]
]

let B_1 = [
    [
                0.45655980706214905,
                0.7681077122688293,
                0.44895800948143005,
                -0.26391538977622986,
            ],
            [
                -0.23043100535869598,
                -0.38531294465065,
                0.8935520052909851,
                0.9078537225723267,
            ],
            [
                0.8593336939811707,
                -0.5114138126373291,
                0.0010774779366329312,
                -0.5531684756278992,
            ],
            [0.0, 0.0, 0.0, 1.0],
]

let B_2 = [
    [
                0.4490292966365814,
                0.4107557237148285,
                -0.7935065627098083,
                -0.29981839656829834,
            ],
            [
                -0.8199097514152527,
                0.5423877835273743,
                -0.18320521712303162,
                0.9066635370254517,
            ],
            [
                0.35513556003570557,
                0.7328680157661438,
                0.5803306698799133,
                -0.6528453826904297,
            ],
            [0.0, 0.0, 0.0, 1.0000001192092896],
]

let B_3 = [
    [
                0.011919788084924221,
                -0.8203105926513672,
                -0.5717933177947998,
                -0.35877254605293274,
            ],
            [
                0.4230100214481354,
                -0.5140084028244019,
                0.7462285757064819,
                0.9013289213180542,
            ],
            [
                -0.9060462713241577,
                -0.25076937675476074,
                0.34087279438972473,
                -0.5011917948722839,
            ],
            [0.0, 0.0, 0.0, 0.9999998807907104],
]

let A: [[[Double]]] = [
    A_1,
    A_2,
    A_3
]
let B: [[[Double]]] = [
    B_1,
    B_2,
    B_3
]

print("A:")
print(A)
print("B:")
print(B)

print(calcAffineMatrix(A, B))
