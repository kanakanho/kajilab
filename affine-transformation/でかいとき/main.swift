import Accelerate
import simd

//
//  Extension.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2024/12/27.
//

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
    
    init(codable: [[Float]]) {
        self.init([
            SIMD4<Float>(codable[0][0], codable[0][1], codable[0][2], codable[0][3]),
            SIMD4<Float>(codable[1][0], codable[1][1], codable[1][2], codable[1][3]),
            SIMD4<Float>(codable[2][0], codable[2][1], codable[2][2], codable[2][3]),
            SIMD4<Float>(codable[3][0], codable[3][1], codable[3][2], codable[3][3])
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
    
    var codable: [[Float]] {
        return [
            [self.columns.0.x, self.columns.0.y, self.columns.0.z, self.columns.0.w],
            [self.columns.1.x, self.columns.1.y, self.columns.1.z, self.columns.1.w],
            [self.columns.2.x, self.columns.2.y, self.columns.2.z, self.columns.2.w],
            [self.columns.3.x, self.columns.3.y, self.columns.3.z, self.columns.3.w]
        ]
    }
    
    func toDoubleList() -> [[Double]] {
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



//
//  CalculateTransformationMatrix.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/02/07.
//

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
    let n = A.count  // A, B のデータセットの個数

    var P: [[Double]] = []
    for i in 0..<n {
        var rowP: [Double] = []
        for j in 0..<3 {
            rowP.append(A[i][j][3])
        }
        rowP.append(1.0)
        P.append(rowP)
    }
    if P.count == 3 {
        P.append([0, 0, 0, 0])
    }
    
    var Q: [[Double]] = []
    for i in 0..<n {
        var rowQ: [Double] = []
        for j in 0..<3 {
            rowQ.append(B[i][j][3])
        }
        rowQ.append(1.0)
        Q.append(rowQ)
    }
    if Q.count == 3 {
        Q.append([0, 0, 0, 0])
    }

    // 最小二乗法の計算
    let eqSolveMatrix: [[Double]] = matrixMul4x4(eqSolve(matrixMul4x4(P.transpose4x4, P), P.transpose4x4), Q)
    
    var affineMatrix: [[Double]] = eqSolveMatrix.transpose4x4
    affineMatrix[3][3] = 1.0  // 最後の要素を 1 にする

    return affineMatrix
}

// let A:[[[Double]]] = [
//       [[1, 0, 0, 7],[0, 1, 0, 9],[0, 0, 1, 8],[0, 0, 0, 1]],
//       [[1, 0, 0, 7],[0, 1, 0, 7],[0, 0, 1, 8],[0, 0, 0, 1]],
//       [[1, 0, 0, 23],[0, 1, 0, 25],[0, 0, 1, 23],[0, 0, 0, 1]],
//   ]

// let B:[[[Double]]] = [
//       [[1, 0, 0, 13],[0, 1, 0, 15],[0, 0, 1, 14],[0, 0, 0, 1]],
//       [[1, 0, 0, 15],[0, 1, 0, 15],[0, 0, 1, 16],[0, 0, 0, 1]],
//       [[1, 0, 0, 33],[0, 1, 0, 35],[0, 0, 1, 33],[0, 0, 0, 1]],
//   ]

let A:[[[Double]]] = [
    [
        [
            -0.07545638084411621,
            0.39005914330482483,
            -0.9176926612854004,
            0.05287403613328934,
        ],
        [
            -0.8903007507324219,
            0.3881213665008545,
            0.23817254602909088,
            0.8751094937324524,
        ],
        [
            0.44907766580581665,
            0.8349941372871399,
            0.3179836869239807,
            -0.45815807580947876,
        ],
        [0.0, 0.0, 0.0, 1.0],
    ],
    [
        [
            -0.08045242726802826,
            0.3675697147846222,
            -0.9265097975730896,
            0.05901721864938736,
        ],
        [
            -0.8620753884315491,
            0.4409431219100952,
            0.2497905045747757,
            0.8726698160171509,
        ],
        [
            0.5003533959388733,
            0.8188175559043884,
            0.28139781951904297,
            -0.46183133125305176,
        ],
        [0.0, 0.0, 0.0, 1.0000001192092896],
    ],
    [
        [
            -0.47466233372688293,
            0.5110324025154114,
            -0.7166183590888977,
            0.31743118166923523,
        ],
        [
            -0.6490819454193115,
            0.3466627299785614,
            0.677139401435852,
            0.7114048004150391,
        ],
        [
            0.5944650769233704,
            0.7865564227104187,
            0.1671542227268219,
            -0.4768063426017761,
        ],
        [0.0, 0.0, 0.0, 0.9999997019767761],
    ],
    [
        [
            -0.4786551296710968,
            0.5089558959007263,
            -0.7154390215873718,
            0.2991752326488495,
        ],
        [-0.657845675945282, 0.3317706286907196, 0.676141083240509, 0.7244756817817688],
        [
            0.5814880132675171,
            0.7942871451377869,
            0.17601066827774048,
            -0.457441508769989,
        ],
        [0.0, 0.0, 0.0, 0.9999998807907104],
    ],

  ]

let B:[[[Double]]] = [
    [
        [
            0.017645414918661118,
            0.5151004791259766,
            -0.85694819688797,
            -0.03971794992685318,
        ],
        [
            -0.8064712285995483,
            0.5139551758766174,
            0.2923256456851959,
            1.1013673543930054,
        ],
        [
            0.5910100936889648,
            0.6859457492828369,
            0.42448264360427856,
            -0.5777835845947266,
        ],
        [0.0, 0.0, 0.0, 0.9999997019767761],
    ],
    [
        [
            0.03965822979807854,
            0.48614779114723206,
            -0.8729759454727173,
            -0.045029688626527786,
        ],
        [
            -0.8076704144477844,
            0.5299756526947021,
            0.2584444284439087,
            1.099175214767456,
        ],
        [
            0.5882984399795532,
            0.6948277354240417,
            0.4136653244495392,
            -0.5745953321456909,
        ],
        [0.0, 0.0, 0.0, 0.9999997019767761],
    ],
    [
        [
            0.5587247610092163,
            0.5876954197883606,
            -0.5851842761039734,
            -0.271121621131897,
        ],
        [
            -0.7937838435173035,
            0.5833656787872314,
            -0.1720229983329773,
            0.9474490880966187,
        ],
        [
            0.240279421210289,
            0.5606232285499573,
            0.7924439907073975,
            -0.4751623570919037,
        ],
        [0.0, 0.0, 0.0, 1.0000001192092896],
    ],
    [
        [
            0.5518196225166321,
            0.5860751271247864,
            -0.5933053493499756,
            -0.26687049865722656,
        ],
        [
            -0.7907507419586182,
            0.5937387943267822,
            -0.14895568788051605,
            0.9512237906455994,
        ],
        [
            0.26496919989585876,
            0.5513532161712646,
            0.7910758852958679,
            -0.4752828776836395,
        ],
        [0.0, 0.0, 0.0, 0.9999998807907104],
    ],
  ]

print(calcAffineMatrix(A, B))

