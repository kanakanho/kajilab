import sqlite3
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation


# エラーのノルムが一番小さいもののハッシュ値を取得
def get_best_hash(hash_df, is_min=True):
    if is_min:
        best_index = hash_df["error_norm"].idxmin()
    else:
        best_index = hash_df[
            "error_norm"
        ].idxmax()  # 最大のエラーのノルムを持つものを選択
    best_hash = hash_df.iloc[best_index]

    print("Best Hash:")
    print(f"Hash A: {best_hash['hash_a']}")
    print(f"Hash B: {best_hash['hash_b']}")
    print(f"Hash C: {best_hash['hash_c']}")
    print(f"Hash D: {best_hash['hash_d']}")
    print(f"Error Norm: {best_hash['error_norm']}")
    print(f"Error A: {best_hash['error_x']}")
    print(f"Error B: {best_hash['error_y']}")
    print(f"Error C: {best_hash['error_z']}")
    print(f"Affine Matrix A: {best_hash['affine_matrix']}")

    return best_hash


# 3Dプロットの表示
def plot_3d_affine_matrices(best_hashs):
    conn = sqlite3.connect("world.db")
    c = conn.cursor()

    potions = []
    for hash_value in best_hashs:
        c.execute("SELECT * FROM world WHERE hash = ?", (str(hash_value),))
        rows = c.fetchall()
        rows = [list(row) for row in rows]
        potions.append([rows[0][0], rows[0][1], rows[0][2]])

    conn.close()

    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")
    # 各ポーションの位置をプロット
    for i, potion in enumerate(potions):
        ax.scatter(
            potion[0],
            potion[1],
            potion[2],
            label=f"Hash: {best_hash[f'hash_{chr(97+i)}']}",
            s=100,
        )
    ax.set_xlabel("X axis")
    ax.set_ylabel("Y axis")
    ax.set_zlabel("Z axis")
    ax.set_title("3D Affine Matrices Points")
    ax.legend(
        [
            f"Hash: {best_hash['hash_a']}",
            f"Hash: {best_hash['hash_b']}",
            f"Hash: {best_hash['hash_c']}",
            f"Hash: {best_hash['hash_d']}",
        ]
    )

    # 5度ずつ回転させるアニメーション
    ani = FuncAnimation(
        fig,
        lambda x: ax.view_init(elev=10, azim=x),
        frames=np.arange(0, 360, 5),
        interval=100,
    )
    ani.save("worst.gif", writer="pillow")

    # plt.show()


hash_df = pd.read_sql_query(
    "SELECT * FROM affine_matrices", sqlite3.connect("affine_matrices.db")
)
best_hash = get_best_hash(hash_df)

plot_3d_affine_matrices(
    [best_hash["hash_a"], best_hash["hash_b"], best_hash["hash_c"], best_hash["hash_d"]]
)

best_hash = get_best_hash(hash_df, is_min=False)

plot_3d_affine_matrices(
    [best_hash["hash_a"], best_hash["hash_b"], best_hash["hash_c"], best_hash["hash_d"]]
)