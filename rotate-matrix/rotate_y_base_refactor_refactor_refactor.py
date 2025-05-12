"""
前提条件
- y軸の向きは端末によって、変わらない
操作
1. クライアントとホスト側でy軸を揃える
2. x軸を揃える
3. z軸の正負を確認し、逆向きの場合は反転させる
"""

from pprint import pprint

import numpy as np
import math
from scipy.linalg import polar
from scipy.linalg import svd
from scipy.spatial.transform import Rotation as R
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
import pandas as pd
import japanize_matplotlib
import sample_data_reverse

colors = [
    "orange",
    "black",
    "red",
    "green",
    "blue",
    "purple",
    "pink",
    "brown",
    "gray",
]


def plots(
    client_right_arrows,
    client_world_host_hand_arrows,
    is_ani=False,
    suffix="",
):
    shift_value = client_world_host_hand_arrows[0][:3] - client_right_arrows[0]
    client_right_arrows_shift = [arrow - shift_value for arrow in client_right_arrows]
    client_world_host_hand_arrows_shift = [
        arrow[:3] - shift_value for arrow in client_world_host_hand_arrows
    ]

    client_right_arrows_shift = [
        arrow - client_right_arrows_shift[0] for arrow in client_right_arrows_shift
    ]
    client_world_host_hand_arrows_shift = [
        arrow - client_world_host_hand_arrows_shift[0]
        for arrow in client_world_host_hand_arrows_shift
    ]

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
    for arrow in client_right_arrows_shift:
        count += 1
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Client Right Hand",
            # alpha=count / 9,
            marker="o",
        )

    # client_right_arrows_shift[0] からそれ以外の点までの辺をプロット
    for i in range(1, len(client_right_arrows_shift)):
        ax.plot(
            [client_right_arrows_shift[0][0], client_right_arrows_shift[i][0]],
            [client_right_arrows_shift[0][1], client_right_arrows_shift[i][1]],
            [client_right_arrows_shift[0][2], client_right_arrows_shift[i][2]],
            color="pink",
            alpha=0.5,
        )

    # ホスト側の右手の立方体の描画
    count = 0
    for arrow in client_world_host_hand_arrows_shift:
        count += 1
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Host Right Hand",
            # alpha=count / 9,
            marker="o",
        )

    # client_world_host_hand_arrows_shift[0] からそれ以外の点までの辺をプロット
    for i in range(1, len(client_world_host_hand_arrows_shift)):
        ax.plot(
            [
                client_world_host_hand_arrows_shift[0][0],
                client_world_host_hand_arrows_shift[i][0],
            ],
            [
                client_world_host_hand_arrows_shift[0][1],
                client_world_host_hand_arrows_shift[i][1],
            ],
            [
                client_world_host_hand_arrows_shift[0][2],
                client_world_host_hand_arrows_shift[i][2],
            ],
            color="lightblue",
            alpha=0.5,
        )

    # 軸の範囲を設定
    x_max = max(
        max(client_right_arrows_shift, key=lambda x: x[0])[0],
        max(client_world_host_hand_arrows_shift, key=lambda x: x[0])[0],
    )
    x_min = min(
        min(client_right_arrows_shift, key=lambda x: x[0])[0],
        min(client_world_host_hand_arrows_shift, key=lambda x: x[0])[0],
    )
    y_max = max(
        max(client_right_arrows_shift, key=lambda x: x[1])[1],
        max(client_world_host_hand_arrows_shift, key=lambda x: x[1])[1],
    )
    y_min = min(
        min(client_right_arrows_shift, key=lambda x: x[1])[1],
        min(client_world_host_hand_arrows_shift, key=lambda x: x[1])[1],
    )
    z_max = max(
        max(client_right_arrows_shift, key=lambda x: x[2])[2],
        max(client_world_host_hand_arrows_shift, key=lambda x: x[2])[2],
    )
    z_min = min(
        min(client_right_arrows_shift, key=lambda x: x[2])[2],
        min(client_world_host_hand_arrows_shift, key=lambda x: x[2])[2],
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

    if is_ani:
        # 5度ずつ回転させるアニメーション
        ani = FuncAnimation(
            fig,
            lambda x: ax.view_init(elev=10, azim=x),
            frames=np.arange(0, 360, 5),
            interval=100,
        )
        ani.save(f"client_world_rotate_y_base_{suffix}.gif", writer="pillow")

    # plt.show()


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


def decompose_affine_matrix(matrix: np.ndarray):
    """
    アフィン変換行列からスケーリング成分と回転行列を分離して抽出する。

    Parameters:
        matrix (np.ndarray): 4x4 アフィン変換行列

    Returns:
        scale: np.ndarray - x, y, z のスケーリング成分
        rotation: np.ndarray - 3x3 の回転行列
    """
    if matrix.shape != (4, 4):
        raise ValueError("Input matrix must be a 4x4 numpy array.")

    # 3x3 部分行列（回転 + スケーリング）
    M = matrix[:3, :3]

    # 極分解（M = R × S）
    R, S = polar(M)

    a = np.asarray(M)
    if a.ndim != 2:
        raise ValueError("`a` must be a 2-D array.")

    w, s, vh = svd(a, full_matrices=False)
    print("w")
    print(w)
    print("s")
    print(s)
    print("vh")
    print(vh)
    R = w.dot(vh)
    print("R")
    print(w @ vh)
    # S = (vh.T.conj() * s).dot(vh)
    print("R")
    print(R)

    # スケーリング成分は S の対角要素の平方根（または M 各軸ベクトルのノルムでもOK）
    scale_x = np.linalg.norm(M[:, 0])
    scale_y = np.linalg.norm(M[:, 1])
    scale_z = np.linalg.norm(M[:, 2])
    scale = np.array([scale_x, scale_y, scale_z])
    print("scale")
    print(scale)

    return scale, R


def rotation(axis, world_hand_arrows_shift, affine_matrix) -> np.ndarray:
    arrows_shift = []
    if axis == "x":
        arrows_shift = world_hand_arrows_shift[1]
    elif axis == "y":
        arrows_shift = world_hand_arrows_shift[2]
    elif axis == "z":
        arrows_shift = world_hand_arrows_shift[3]

    print("arrows_shift")
    print(arrows_shift)

    theta_x = math.asin(arrows_shift[0])
    theta_x_rotation_matrix = np.array(
        [
            [1, 0, 0, 0],
            [0, math.cos(theta_x), -math.sin(theta_x), 0],
            [0, math.sin(theta_x), math.cos(theta_x), 0],
            [0, 0, 0, 1],
        ]
    )
    print("theta_x")
    print(theta_x)
    theta_y = math.asin(arrows_shift[1])
    theta_y_rotation_matrix = np.array(
        [
            [math.cos(theta_y), 0, math.sin(theta_y), 0],
            [0, 1, 0, 0],
            [-math.sin(theta_y), 0, math.cos(theta_y), 0],
            [0, 0, 0, 1],
        ]
    )
    print("theta_y")
    print(theta_y)
    theta_z = math.asin(arrows_shift[2])
    theta_z_rotation_matrix = np.array(
        [
            [math.cos(theta_z), -math.sin(theta_z), 0, 0],
            [math.sin(theta_z), math.cos(theta_z), 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1],
        ]
    )
    print("theta_z")
    print(theta_z)

    # print("theta_x")
    # print(theta_x * 180 / math.pi)
    # print("theta_y")
    # print(theta_y * 180 / math.pi)
    # print("theta_z")
    # print(theta_z * 180 / math.pi)
    # print("theta_x_rotation_matrix")
    # print(theta_x_rotation_matrix)

    # アフィン行列を更新
    if axis == "y":
        affine_matrix = affine_matrix @ theta_z_rotation_matrix
        affine_matrix = affine_matrix @ theta_y_rotation_matrix
        affine_matrix = affine_matrix @ theta_x_rotation_matrix
    elif axis == "x":
        # affine_matrix = affine_matrix @ theta_z_rotation_matrix
        # affine_matrix = affine_matrix @ theta_y_rotation_matrix
        affine_matrix = affine_matrix @ theta_x_rotation_matrix
    elif axis == "z":
        # affine_matrix = affine_matrix @ theta_z_rotation_matrix
        affine_matrix = affine_matrix @ theta_y_rotation_matrix
        # affine_matrix = affine_matrix @ theta_x_rotation_matrix

    return affine_matrix


# --------------------------------------------------------------------


"""
初期のアフィン行列の生成
"""

host_to_client_affine_matrix = generateAffineMatrix3DSelfLU(
    sample_data_reverse.host_matrix, sample_data_reverse.client_matrix
)
print("初期のアフィン行列の生成")
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


# --------------------------------------------------------------------


"""
スケーリング成分の除去
"""

_, host_to_client_affine_matrix_rotation = decompose_affine_matrix(
    host_to_client_affine_matrix
)
host_to_client_affine_matrix[:3, :3] = host_to_client_affine_matrix_rotation

print("スケーリング成分の除去")
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


# --------------------------------------------------------------------


"""
補正のための座標の定義
"""

client_right_position = sample_data_reverse.client_matrix[0][:3, 3]
print("client_right_position")
print(client_right_position)

baius = 1

client_right_arrows = [
    client_right_position,  # 中心
    client_right_position + np.array([baius, 0, 0]),
    client_right_position + np.array([0, baius, 0]),
    client_right_position + np.array([0, 0, baius]),
]

print("client_right_arrows")
print(client_right_arrows)

client_world_host_hand_arrows = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows
]

