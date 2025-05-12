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


def transformation_to_angles(transform) -> np.ndarray:
    """
    回転行列を計算する関数
    :param transform: 変換行列
    :return: np.array([x,y,z]) の回転成分（deg）
    """
    # 回転行列を取得
    rotation_matrix = transform[:3, :3]

    # 回転行列から回転角を計算
    r = R.from_matrix(rotation_matrix)
    angles = r.as_euler("zxy", degrees=True)

    # 回転角を返す
    return angles



def rotation_y(mine_arrows_shift, world_hand_arrows_shift, affine_matrix) -> np.ndarray:
    world_hand_arrow_shift = []
    world_hand_arrow_shift = world_hand_arrows_shift[2]
    print("world_hand_arrow_shift")
    print(world_hand_arrow_shift)

    mine_arrow_shift = []
    mine_arrow_shift = mine_arrows_shift[2]

    print("mine_arrow_shift")
    print(mine_arrow_shift)

    # 正規化する
    world_hand_arrow_shift = world_hand_arrow_shift / np.linalg.norm(world_hand_arrow_shift)
    mine_arrow_shift = mine_arrow_shift / np.linalg.norm(mine_arrow_shift)

    theta_x = math.asin(world_hand_arrow_shift[0])
    mine_arrow_theta_x = math.asin(mine_arrow_shift[0])
    theta_x = mine_arrow_theta_x - theta_x
    theta_x_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_x), -math.sin(theta_x)],
            [0, math.sin(theta_x), math.cos(theta_x)],
        ]
    )
    world_hand_theta_y = math.asin(world_hand_arrow_shift[1])
    mine_arrow_theta_y = math.asin(mine_arrow_shift[1])
    print(world_hand_theta_y * 180 / math.pi)
    print(mine_arrow_theta_y * 180 / math.pi)
    theta_y = mine_arrow_theta_y -  world_hand_theta_y
    print(theta_y * 180 / math.pi)
    theta_y_rotation_matrix = np.array(
        [
            [math.cos(theta_y), 0, math.sin(theta_y)],
            [0, 1, 0],
            [-math.sin(theta_y), 0, math.cos(theta_y)],
        ]
    )
    theta_z = math.asin(world_hand_arrow_shift[2])
    mine_arrow_theta_z = math.asin(mine_arrow_shift[2])
    theta_z = mine_arrow_theta_z - theta_z
    theta_z_rotation_matrix = np.array(
        [
            [math.cos(theta_z), -math.sin(theta_z), 0],
            [math.sin(theta_z), math.cos(theta_z), 0],
            [0, 0, 1],
        ]
    )

    # アフィン行列を更新
    affine_matrix[:3, :3] = theta_z_rotation_matrix @ theta_y_rotation_matrix @ theta_x_rotation_matrix
    # affine_matrix[:3, :3] = theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    # affine_matrix[:3, :3] = affine_matrix[:3, :3] @ theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    return affine_matrix


