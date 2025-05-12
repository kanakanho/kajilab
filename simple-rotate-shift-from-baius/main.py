"""
前提条件
- y軸の向きは端末によって、変わらない
操作
1. クライアントとホスト側でy軸を揃える
2. x軸を揃える
3. z軸の正負を確認し、逆向きの場合は反転させる
"""

from pprint import pprint
import modules.browser as browser

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
import modules.plots as plots
import modules.rotation as rotation
import modules.affine as affine

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
client_matrix = np.array([client_right.T, client_both_left.T, client_both_right.T])

host_matrix = np.array([client_right.T, client_both_left.T, client_both_right.T])
client_matrix = np.array([host_right.T, host_both_right.T, host_both_left.T])

host_matrix = np.array(
    [
        [
            [
                0.5562306642532349,
                0.5555832386016846,
                -0.618008553981781,
                -0.24337060749530792,
            ],
            [
                -0.6506398320198059,
                0.7537873983383179,
                0.09204696118831635,
                0.7893363237380981,
            ],
            [
                0.5169867277145386,
                0.35090163350105286,
                0.780764102935791,
                -0.5038592219352722,
            ],
            [0.0, 0.0, 0.0, 1.0000001192092896],
        ],
        [
            [
                0.1541898101568222,
                0.5248171091079712,
                -0.8371332287788391,
                -0.06998009979724884,
            ],
            [
                -0.6118054986000061,
                0.7160078883171082,
                0.33619382977485657,
                0.6919271349906921,
            ],
            [
                0.7758345007896423,
                0.4603252410888672,
                0.43148720264434814,
                -0.5652991533279419,
            ],
            [0.0, 0.0, 0.0, 0.9999996423721313],
        ],
        [
            [
                -0.4974305033683777,
                -0.31042829155921936,
                -0.8100600242614746,
                -0.39988118410110474,
            ],
            [
                0.7428818345069885,
                -0.6346402764320374,
                -0.2129741758108139,
                0.7015295624732971,
            ],
            [
                -0.4479835033416748,
                -0.7077187299728394,
                0.5463011860847473,
                -0.3203715980052948,
            ],
            [0.0, 0.0, 0.0, 0.9999997615814209],
        ],
    ]
)
client_matrix = np.array(
    [
        [
            [
                0.8661612868309021,
                0.361994206905365,
                -0.34456488490104675,
                -0.416620671749115,
            ],
            [
                -0.3561864495277405,
                0.930767834186554,
                0.08247461915016174,
                0.9175246953964233,
            ],
            [
                0.3505653142929077,
                0.05129300057888031,
                0.9351325035095215,
                -0.3071862459182739,
            ],
            [0.0, 0.0, 0.0, 0.9999997615814209],
        ],
        [
            [
                0.6101363897323608,
                0.47927841544151306,
                -0.6308925747871399,
                -0.27676621079444885,
            ],
            [
                -0.39316582679748535,
                0.8744770884513855,
                0.28409498929977417,
                0.8279070854187012,
            ],
            [
                0.6878619194030762,
                0.07470865547657013,
                0.7219863533973694,
                -0.5423091053962708,
            ],
            [0.0, 0.0, 0.0, 0.9999997615814209],
        ],
        [
            [
                -0.785858154296875,
                -0.19526691734790802,
                -0.586769163608551,
                -0.5836778879165649,
            ],
            [
                0.5389275550842285,
                -0.6815949082374573,
                -0.49496009945869446,
                0.8163708448410034,
            ],
            [
                -0.30328965187072754,
                -0.7051944136619568,
                0.6408713459968567,
                -0.20289365947246552,
            ],
            [0.0, 0.0, 0.0, 0.9999998807907104],
        ],
    ]
)


print(host_matrix[0][:3, 3])
print(client_matrix[0][:3, 3])


host_to_client_affine_matrix = affine.generateAffineMatrix3DSelfLU(
    host_matrix, client_matrix
)
print("初期のアフィン行列の生成")
print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


# --------------------------------------------------------------------


"""
スケーリング成分の除去
"""

