"""
アフィン変換行列を作成して、その行列からスケリーング成分を除去し、その変換がどのような結果になるのかを確認するためのプログラム
"""

import numpy as np
from scipy.linalg import polar
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
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

    # スケーリング成分は S の対角要素の平方根（または M 各軸ベクトルのノルムでもOK）
    scale_x = np.linalg.norm(M[:, 0])
    scale_y = np.linalg.norm(M[:, 1])
    scale_z = np.linalg.norm(M[:, 2])
    scale = np.array([scale_x, scale_y, scale_z])

    return scale, R


client_right = np.array(
    [
        [0.6260809, -0.7287946, 0.27727395, 0.0],
        [0.5277127, 0.65780145, 0.53741616, 0.0],
        [-0.5740574, -0.19014505, 0.79643136, 0.0],
        [-0.3852316, 1.3070072, -0.24187692, 0.9999999],
    ]
)

client_both_right = np.array(
    [
        [0.06430586, -0.6509886, 0.7563589, 0.0],
        [0.6940623, 0.57376546, 0.43482298, 0.0],
        [-0.71703726, 0.49699852, 0.48872307, 0.0],
        [-0.13179393, 1.1662917, -0.42948368, 0.9999998],
    ]
)

client_both_left = np.array(
    [
        [-0.43660122, 0.88827, 0.14267299, 0.0],
        [-0.6418425, -0.19641805, -0.74125427, 0.0],
        [-0.63041043, -0.41520622, 0.6558859, 0.0],
        [-0.45987153, 1.1884942, -0.0532205, 0.9999998],
    ]
)

client_matrix = np.array(
    [
        client_right.T,
        client_both_left.T,
        client_both_right.T,
    ]
)

# print("client_matrix")
# print(client_matrix)

host_right = np.array(
    [
        [0.092240095, -0.5007555, 0.86065996, 0.0],
        [0.30278015, 0.8375217, 0.45484287, 0.0],
        [-0.94858617, 0.21863598, 0.22887182, 0.0],
        [-0.091274284, 1.3827536, -0.60816413, 0.9999996],
    ]
)

host_both_right = np.array(
    [
        [0.1284489, 0.43118837, 0.8930717, 0.0],
        [0.3820718, 0.80950046, -0.4457915, 0.0],
        [-0.9151621, 0.39847913, -0.060765553, 0.0],
        [0.13363218, 1.238118, -0.7244158, 0.99999964],
    ]
)

host_both_left = np.array(
    [
        [-0.5007684, 0.116484866, -0.8577073, 0.0],
        [0.3800316, -0.8607031, -0.33877146, 0.0],
        [-0.7776932, -0.49560198, 0.38674507, 0.0],
        [-0.45513877, 1.1767162, -0.5885545, 0.9999995],
    ]
)

host_matrix = np.array([host_right.T, host_both_right.T, host_both_left.T])

host_matrix = np.array(
    [
        [
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
            [0.0, 0.0, 0.0, 0.9999997019767761],
        ],
        [
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
            [0.0, 0.0, 0.0, 0.9999998211860657],
        ],
        [
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
            [0.0, 0.0, 0.0, 0.9999997615814209],
        ],
    ]
)

client_matrix = np.array(
    [
        [
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
        ],
        [
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
        ],
        [
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
        ],
    ]
)
host_to_client_affine_matrix = generateAffineMatrix3DSelfLU(host_matrix, client_matrix)
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)

host_to_client_affine_matrix_scale, host_to_client_affine_matrix_rotation = (
    decompose_affine_matrix(host_to_client_affine_matrix)
)
host_to_client_affine_matrix[:3, :3] = host_to_client_affine_matrix_rotation

print("host_to_client_affine_matrix_scale")
print(host_to_client_affine_matrix_scale)
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


client_to_host_affine_matrix = generateAffineMatrix3DSelfLU(client_matrix, host_matrix)
print("client_to_host_affine_matrix")
print(client_to_host_affine_matrix)

client_to_host_affine_matrix_scale, client_to_host_affine_matrix_rotation = (
    decompose_affine_matrix(client_to_host_affine_matrix)
)
client_to_host_affine_matrix[:3, :3] = client_to_host_affine_matrix_rotation
print("client_to_host_affine_matrix_scale")
print(client_to_host_affine_matrix_scale)
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
    # client_right_position,  # 中心
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
    # host_right_position,  # 中心
    host_right_position + np.array([baius, baius, baius]),  # 右上前
    host_right_position + np.array([-baius, baius, baius]),  # 左上前
    host_right_position + np.array([-baius, -baius, baius]),  # 左下前
    host_right_position + np.array([baius, -baius, baius]),  # 右下前
    host_right_position + np.array([baius, baius, -baius]),  # 右上後
    host_right_position + np.array([-baius, baius, -baius]),  # 左上後
    host_right_position + np.array([-baius, -baius, -baius]),  # 左下後
    host_right_position + np.array([baius, -baius, -baius]),  # 右下後
]