def rotation_x(mine_arrows_shift, world_hand_arrows_shift, affine_matrix) -> np.ndarray:
    arrows_shift = []
    arrows_shift = world_hand_arrows_shift[1]

    mine_arrow_shift = []
    mine_arrow_shift = mine_arrows_shift[1]

    # 正規化する
    arrows_shift = arrows_shift / np.linalg.norm(arrows_shift)
    mine_arrow_shift = mine_arrow_shift / np.linalg.norm(mine_arrow_shift)

    theta_x = math.asin(arrows_shift[0])
    mine_arrow_theta_x = math.asin(mine_arrow_shift[0])
    theta_x = mine_arrow_theta_x - theta_x
    theta_x_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_x), -math.sin(theta_x)],
            [0, math.sin(theta_x), math.cos(theta_x)],
        ]
    )

    theta_y = math.asin(arrows_shift[1])
    mine_arrow_theta_y = math.asin(mine_arrow_shift[1])
    theta_y = mine_arrow_theta_y - theta_y
    theta_y_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_y), -math.sin(theta_y)],
            [0, math.sin(theta_y), math.cos(theta_y)],
        ]
    )

    theta_z = math.asin(arrows_shift[2])
    mine_arrow_theta_z = math.asin(mine_arrow_shift[2])
    theta_z = mine_arrow_theta_z - theta_z
    theta_z_rotation_matrix = np.array(
        [
            [math.cos(theta_z), -math.sin(theta_z), 0],
            [math.sin(theta_z), math.cos(theta_z), 0],
            [0, 0, 1],
        ]
    )

    # アフィン行列を更新
    affine_matrix[:3, :3] = theta_z_rotation_matrix @ theta_y_rotation_matrix @ theta_x_rotation_matrix
    # affine_matrix[:3, :3] = theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    # affine_matrix[:3, :3] = affine_matrix[:3, :3] @ theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    return affine_matrix


def rotation_z(mine_arrows_shift, world_hand_arrows_shift, affine_matrix) -> np.ndarray:
    arrows_shift = []
    arrows_shift = world_hand_arrows_shift[3]

    mine_arrow_shift = []
    mine_arrow_shift = mine_arrows_shift[3]

    # 正規化する
    arrows_shift = arrows_shift / np.linalg.norm(arrows_shift)
    mine_arrow_shift = mine_arrow_shift / np.linalg.norm(mine_arrow_shift)

    theta_x = math.asin(arrows_shift[0])
    mine_arrow_theta_x = math.asin(mine_arrow_shift[0])
    theta_x = mine_arrow_theta_x - theta_x
    theta_x_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_x), -math.sin(theta_x)],
            [0, math.sin(theta_x), math.cos(theta_x)],
        ]
    )

    theta_y = math.asin(arrows_shift[1])
    mine_arrow_theta_y = math.asin(mine_arrow_shift[1])
    theta_y = mine_arrow_theta_y - theta_y
    theta_y_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_y), -math.sin(theta_y)],
            [0, math.sin(theta_y), math.cos(theta_y)],
        ]
    )

    theta_z = math.asin(arrows_shift[2])
    mine_arrow_theta_z = math.asin(mine_arrow_shift[2])
    theta_z = mine_arrow_theta_z - theta_z
    theta_z_rotation_matrix = np.array(
        [
            [math.cos(theta_z), -math.sin(theta_z), 0],
            [math.sin(theta_z), math.cos(theta_z), 0],
            [0, 0, 1],
        ]
    )

    # アフィン行列を更新
    affine_matrix[:3, :3] = theta_z_rotation_matrix @ theta_y_rotation_matrix @ theta_x_rotation_matrix
    # affine_matrix[:3, :3] = theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    # affine_matrix[:3, :3] = affine_matrix[:3, :3] @ theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    return affine_matrix

def align_axes_svd(source_arrows, target_arrows):
    """SVDを用いて2つのベクトルの組の間の最適な回転行列を計算する"""
    # 中心化
    source_centroid = np.mean(source_arrows, axis=0)
    target_centroid = np.mean(target_arrows, axis=0)
    centered_source = source_arrows - source_centroid
    centered_target = target_arrows - target_centroid

    # 外積行列（共分散行列）の計算
    H = centered_source.T @ centered_target

    # SVD
    U, S, V_t = svd(H)

    # 回転行列の構築
    R = V_t.T @ U.T

    # 反射成分の補正 (determinantが-1の場合)
    if np.linalg.det(R) < 0:
        V_t[-1, :] *= -1
        R = V_t.T @ U.T

    # 並進ベクトルの計算
    t = target_centroid - R @ source_centroid

    # アフィン変換行列の構築
    affine_matrix = np.eye(4)
    affine_matrix[:3, :3] = R
    affine_matrix[:3, 3] = t

    return affine_matrix


