import numpy as np


def clacX(matrixs: list[list[float]], matrixDashs: list[list[float]]):
    res_matrix = np.zeros((1, 8), dtype=np.float32)
    print(len(matrixs))
    for i in range(len(matrixs)):
        row1 = np.array(
            [
                matrixDashs[i][0],
                matrixDashs[i][1],
                1,
                0,
                0,
                0,
                -matrixs[i][0] * matrixDashs[i][0],
                -matrixs[i][0] * matrixDashs[i][1],
            ]
        )
        row2 = np.array(
            [
                0,
                0,
                0,
                matrixDashs[i][0],
                matrixDashs[i][1],
                1,
                -matrixs[i][1] * matrixDashs[i][0],
                -matrixs[i][1] * matrixDashs[i][1],
            ]
        )
        res_matrix = np.vstack((res_matrix, row1))
        res_matrix = np.vstack((res_matrix, row2))

    return res_matrix[1:]


def clac_homography(
    matrixs: list[list[float]], matrixDashs: list[list[float]]
) -> np.ndarray | None:
    if (len(matrixs) < 4) or (len(matrixDashs) < 4):
        print("Matrixs and MatrixDashs must be more than 4")
        return None
    matrix = clacX(matrixs, matrixDashs)
    print(matrix)
    matrixT = matrix.T
    print(matrixT)
    print(matrixT @ matrix)
    print(np.linalg.inv(matrixT @ matrix))
    clac = np.linalg.inv(matrixT @ matrix) @ matrixT

    h = clac @ np.array(matrixs).flatten()
    print(h)
    h = np.append(h, 1).reshape(3, 3)

    return h


print(
    clac_homography([[0, 0], [1, -1], [1, 0], [0, 2]], [[0, 0], [1, 0], [1, 1], [0, 1]])
)
