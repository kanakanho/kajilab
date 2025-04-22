//
//  CalculateTransformationMatrix.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/02/07.
//

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

func svd(_ A: [[Double]]) -> ([[Double]],[Double],[[Double]]) {
    var flatA = A.flatMap { $0 }
    var m = __CLPK_integer(A.count)
    var n = __CLPK_integer(A[0].count)
    var lda = m
    var s = [Double](repeating: 0.0, count: Int(min(m, n)))
    var u = [Double](repeating: 0.0, count: Int(m * m))
    var vt = [Double](repeating: 0.0, count: Int(n * n))
    var superb = [Double](repeating: 0.0, count: Int(min(m, n) - 1))
    var info: __CLPK_integer = 0

    var jobu: Int8 = 65 // 'A'
    var jobvt: Int8 = 65 // 'A'

    dgesvd_(&jobu, &jobvt, &m, &n, &flatA, &lda, &s, &u, &m, &vt, &n, &superb, &info)

    let Umat = (0..<Int(m)).map { i in (0..<Int(m)).map { j in u[i * Int(m) + j] } }
    let VTmat = (0..<Int(n)).map { i in (0..<Int(n)).map { j in vt[i * Int(n) + j] } }

    return (Umat, s, VTmat)
}

func determinant3x3(matrix: [[Double]]) -> Double {
    let a = matrix[0][0], b = matrix[0][1], c = matrix[0][2]
    let d = matrix[1][0], e = matrix[1][1], f = matrix[1][2]
    let g = matrix[2][0], h = matrix[2][1], i = matrix[2][2]
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
}

func estimateRUsingSVD(A: [[Double]], APrime: [[Double]]) -> [[Double]] {
    precondition(A[0].count == 3 && APrime[0].count == 3, "Both matrices must have 3 columns")

    // A^T @ A'
    let AT = A.transpose4x4
    let N = matmul(AT, APrime)

    // Perform SVD on N
    let (U, S, Vt) = svd(N)
    let V = Vt.transpose4x4

    // Compute determinant
    let det = determinant3x3(matrix: matmul(V, U.transpose4x4))

    // Create diagonal matrix D
    let D = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, det]
    ]

    return matmul(matmul(V, D), U.transpose4x4)
}

func shiftRotateAffineMatrix(_ matrix: [[Double]]) -> [[Double]] {
    // 3x3 部分行列 (回転 + スケーリング)
    let M = simd_double3x3(matrix.tosimd_double4x4())

    // 列ベクトルを正規化して回転行列を得る
    let rotation = simd_float3x3(
        normalize(M.columns.0),
        normalize(M.columns.1),
        normalize(M.columns.2)
    )

    var tmpMatrix = matrix

    // スケーリングを除去
    for i in 0..<3 {
        for j in 0..<3 {
            tmpMatrix[i][j] = rotation[i][j]
        }
    }

    return tmpMatrix
}

struct ArrowPoint {
    var origin: SIMD3<Double>
    var x: SIMD3<Double>
    var y: SIMD3<Double>
    var z: SIMD3<Double>

    var list: [[Double]] {
        return [
            [origin.x, origin.y, origin.z],
            [x.x, x.y, x.z],
            [y.x, y.y, y.z],
            [z.x, z.y, z.z]
        ]
    }
}

func changeRotateAffineMatrix(_ matrix: [[Double]]) -> [[Double]] {
    // // let quat = simd_quatd(matrix.tosimd_double4x4())
    // let euler = SIMD3<Double>(Double.pi, Double.pi, Double.pi)
    // let rotation = simd_double3x3(diagonal: euler)
    // let rotationMatrix = rotation.toDoubleList()
    // var tmpMatrix = matrix
    // for i in 0..<3 {
    //     for j in 0..<3 {
    //         tmpMatrix[i][j] = rotationMatrix[i][j]
    //     }
    // }
    // return tmpMatrix

    let quaternion = simd_quatd(matrix.tosimd_double4x4())
    let euler = quaternion
    print(euler)
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

    affineMatrix = shiftRotateAffineMatrix(affineMatrix)

    affineMatrix = changeRotateAffineMatrix(affineMatrix)
    
    return affineMatrix
}


let A: [[[Double]]] = [
    [
        [0.3725767433643341, -0.26258817315101624, -0.890075147151947, 0.1274329274892807],
        [0.030086353421211243, 0.9620451331138611, -0.2712266743183136, 1.0478260517120361],
        [0.9275131821632385, 0.07427370548248291, 0.36633607745170593, -0.3857370615005493],
        [0.0, 0.0, 0.0, 0.9999998211860657]
    ], 
    [
        [0.784506618976593, -0.01472133956849575, -0.6199458241462708, 0.12870480120182037],
        [-0.2429184466600418, -0.9271172285079956, -0.28538426756858826, 0.9940497875213623],
        [-0.5705612301826477, 0.374482125043869, -0.7309058308601379, -0.4583953320980072],
        [0.0, 0.0, 0.0, 0.9999998807907104]
    ], 
    [
        [0.3725767433643341, -0.26258817315101624, -0.890075147151947, 0.1274329274892807],
        [0.030086353421211243, 0.9620451331138611, -0.2712266743183136, 1.0478260517120361],
        [0.9275131821632385, 0.07427370548248291, 0.36633607745170593, -0.3857370615005493],
        [0.0, 0.0, 0.0, 0.9999998211860657]
    ]
]
let B: [[[Double]]] = [
    [
        [0.755118727684021, 0.6171859502792358, 0.22108149528503418, -0.4415866732597351],
        [-0.4022881090641022, 0.16994896531105042, 0.899600625038147, 0.9640570878982544],
        [0.517648458480835, -0.7682437896728516, 0.37661826610565186, -0.4113050699234009],
        [0.0, 0.0, 0.0, 0.9999997615814209]
    ],
    [
        [-0.001725687412545085, -0.9643319845199585, -0.26469072699546814, -0.3835128843784332],
        [0.4989171326160431, -0.23022451996803284, 0.8355110883712769, 0.9332133531570435],
        [-0.8666480779647827, -0.13061681389808655, 0.48151904344558716, -0.29075688123703003],
        [0.0, 0.0, 0.0, 1.0000001192092896]
    ],
    [
        [0.755118727684021, 0.6171859502792358, 0.22108149528503418, -0.4415866732597351],
        [-0.4022881090641022, 0.16994896531105042, 0.899600625038147, 0.9640570878982544],
        [0.517648458480835, -0.7682437896728516, 0.37661826610565186, -0.4113050699234009],
        [0.0, 0.0, 0.0, 0.9999997615814209]
    ]
]

print(calcAffineMatrix(A, B))