print("client_world_host_hand_arrows")
print(client_world_host_hand_arrows)


# --------------------------------------------------------------------


"""
arrow の座標をシフトさせる
"""

# shift_value = client_world_host_hand_arrows[0][:3] - client_right_arrows[0]
shift_value = client_world_host_hand_arrows[0][:3] - client_right_arrows[0]

print("shift_value")
print(shift_value)

client_right_arrows_shift = [arrow - shift_value for arrow in client_right_arrows]
# client_right_arrows_shift = arrow / client_right_arrows
client_world_host_hand_arrows_shift = [
    arrow[:3] - shift_value for arrow in client_world_host_hand_arrows
]

print("client_world_host_hand_arrows_shift1")
print(client_world_host_hand_arrows_shift)

client_right_arrows_shift = [
    arrow - client_right_arrows_shift[0] for arrow in client_right_arrows_shift
]
client_world_host_hand_arrows_shift = [
    arrow - client_world_host_hand_arrows_shift[0]
    for arrow in client_world_host_hand_arrows_shift
]

print("client_right_arrows_shift")
print(client_right_arrows_shift)
print("client_world_host_hand_arrows_shift2")
print(client_world_host_hand_arrows_shift)


# --------------------------------------------------------------------


"""
変換のための処理
"""

# # y軸を揃えるための回転させる
# host_to_client_affine_matrix = rotation(
#     "y", client_world_host_hand_arrows_shift, host_to_client_affine_matrix
# )


