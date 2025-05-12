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
