let affine =
    [
        [
            0.8577224767900956,
            0.24158329989589972,
            0.4538167714182363,
            1.4552181874656285e-08,
        ],
        [
            -0.09354161160825158,
            0.9413171935921485,
            -0.32430218615595646,
            1.0223272097819658e-08,
        ],
        [
            -0.505531521971474,
            0.23571052216481425,
            0.8299870059428615,
            4.1242520584012065e-09,
        ],
        [0.0, 0.0, 0.0, 1.0],
    ]


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

print("Affine Matrix:")
for row in affine {
    print(row)
}
let inverseAffine = inverseMatrix(affine)
print("\nInverse Affine Matrix:")
for row in inverseAffine {
    print(row)
}