from IPython.display import display, HTML, IFrame
from IPython.core.display import DisplayHandle
import webbrowser
import numpy as np


def open_browser(queryMatrix: np.ndarray) -> None:
    base_url = "https://threejs-rotation-visualization.kanakanho.workers.dev/?matrix="

    # queryMatrixが2次元配列であることを前提に処理
    matrixs = []
    for row in queryMatrix:
        matrixs.append(row.flatten().tolist())  # 各行を1次元リストに変換

    # Open the HTML file in the default web browser
    webbrowser.open(f"{base_url}{matrixs.__str__()}")


def matrix_to_url(queryMatrix: np.ndarray) -> str:
    base_url = "https://threejs-rotation-visualization.kanakanho.workers.dev/?matrix="

    # queryMatrixが2次元配列であることを前提に処理
    matrixs = []
    for row in queryMatrix:
        matrixs.append(row.flatten().tolist())  # 各行を1次元リストに変換

    # Open the HTML file in the default web browser
    return f"{base_url}{matrixs.__str__()}"