colors = [
    "green",
    "yellow",
    "purple",
    "orange",
    "pink",
    "brown",
    "gray",
    "cyan",
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
        color=colors[count % len(colors)],
        label="Client Right Hand",
        # alpha=count / 9,
        marker="o",
    )

# 立方体の辺をプロットする
for i in range(8):
    for j in range(i + 1, 8):
        if (
            (i ^ j) == 1
            or (i ^ j) == 2
            or (i ^ j) == 4
            or (i ^ j) == 8
            or (i ^ j) == 3
            or (i ^ j) == 5
            or (i ^ j) == 6
            or (i ^ j) == 7
        ):
            ax.plot(
                [client_right_cubes[i][0], client_right_cubes[j][0]],
                [client_right_cubes[i][1], client_right_cubes[j][1]],
                [client_right_cubes[i][2], client_right_cubes[j][2]],
                color="blue",
                alpha=0.2,
            )

# ホスト側の右手の立方体の描画
count = 0
for cube in client_world_host_hand_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color=colors[count % len(colors)],
        label="Host Right Hand",
        # alpha=count / 9,
        marker="o",
    )

# 立方体の辺をプロットする
for i in range(8):
    for j in range(i + 1, 8):
        if (
            (i ^ j) == 1
            or (i ^ j) == 2
            or (i ^ j) == 4
            or (i ^ j) == 8
            or (i ^ j) == 3
            or (i ^ j) == 5
            or (i ^ j) == 6
            or (i ^ j) == 7
        ):
            ax.plot(
                [
                    client_world_host_hand_cubes[i][0],
                    client_world_host_hand_cubes[j][0],
                ],
                [
                    client_world_host_hand_cubes[i][1],
                    client_world_host_hand_cubes[j][1],
                ],
                [
                    client_world_host_hand_cubes[i][2],
                    client_world_host_hand_cubes[j][2],
                ],
                color="red",
                alpha=0.2,
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

# 5度ずつ回転させるアニメーション
# ani = FuncAnimation(
#     fig,
#     lambda x: ax.view_init(elev=10, azim=x),
#     frames=np.arange(0, 360, 5),
#     interval=100,
# )
# ani.save("client_world.gif", writer="pillow")

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
        color=colors[count % len(colors)],
        label="Client Right Hand",
        # alpha=count / 9,
        marker="o",
    )

# 立方体の辺をプロットする
for i in range(8):
    for j in range(i + 1, 8):
        if (
            (i ^ j) == 1
            or (i ^ j) == 2
            or (i ^ j) == 4
            or (i ^ j) == 8
            or (i ^ j) == 3
            or (i ^ j) == 5
            or (i ^ j) == 6
            or (i ^ j) == 7
        ):
            ax.plot(
                [host_right_cubes[i][0], host_right_cubes[j][0]],
                [host_right_cubes[i][1], host_right_cubes[j][1]],
                [host_right_cubes[i][2], host_right_cubes[j][2]],
                color="red",
                alpha=0.2,
            )

# クライアント側の右手の立方体の描画
count = 0
for cube in host_world_client_hand_cubes:
    count += 1
    ax.scatter(
        cube[0],
        cube[1],
        cube[2],
        color=colors[count % len(colors)],
        label="Host Right Hand",
        # alpha=count / 9,
        marker="o",
    )

# 立方体の辺をプロットする
for i in range(8):
    for j in range(i + 1, 8):
        if (
            (i ^ j) == 1
            or (i ^ j) == 2
            or (i ^ j) == 4
            or (i ^ j) == 8
            or (i ^ j) == 3
            or (i ^ j) == 5
            or (i ^ j) == 6
            or (i ^ j) == 7
        ):
            ax.plot(
                [
                    host_world_client_hand_cubes[i][0],
                    host_world_client_hand_cubes[j][0],
                ],
                [
                    host_world_client_hand_cubes[i][1],
                    host_world_client_hand_cubes[j][1],
                ],
                [
                    host_world_client_hand_cubes[i][2],
                    host_world_client_hand_cubes[j][2],
                ],
                color="blue",
                alpha=0.2,
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

# 5度ずつ回転させるアニメーション
# ani = FuncAnimation(
#     fig,
#     lambda x: ax.view_init(elev=10, azim=x),
#     frames=np.arange(0, 360, 5),
#     interval=100,
# )
# ani.save("host_world.gif", writer="pillow")

plt.show()
