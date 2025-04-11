import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import japanize_matplotlib
import sqlite3
import sys

points = 3  # 3 か 4

args = sys.argv
if len(args) == 2:
    points = int(args[1])

# ワールドから2つの座標系を作成
hash1 = "323"
hash2 = "525"
hash3 = "433"
hash4 = "336"

conn = sqlite3.connect("world.db")
c = conn.cursor()

c.execute(
    f"SELECT * FROM distance_point_{points} WHERE hash1 = ? AND hash2 = ? AND hash3 = ?",
    (hash1, hash2, hash3),
)
rows = c.fetchall()
rows = [list(row) for row in rows]


# hash,distance をプロット
distance = [row[4] for row in rows]

# distance を正規化
distance_norms = [d / max(distance) for d in distance]
# distance_norms = distance
rows.append(distance_norms)

print(max(distance))
print(min(distance))

fig = plt.figure(figsize=(12, 12))
ax = fig.add_subplot(111, projection="3d")

for i in range(0, 50, 10):
    for j in range(0, 50, 10):
        for k in range(0, 50, 10):
            hash = str(i) + str(j) + str(k)
            distance_norm = [
                distance_norms[idx] for idx, row in enumerate(rows) if row[0] == hash
            ]
            if distance_norm:
                ax.scatter(
                    i,
                    j,
                    k,
                    c="r",
                    alpha=distance_norm[0],
                    s=(
                        (distance_norm[0] * 100)
                        if points == 3
                        else (distance_norm[0] * 10)
                    ),
                )


def plot_hashs(hash: str):
    c.execute("SELECT * FROM world WHERE hash = ?", (hash,))
    rows = c.fetchall()
    rows = [list(row) for row in rows]
    for row in rows:
        x = row[0]
        y = row[1]
        z = row[2]
        ax.scatter(x, y, z, c="b")


plot_hashs(hash1)
plot_hashs(hash2)
plot_hashs(hash3)
plot_hashs(hash4)

ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("Z")

plt.show()

c.close()