_, host_to_client_affine_matrix_rotation = affine.decompose_affine_matrix(
    host_to_client_affine_matrix
)
host_to_client_affine_matrix[:3, :3] = host_to_client_affine_matrix_rotation


client_right_position = client_matrix[0][:3, 3]
print("client_right_position")
print(client_right_position)

baius = 1

angles = rotation.transformation_to_angles(host_right)

# angles を見て、バイアスを決定する
client_right_arrows = [
    client_right_position,  # 中心
    client_right_position
    + np.array([math.cos(angles[1]), math.cos(angles[2]), math.cos(angles[0])]) * baius,
    client_right_position
    + np.array([math.cos(angles[0]), math.cos(angles[1]), math.cos(angles[2])]) * baius,
    client_right_position
    + np.array([math.cos(angles[2]), math.cos(angles[0]), math.cos(angles[1])]) * baius,
]

print("client_right_arrows")
print(client_right_arrows)

client_world_host_hand_arrows = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows
]

print("client_world_host_hand_arrows")
print(client_world_host_hand_arrows)


# shift_value = client_world_host_hand_arrows[0][:3] - client_right_arrows[0]
shift_value = client_world_host_hand_arrows[0][:3] - client_right_arrows[0]

print("shift_value")
print(shift_value)

client_right_arrows_shift = [arrow - shift_value for arrow in client_right_arrows]
# client_right_arrows_shift = arrow / client_right_arrows
client_world_host_hand_arrows_shift = [
    arrow[:3] - shift_value for arrow in client_world_host_hand_arrows
]

print("client_right_arrows_shift")
pprint(client_right_arrows_shift)
print("client_world_host_hand_arrows_shift1")
pprint(client_world_host_hand_arrows_shift)

client_right_arrows_shift = [
    arrow - client_right_arrows_shift[0] for arrow in client_right_arrows_shift
]
client_world_host_hand_arrows_shift = [
    arrow - client_world_host_hand_arrows_shift[0]
    for arrow in client_world_host_hand_arrows_shift
]

print("client_right_arrows_shift")
pprint(client_right_arrows_shift)
print("client_world_host_hand_arrows_shift2")
pprint(client_world_host_hand_arrows_shift)


plots.plots(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    is_ani=True,
    suffix="shift",
)


# plt.show()


# # スクリプトの該当部分を以下のように置き換えることを検討してください
# client_right_position = client_matrix[0][:3, 3]
# baius = 1
# client_right_arrows_local = np.array([
#     [baius, 0, 0],
#     [0, baius, 0],
#     [0, 0, baius]
# ])


# client_world_host_hand_arrows_local = np.array([
#     (host_to_client_affine_matrix[:3, :3] @ arrow) for arrow in client_right_arrows_local
# ])

# affine_matrix_svd = rotation.align_axes_svd(client_right_arrows_local, client_world_host_hand_arrows_local)

# print("SVDで計算されたアフィン行列")
# print(affine_matrix_svd)

# # この affine_matrix_svd を用いて、点の変換や可視化を行う
# client_world_host_hand_arrows_aligned_svd = [
#     affine_matrix_svd @ np.array([*arrow_local, 1])
#     for arrow_local in client_right_arrows_local
# ]

# plots.plots(
#     np.array([[0,0,0,1][:3]] + client_right_arrows_local.tolist()),
#     [arr[:3] for arr in [[0,0,0,1]] + client_world_host_hand_arrows_aligned_svd],
#     is_ani=True,
#     suffix="aligned_svd"
# )

print("client_right_arrows_shift")
print(client_right_arrows_shift)
print("client_world_host_hand_arrows_shift")
print(client_world_host_hand_arrows_shift)

host_to_client_affine_matrix = rotation.rotation_y(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    host_to_client_affine_matrix,
)

client_world_host_hand_arrows_shift = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows_shift
]

plots.plots(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    is_ani=True,
    suffix="rotate_y",
)

print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


host_to_client_affine_matrix = rotation.rotation_x(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    host_to_client_affine_matrix,
)

