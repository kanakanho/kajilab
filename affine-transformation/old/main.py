import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# 元の3D座標
matrixA = np.array([[0, 0, 0], [10, 10, 0], [0, 10, 10]])

# 対応する変換後の3D座標
matrixAdash = np.array([[1, 2, 3], [4, 3, 7], [5, 7, 10]])

# 子の座標系への変換を表すアフィン変換行列
more_affine = np.array([[1, 0, 0, 4], [0, 1, 0, 4], [0, 0, 1, 4], [0, 0, 0, 1]])


def generateAffineMatrix3D(matrix, matrix_dash) -> np.array:
    # 元の点 (matrix) と変換後の点 (matrix_dash) のサイズを確認
    assert matrix.shape[0] == 3 and matrix_dash.shape[0] == 3, "3つの点が必要です"

    # 元の点を拡張して 4x3 行列を作成 (x, y, z, 1)
    ones = np.ones((matrix.shape[0], 1))
    print(ones)
    matrix_ext = np.hstack((matrix, ones))  # 3x4 の行列
    print(matrix_ext)

    # 対応する変換後の点 (x', y', z', 1)
    matrix_dash_ext = np.hstack((matrix_dash, ones))  # 3x4 の行列
    print(matrix_dash_ext)

    # 最小二乗法でアフィン変換行列を計算
    affine_matrix, _, _, _ = np.linalg.lstsq(matrix_ext, matrix_dash_ext, rcond=None)

    # 結果を返す (4x4 のアフィン変換行列)
    return affine_matrix.T


affine = generateAffineMatrix3D(matrixA, matrixAdash)
print("3Dアフィン変換行列:")
print(affine)

# 3Dプロット
fig = plt.figure()
ax = fig.add_subplot(111, projection="3d")

# 元の3D座標をプロット
# 点から面にする
ax.scatter(matrixA[:, 0], matrixA[:, 1], matrixA[:, 2], label="Original", s=2 * 20)
ax.scatter(
    matrixAdash[:, 0],
    matrixAdash[:, 1],
    matrixAdash[:, 2],
    label="Transformed",
    s=1.5 * 20,
)
# 面てきなものを作る
# ax.plot_trisurf(
#     matrixA[:, 0], matrixA[:, 1], matrixA[:, 2], label="Original", alpha=0.5
# )

# アフィン変換行列を使って変換前の点を変換
matrixA_transformed = affine @ np.vstack((matrixA.T, np.ones(matrixA.shape[0])))

# 変換後の点をプロット
# ax.scatter(
#     matrixA_transformed[0],
#     matrixA_transformed[1],
#     matrixA_transformed[2],
#     label="Transformed by affine matrix",
#     s= 1.0 * 20,
# )
# ax.plot_trisurf(
#     matrixA_transformed[0],
#     matrixA_transformed[1],
#     matrixA_transformed[2],
#     label="Transformed by affine matrix",
#     alpha=0.5
# )

# matrixA で野良の点をプロット
more_affine_transformed = affine @ more_affine

# 変換後の点をプロット
# ax.scatter(
#     more_affine_transformed[0],
#     more_affine_transformed[1],
#     more_affine_transformed[2],
#     label="Transformed by affine matrix",
#     s= 2.0 * 20,
# )
ax.plot_trisurf(
    more_affine_transformed[0],
    more_affine_transformed[1],
    more_affine_transformed[2],
    label="Transformed by affine matrix",
    alpha=0.5
)

# 野良の点を A dash の座標系に変換
more_affine_transformed =  more_affine_transformed @ affine

# 変換後の点をプロット
# ax.scatter(
#     more_affine_transformed[0],
#     more_affine_transformed[1],
#     more_affine_transformed[2],
#     label="Transformed by affine matrix",
#     s= 1.0 * 20,
# )
ax.plot_trisurf(
    more_affine_transformed[0],
    more_affine_transformed[1],
    more_affine_transformed[2],
    label="Transformed by affine matrix",
    alpha=0.5
)

# 軸ラベル
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")

# 凡例
ax.legend()

plt.show()
