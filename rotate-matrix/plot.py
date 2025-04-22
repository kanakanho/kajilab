"""
アフィン変換行列を作成して、その変換がどのような結果になるのかを確認するためのプログラム
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
import pandas as pd
import japanize_matplotlib


def generateAffineMatrix3DSelfLU(matrix_affineA, matrix_affineAdash):
    """LU分解を用いた最小二乗法でアフィン変換行列を求める"""
    points_A = np.array([mat[:3, 3] for mat in matrix_affineA])
    points_Adash = np.array([mat[:3, 3] for mat in matrix_affineAdash])

    # 拡張行列を作成
    P = np.hstack((points_A, np.ones((points_A.shape[0], 1))))
    # print(P)
    Q = points_Adash
    # print(Q)

    # 最小二乗法で解を求める
    affine_matrix = leastSquaresMethodLU(P, Q)

    # 4x4のアフィン変換行列を構築
    affine_matrix = np.vstack((affine_matrix.T, np.array([0, 0, 0, 1])))

    return affine_matrix


def LU(A: np.array) -> np.array:
    """LU分解"""
    n = A.shape[0]
    L = np.eye(n)
    U = np.zeros((n, n))
    for i in range(n):
        for j in range(i, n):
            U[i, j] = A[i, j] - np.sum(L[i, :i] * U[:i, j])
        for j in range(i + 1, n):
            L[j, i] = (A[j, i] - np.sum(L[j, :i] * U[:i, i])) / U[i, i]
    return L, U


def eq_solve(P: np.array, Q: np.array) -> np.array:
    # LU分解
    L, U = LU(P)
    n, m = Q.shape  # Q の形状を取得
    y = np.zeros((n, m))  # 前進代入の解ベクトル y を用意

    # 前進代入
    for i in range(n):
        y[i, :] = Q[i, :] - np.dot(L[i, :i], y[:i, :])

    x = np.zeros((n, m))  # 解ベクトル x を用意

    # 後退代入
    for i in range(n - 1, -1, -1):
        if np.abs(U[i, i]) < 1e-8:  # 0除算防止
            print(f"Warning: U[{i}, {i}] is nearly zero. Adding small value.")
            U[i, i] = 1e-8
        x[i, :] = (y[i, :] - np.dot(U[i, i + 1 :], x[i + 1 :, :])) / U[i, i]

    return x


def leastSquaresMethodLU(P: np.array, Q: np.array) -> np.array:
    # 最小二乗法で解を求める
    affine_matrix = eq_solve(P.T @ P, P.T) @ Q
    return affine_matrix


host_matrix = np.array(
    [
        [
            [1.0, 0.0, 0.0, 7.0],
            [0.0, 1.0, 0.0, 7.0],
            [0.0, 0.0, 1.0, 23.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
        [
            [1.0, 0.0, 0.0, 9.0],
            [0.0, 1.0, 0.0, 7.0],
            [0.0, 0.0, 1.0, 25.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
        [
            [1.0, 0.0, 0.0, 8.0],
            [0.0, 1.0, 0.0, 8.0],
            [0.0, 0.0, 1.0, 23.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
    ]
)

client_matrix = np.array(
    [
        [
            [1.0, 0.0, 0.0, 13.0],
            [0.0, 1.0, 0.0, 15.0],
            [0.0, 0.0, 1.0, 33.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
        [
            [1.0, 0.0, 0.0, 15.0],
            [0.0, 1.0, 0.0, 15.0],
            [0.0, 0.0, 1.0, 35.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
        [
            [1.0, 0.0, 0.0, 14.0],
            [0.0, 1.0, 0.0, 16.0],
            [0.0, 0.0, 1.0, 33.0],
            [0.0, 0.0, 0.0, 1.0],
        ],
    ],
)

host_to_client_affine_matrix = generateAffineMatrix3DSelfLU(host_matrix, client_matrix)
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)
client_to_host_affine_matrix = generateAffineMatrix3DSelfLU(client_matrix, host_matrix)
print("client_to_host_affine_matrix")
print(client_to_host_affine_matrix)


# client側の右手の回転系をhost側から見た時の回転系と比較する
# client_right_position = client_right[3, :3]
client_right_position = host_matrix[0][3, :3]
# host_right_position = host_right[3, :3]
host_right_position = host_matrix[0][3, :3]

baius = 1
# 右手を囲み、回転する直方体の8つの頂点を定義する
client_right_cubes = [
    client_right_position,  # 中心
    client_right_position + np.array([baius, baius, baius]),  # 右上前
    client_right_position + np.array([-baius, baius, baius]),  # 左上前
    client_right_position + np.array([-baius, -baius, baius]),  # 左下前
    client_right_position + np.array([baius, -baius, baius]),  # 右下前
    client_right_position + np.array([baius, baius, -baius]),  # 右上後
    client_right_position + np.array([-baius, baius, -baius]),  # 左上後
    client_right_position + np.array([-baius, -baius, -baius]),  # 左下後
    client_right_position + np.array([baius, -baius, -baius]),  # 右下後
]
host_right_cubes = [
    host_right_position,  # 中心
    host_right_position + np.array([baius, baius, baius]),  # 右上前
    host_right_position + np.array([-baius, baius, baius]),  # 左上前
    host_right_position + np.array([-baius, -baius, baius]),  # 左下前
    host_right_position + np.array([baius, -baius, baius]),  # 右下前
    host_right_position + np.array([baius, baius, -baius]),  # 右上後
    host_right_position + np.array([-baius, baius, -baius]),  # 左上後
    host_right_position + np.array([-baius, -baius, -baius]),  # 左下後
    host_right_position + np.array([baius, -baius, -baius]),  # 右下後
]

print("client_right_cubes")
print(client_right_cubes)

client_world_host_hand_cubes = [
    host_to_client_affine_matrix @ np.array([*cube, 1]) for cube in client_right_cubes
]
print("client_world_host_hand_cubes")
print(client_world_host_hand_cubes)


host_world_client_hand_cubes = [
    client_to_host_affine_matrix @ np.array([*cube, 1]) for cube in client_right_cubes
]

print("host_world_client_hand_cubes")
print(host_world_client_hand_cubes)

# plot
fig = plt.figure()
ax = fig.add_subplot(111, projection="3d")
# 3Dグラフの設定
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")

# grid表示
ax.set_aspect("equal", adjustable="box")

# クライアント側の右手の立方体の描画
count = 0
for cube in client_right_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color="blue",
        label="Client Right Hand",
        alpha=count / 9,
    )

# ホスト側の右手の立方体の描画
count = 0
for cube in client_world_host_hand_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color="red",
        label="Host Right Hand",
        alpha=count / 9,
    )

# 軸の範囲を設定
x_max = max(
    max(client_right_cubes, key=lambda x: x[0])[0],
    max(client_world_host_hand_cubes, key=lambda x: x[0])[0],
)
x_min = min(
    min(client_right_cubes, key=lambda x: x[0])[0],
    min(client_world_host_hand_cubes, key=lambda x: x[0])[0],
)
y_max = max(
    max(client_right_cubes, key=lambda x: x[1])[1],
    max(client_world_host_hand_cubes, key=lambda x: x[1])[1],
)
y_min = min(
    min(client_right_cubes, key=lambda x: x[1])[1],
    min(client_world_host_hand_cubes, key=lambda x: x[1])[1],
)
z_max = max(
    max(client_right_cubes, key=lambda x: x[2])[2],
    max(client_world_host_hand_cubes, key=lambda x: x[2])[2],
)
z_min = min(
    min(client_right_cubes, key=lambda x: x[2])[2],
    min(client_world_host_hand_cubes, key=lambda x: x[2])[2],
)
max_range = (
    max(
        x_max - x_min,
        y_max - y_min,
        z_max - z_min,
    )
    / 2.0
)
mean_x = (x_max + x_min) / 2.0
mean_y = (y_max + y_min) / 2.0
mean_z = (z_max + z_min) / 2.0
ax.set_xlim(mean_x - max_range, mean_x + max_range)
ax.set_ylim(mean_y - max_range, mean_y + max_range)
ax.set_zlim(mean_z - max_range, mean_z + max_range)

plt.show()


# plot
fig = plt.figure()
ax = fig.add_subplot(111, projection="3d")

# 3Dグラフの設定
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")

ax.set_aspect("equal", adjustable="box")

# ホスト側の右手の立方体の描画
count = 0
for cube in host_right_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color="red",
        label="Client Right Hand",
        alpha=count / 9,
    )
# クライアント側の右手の立方体の描画
count = 0
for cube in host_world_client_hand_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color="blue",
        label="Host Right Hand",
        alpha=count / 9,
    )

# 軸の範囲を設定
x_max = max(
    max(host_right_cubes, key=lambda x: x[0])[0],
    max(host_world_client_hand_cubes, key=lambda x: x[0])[0],
)
x_min = min(
    min(host_right_cubes, key=lambda x: x[0])[0],
    min(host_world_client_hand_cubes, key=lambda x: x[0])[0],
)
y_max = max(
    max(host_right_cubes, key=lambda x: x[1])[1],
    max(host_world_client_hand_cubes, key=lambda x: x[1])[1],
)
y_min = min(
    min(host_right_cubes, key=lambda x: x[1])[1],
    min(host_world_client_hand_cubes, key=lambda x: x[1])[1],
)
z_max = max(
    max(host_right_cubes, key=lambda x: x[2])[2],
    max(host_world_client_hand_cubes, key=lambda x: x[2])[2],
)
z_min = min(
    min(host_right_cubes, key=lambda x: x[2])[2],
    min(host_world_client_hand_cubes, key=lambda x: x[2])[2],
)
max_range = (
    max(
        x_max - x_min,
        y_max - y_min,
        z_max - z_min,
    )
    / 2.0
)
mean_x = (x_max + x_min) / 2.0
mean_y = (y_max + y_min) / 2.0
mean_z = (z_max + z_min) / 2.0
ax.set_xlim(mean_x - max_range, mean_x + max_range)
ax.set_ylim(mean_y - max_range, mean_y + max_range)
ax.set_zlim(mean_z - max_range, mean_z + max_range)

plt.show()