print("host_to_client_affine_matrix_y")
print(host_to_client_affine_matrix)


print("回転成分を調整")
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


client_world_host_hand_arrows = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows
]

print("client_world_host_hand_arrows")
print(client_world_host_hand_arrows)


"""
描画のための処理
"""

# # 基準地点をシフトさせた純粋な軸の表示
# # plot
# plots(
#     client_right_arrows,
#     client_world_host_hand_arrows,
#     is_ani=True,
#     suffix="shift_y",
# )

# plt.plot()

# --------------------------------------------------------------------


"""
変換のための処理
"""

# # y軸を揃えるための回転させる
# host_to_client_affine_matrix = rotation(
#     "x", client_world_host_hand_arrows_shift, host_to_client_affine_matrix
# )


print("host_to_client_affine_matrix_x")
print(host_to_client_affine_matrix)


print("回転成分を調整")
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


client_world_host_hand_arrows = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows
]

print("client_world_host_hand_arrows")
print(client_world_host_hand_arrows)


"""
描画のための処理
"""

# # 基準地点をシフトさせた純粋な軸の表示
# # plot
# plots(
#     client_right_arrows,
#     client_world_host_hand_arrows,
#     is_ani=True,
#     suffix="shift_y",
# )

# plt.plot()


# # --------------------------------------------------------------------

