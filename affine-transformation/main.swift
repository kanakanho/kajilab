import Foundation
import simd

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        self.columns.3.xyz
    }
}

func simd_float4x4ToPositionMatrix(matrixs: [simd_float4x4]) -> simd_float4x4 {
    return simd_float4x4([
        simd_float4(matrixs[0].position, 1),
        simd_float4(matrixs[1].position, 1),
        simd_float4(matrixs[2].position, 1),
        simd_float4(1, 1, 1, 1)
    ])
}

func clacAffine(matrixs: [simd_float4x4], matrixDashs: [simd_float4x4]) -> simd_float4x4 {
    if (matrixs.count < 3) || (matrixDashs.count < 3) {
        print("Matrixs and MatrixDashs must be more than 3")
        return .init()
    }
    let matrix = simd_float4x4ToPositionMatrix(matrixs: matrixs)
    let matrixDash = simd_float4x4ToPositionMatrix(matrixs: matrixDashs)
    let matrixT = matrix.transpose
    return (matrixT * matrix).inverse * matrixT * matrixDash
}

let matrix1 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(0, 0, 0, 1)
])

let matrix2 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(10, 10, 5, 1)
])

let matrix3 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(0, 10, 10, 1)
])

let matrixDash1 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(1, 2, 3, 1)
])

let matrixDash2 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(4, 3, 7, 1)
])

let matrixDash3 = simd_float4x4([
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(5, 7, 10, 1)
])

// 結果を計算
print(clacAffine(matrixs: [matrix1, matrix2, matrix3], matrixDashs: [matrixDash1, matrixDash2, matrixDash3]))
