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
        let returnAffineMatrix = matmul(matmul(matmul(affineMatrix,theta_x_rotation), theta_y_rotation), theta_z_rotation)
        return returnAffineMatrix
    case "y":
        let returnAffineMatrix = matmul(matmul(matmul(affineMatrix,theta_x_rotation), theta_y_rotation), theta_z_rotation)
        return returnAffineMatrix
    case "z":
        let returnAffineMatrix = matmul(matmul(matmul(affineMatrix,theta_x_rotation), theta_y_rotation), theta_z_rotation)
        return returnAffineMatrix
    default:
        return []
    }
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