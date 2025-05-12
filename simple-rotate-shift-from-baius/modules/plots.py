import numpy as np
import math
from scipy.linalg import polar
from scipy.spatial.transform import Rotation as R
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm
import pandas as pd
import japanize_matplotlib

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


# plot
def plots(
    client_right_arrows,
    client_world_host_hand_arrows,
    is_ani=False,
    suffix="",
    axis = "all",
):
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
    for arrow in client_right_arrows:
        count += 1
        if axis == "x":
            if count != 2:
                continue
        elif axis == "y":
            if count != 3:
                continue
        elif axis == "z":
            if count != 4:
                continue
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Client Right Hand",
            # alpha=count / 9,
            marker="o",
        )

    # client_right_arrows[0] からそれ以外の点までの辺をプロット
    for i in range(1, len(client_right_arrows)):
        if axis == "x":
            if i != 1:
                continue
        elif axis == "y":
            if i != 2:
                continue
        elif axis == "z":
            if i != 3:
                continue
        ax.plot(
            [client_right_arrows[0][0], client_right_arrows[i][0]],
            [client_right_arrows[0][1], client_right_arrows[i][1]],
            [client_right_arrows[0][2], client_right_arrows[i][2]],
            color="pink",
            alpha=0.5,
        )

    # ホスト側の右手の立方体の描画
    count = 0
    for arrow in client_world_host_hand_arrows:
        count += 1
        if axis == "x":
            if count != 2:
                continue
        elif axis == "y":
            if count != 3:
                continue
        elif axis == "z":
            if count != 4:
                continue
        ax.scatter(
            arrow[0],
            arrow[1],
            arrow[2],
            color=colors[count % len(colors)],
            label="Host Right Hand",
            # alpha=count / 9,
            marker="o",
        )

    # client_world_host_hand_arrows[0] からそれ以外の点までの辺をプロット
    for i in range(1, len(client_world_host_hand_arrows)):
        if axis == "x":
            if i != 1:
                continue
        elif axis == "y":
            if i != 2:
                continue
        elif axis == "z":
            if i != 3:
                continue
        ax.plot(
            [client_world_host_hand_arrows[0][0], client_world_host_hand_arrows[i][0]],
            [client_world_host_hand_arrows[0][1], client_world_host_hand_arrows[i][1]],
            [client_world_host_hand_arrows[0][2], client_world_host_hand_arrows[i][2]],
            color="lightblue",
            alpha=0.5,
        )

    # 軸の範囲を設定
    x_max = max(
        max(client_right_arrows, key=lambda x: x[0])[0],
        max(client_world_host_hand_arrows, key=lambda x: x[0])[0],
    )
    x_min = min(
        min(client_right_arrows, key=lambda x: x[0])[0],
        min(client_world_host_hand_arrows, key=lambda x: x[0])[0],
    )
    y_max = max(
        max(client_right_arrows, key=lambda x: x[1])[1],
        max(client_world_host_hand_arrows, key=lambda x: x[1])[1],
    )
    y_min = min(
        min(client_right_arrows, key=lambda x: x[1])[1],
        min(client_world_host_hand_arrows, key=lambda x: x[1])[1],
    )
    z_max = max(
        max(client_right_arrows, key=lambda x: x[2])[2],
        max(client_world_host_hand_arrows, key=lambda x: x[2])[2],
    )
    z_min = min(
        min(client_right_arrows, key=lambda x: x[2])[2],
        min(client_world_host_hand_arrows, key=lambda x: x[2])[2],
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
        ani.save(f"2d_rotate_{suffix}.gif", writer="pillow")

    # plt.show()