# 計算に使用した全ての点を変換した上でプロット

client_hands_positions = [
    sample_data_reverse.client_matrix[i][:3, 3] for i in range(len(sample_data_reverse.client_matrix))
]
host_hands_positions = [
    sample_data_reverse.host_matrix[i][:3, 3] for i in range(len(sample_data_reverse.host_matrix))
]
print("client_hands_positions")
for hand in client_hands_positions:
    print(hand)

baius = 1
baiuses = [
    np.array([0, 0, 0]),
    np.array([baius, 0, 0]),
    np.array([0, baius, 0]),
    np.array([0, 0, baius]),
]
client_hands_arrows = [
    [client_hands_positions[i] + baius for baius in baiuses]
    for i in range(len(client_hands_positions))
]

host_hands_arrows = [
    [host_hands_positions[i] + baius for baius in baiuses]
    for i in range(len(host_hands_positions))
]

client_world_host_hands_arrows = [
    [host_to_client_affine_matrix @ np.array([*arrow, 1]) for arrow in hand]
    for hand in host_hands_arrows
]

print("client_hands_arrows")
pprint(client_hands_arrows)
# for hand in client_hands_arrows:
#     print("hand")
#     for arrow in hand:
#         print(arrow)
print("client_world_host_hands_arrows")
pprint(client_world_host_hands_arrows)
# for hand in client_world_host_hands_arrows:
#     print("hand")
#     for arrow in hand:
#         print(arrow)


# plot
fig = plt.figure()
ax = fig.add_subplot(111, projection="3d")
# 3Dグラフの設定
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")
# grid表示
ax.set_aspect("equal", adjustable="box")

colors = [
    "black",
    "red",
    "green",
    "blue",
]

# クライアント側の右手の立方体の描画
count = 0
for hand in client_hands_arrows:
    print("hand")
    print(hand)
    for arrow in hand:
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Client Right Hand",
            marker=".",
        )
        count += 1
    # break


# client_right_arrows_shift[0] からそれ以外の点までの辺をプロット
for i in range(0, len(client_hands_arrows)):
    if i == 0:
        continue
    for j in range(0, len(client_hands_arrows[i])):
        ax.plot(
            [client_hands_arrows[i][0][0], client_hands_arrows[i][j][0]],
            [client_hands_arrows[i][0][1], client_hands_arrows[i][j][1]],
            [client_hands_arrows[i][0][2], client_hands_arrows[i][j][2]],
            color="pink",
            alpha=1,
        )
    # break
# ホスト側の右手の立方体の描画
count = 0
for hand in client_world_host_hands_arrows:
    for arrow in hand:
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Host Right Hand",
            # alpha=count / 9,
            marker=".",
        )
        count += 1
    # break

# client_world_host_hand_arrows_shift[0] からそれ以外の点までの辺をプロット
for i in range(0, len(client_world_host_hands_arrows)):
    if i == 0:
        continue
    for j in range(0, len(client_world_host_hands_arrows[i])):
        ax.plot(
            [
                client_world_host_hands_arrows[i][0][0],
                client_world_host_hands_arrows[i][j][0],
            ],
            [
                client_world_host_hands_arrows[i][0][1],
                client_world_host_hands_arrows[i][j][1],
            ],
            [
                client_world_host_hands_arrows[i][0][2],
                client_world_host_hands_arrows[i][j][2],
            ],
            color="lightblue",
            alpha=1,
        )
    # break

# 5度ずつ回転させるアニメーション
ani = FuncAnimation(
    fig,
    lambda x: ax.view_init(elev=10, azim=x),
    frames=np.arange(0, 360, 5),
    interval=100,
)

ani.save("client_world_rotate_y_base_reverse_no_shift.gif", writer="pillow")

plt.show()