client_world_host_hand_arrows_shift = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows_shift
]

plots.plots(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    is_ani=True,
    suffix="rotate_x",
)

print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


host_to_client_affine_matrix = rotation.rotation_z(
    client_world_host_hand_arrows_shift,
    client_world_host_hand_arrows_shift,
    host_to_client_affine_matrix,
)

client_world_host_hand_arrows_shift = [
    host_to_client_affine_matrix @ np.array([*arrow, 1])
    for arrow in client_right_arrows_shift
]

plots.plots(
    client_right_arrows_shift,
    client_world_host_hand_arrows_shift,
    is_ani=True,
    suffix="rotate_z",
)

print("host_to_client_affine_matrix")
print(host_to_client_affine_matrix)


# host_to_client_affine_matrix = rotation.rotation_y(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     host_to_client_affine_matrix,
# )

# client_world_host_hand_arrows_shift = [
#     host_to_client_affine_matrix @ np.array([*arrow, 1])
#     for arrow in client_right_arrows_shift
# ]

# plots.plots(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     # is_ani=True,
#     suffix="rotate_y_2",
# )


# host_to_client_affine_matrix = rotation.rotation_x(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     host_to_client_affine_matrix,
# )

# client_world_host_hand_arrows_shift = [
#     host_to_client_affine_matrix @ np.array([*arrow, 1])
#     for arrow in client_right_arrows_shift
# ]

# plots.plots(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     # is_ani=True,
#     suffix="rotate_x_2",
# )


# host_to_client_affine_matrix = rotation.rotation_z(
#     client_world_host_hand_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     host_to_client_affine_matrix,
# )

# client_world_host_hand_arrows_shift = [
#     host_to_client_affine_matrix @ np.array([*arrow, 1])
#     for arrow in client_right_arrows_shift
# ]

# plots.plots(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     # is_ani=True,
#     suffix="rotate_z_2",
# )


# host_to_client_affine_matrix = np.array(
#     [
#         [
#             0.17723523926802423,
#             -0.898001966943104,
#             0.4027159511714464,
#             1.4552181874656285e-08,
#         ],
#         [
#             0.6094329277807777,
#             -0.22115955036752025,
#             -0.7613671649196501,
#             1.0223272097819658e-08,
#         ],
#         [
#             0.7727736903506457,
#             0.38036945283178675,
#             0.5080747020412368,
#             4.1242520584012065e-09,
#         ],
#         [0.0, 0.0, 0.0, 1.0],
#     ]
# )

# client_world_host_hand_arrows_shift = [
#     host_to_client_affine_matrix @ np.array([*arrow, 1])
#     for arrow in client_right_arrows_shift
# ]

# plots.plots(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     # is_ani=True,
#     suffix="swift",
# )


# host_to_client_affine_matrix = np.array(
#     [
#         [
#             -0.6022129784195152,
#             0.7951146460484095,
#             0.07163957190274994,
#             1.4552181874656285e-08,
#         ],
#         [
#             -0.5659325358377687,
#             -0.36188824903268413,
#             -0.7407815198101871,
#             1.0223272097819658e-08,
#         ],
#         [
#             -0.5630807166857427,
#             -0.4866514099962835,
#             0.6679150482249222,
#             4.1242520584012065e-09,
#         ],
#         [0.0, 0.0, 0.0, 1.0],
#     ]
# )

# client_world_host_hand_arrows_shift = [
#     host_to_client_affine_matrix @ np.array([*arrow, 1])
#     for arrow in client_right_arrows_shift
# ]

# plots.plots(
#     client_right_arrows_shift,
#     client_world_host_hand_arrows_shift,
#     # is_ani=True,
#     suffix="swift",
# )

browser.open_browser(
    np.array(
        [
            # client_matrix[0].T,
            # (host_to_client_affine_matrix @ host_matrix[0]).T,
            client_matrix[1].T,
            (host_to_client_affine_matrix @ host_matrix[1]).T,
            # client_matrix[2].T,
            # (host_to_client_affine_matrix @ host_matrix[2]).T,
        ]
    )
)
