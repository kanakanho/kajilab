import numpy as np
import math
from scipy.linalg import polar
from scipy.linalg import svd
from scipy.spatial.transform import Rotation as R


def rotation(
    mine_affine_matrix: np.ndarray,
    other_affine_matrix: np.ndarray,
    affine_matix: np.ndarray,
) -> np.ndarray:
    """
    それぞれのアフィン行列から、それぞれの軸の回転成分を抽出して、その誤差を補正する関数
    :param mine_affine_matrix: 自分のアフィン行列
    :param other_affine_matrix: 他人のアフィン行列
    :param affine_matix: アフィン行列
    :return: np.array(): 補正されたアフィン行列
    """
    # 自分のアフィン行列から回転成分を抽出
    mine_rotation_matrix = mine_affine_matrix[:3, :3]
    mine_rotation_x = math.atan2(mine_rotation_matrix[2, 1], mine_rotation_matrix[2, 2])
    mine_rotation_y = math.atan2(
        -mine_rotation_matrix[2, 0],
        math.sqrt(mine_rotation_matrix[2, 1] ** 2 + mine_rotation_matrix[2, 2] ** 2),
    )
    mine_rotation_z = math.atan2(mine_rotation_matrix[1, 0], mine_rotation_matrix[0, 0])

    # 他人のアフィン行列から回転成分を抽出
    other_rotation_matrix = other_affine_matrix[:3, :3]
    other_rotation_x = math.atan2(
        other_rotation_matrix[2, 1], other_rotation_matrix[2, 2]
    )
    other_rotation_y = math.atan2(
        -other_rotation_matrix[2, 0],
        math.sqrt(other_rotation_matrix[2, 1] ** 2 + other_rotation_matrix[2, 2] ** 2),
    )
    other_rotation_z = math.atan2(
        other_rotation_matrix[1, 0], other_rotation_matrix[0, 0]
    )

    # 自分の回転成分を補正
    theta_x = other_rotation_x - mine_rotation_x
    theta_y = other_rotation_y - mine_rotation_y
    theta_z = other_rotation_z - mine_rotation_z
    theta_x_rotation_matrix = np.array(
        [
            [1, 0, 0],
            [0, math.cos(theta_x), -math.sin(theta_x)],
            [0, math.sin(theta_x), math.cos(theta_x)],
        ]
    )
    theta_y_rotation_matrix = np.array(
        [
            [math.cos(theta_y), 0, math.sin(theta_y)],
            [0, 1, 0],
            [-math.sin(theta_y), 0, math.cos(theta_y)],
        ]
    )
    theta_z_rotation_matrix = np.array(
        [
            [math.cos(theta_z), -math.sin(theta_z), 0],
            [math.sin(theta_z), math.cos(theta_z), 0],
            [0, 0, 1],
        ]
    )

    # 補正されたアフィン行列を計算
    corrected_rotation_matrix = (
        theta_x_rotation_matrix @ theta_y_rotation_matrix @ theta_z_rotation_matrix
    )
    corrected_affine_matrix = np.eye(4)
    corrected_affine_matrix[:3, :3] = corrected_rotation_matrix
    corrected_affine_matrix[:3, 3] = affine_matix[:3, 3]
    corrected_affine_matrix[3, :3] = 0
    corrected_affine_matrix[3, 3] = 1

    return corrected_affine_matrix
