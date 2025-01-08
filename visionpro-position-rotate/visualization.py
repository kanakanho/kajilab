import pandas as pd
import matplotlib.pyplot as plt
import os
from scipy.spatial.transform import Rotation


def matrix_to_quaternion(matrix):
    q = Rotation.from_matrix(matrix).as_quat()
    return q


def output_file(df: pd.DataFrame, time: float):
    # それぞれの座標をクォータニオンに変換
    quat = df.apply(
        lambda x: matrix_to_quaternion(
            [
                [x["0x"], x["0y"], x["0z"]],
                [x["1x"], x["1y"], x["1z"]],
                [x["2x"], x["2y"], x["2z"]],
            ]
        ),
        axis=1,
    )
    df["t"] = df["time"]
    df["x"] = quat.apply(lambda x: x[0])
    df["y"] = quat.apply(lambda x: x[1])
    df["z"] = quat.apply(lambda x: x[2])
    df["w"] = quat.apply(lambda x: x[3])

    # out/{time}/{type}/{vector3|quaternion}.csv に保存
    if not os.path.exists(f"out/{time}"):
        os.makedirs(f"out/{time}")
    if not os.path.exists(f'out/{time}/{df["type"].iloc[0]}'):
        os.makedirs(f'out/{time}/{df["type"].iloc[0]}')
    cpdf = df[["t", "3x", "3y", "3z"]]
    cpdf.columns = ["t", "x", "y", "z"]
    cpdf.to_json(f'out/{time}/{df["type"].iloc[0]}/vector3.json', orient="records")
    df[["t", "x", "y", "z", "w"]].to_json(
        f'out/{time}/{df["type"].iloc[0]}/quaternion.json', orient="records"
    )
    return df


class Visualization:
    time: str
    file_path: str
    df: pd.DataFrame
    df_handAnchor: pd.DataFrame
    df_indexFingerTipParent: pd.DataFrame
    df_indexFingerTipAnchor: pd.DataFrame

    def __init__(self, time: str):
        self.time = time
        self.file_path = f"data/{time}.csv"
        df = pd.read_csv(self.file_path)

        # 前10個消す
        df = df.iloc[20:]

        # type == "handAnchor" のみ抽出
        df_handAnchor = df[df["type"] == "handAnchor"]
        df_handAnchor.sort_values("time", ascending=True)
        df_indexFingerTipParent = df[df["type"] == "indexFingerTipParent"]
        df_indexFingerTipParent.sort_values("time", ascending=True)
        df_indexFingerTipAnchor = df[df["type"] == "indexFingerTipAnchor"]
        df_indexFingerTipAnchor.sort_values("time", ascending=True)

        output_file(df_handAnchor, time)
        output_file(df_indexFingerTipParent, time)
        output_file(df_indexFingerTipAnchor, time)

        self.df = df
        self.df_handAnchor = df_handAnchor
        self.df_indexFingerTipParent = df_indexFingerTipParent
        self.df_indexFingerTipAnchor = df_indexFingerTipAnchor
    
    def plot(self):
        handanchor_max = self.df_handAnchor[['3x', '3y', '3z']].max().max() + 0.1
        handanchor_min = self.df_handAnchor[['3x', '3y', '3z']].min().min() - 0.1
        fig, ax = plt.subplots(1, 3, figsize=(15, 5))
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['3x'], label='x')
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['3y'], label='y')
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['3z'], label='z')
        ax[0].legend()
        ax[0].set_title('handAnchor')
        ax[0].set_ylim(handanchor_min, handanchor_max)

        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3x'], label='x')
        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3y'], label='y')
        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3z'], label='z')
        ax[1].legend()
        ax[1].set_title('indexFingerTipParent')
        ax[1].set_ylim(handanchor_min, handanchor_max)

        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3x'], label='x')
        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3y'], label='y')
        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3z'], label='z')
        ax[2].legend()
        ax[2].set_title('indexFingerTipAnchor')
        ax[2].set_ylim(handanchor_min, handanchor_max)
        # plt.show()
        plt.savefig(f'out/{self.time}/plot_position.png')

        # typeごとにプロット
        handanchor_max = 1.1
        handanchor_min = -1.1
        fig, ax = plt.subplots(1, 3, figsize=(15, 5))
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['x'], label='quaternion_x')
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['y'], label='quaternion_y')
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['z'], label='quaternion_z')
        ax[0].plot(self.df_handAnchor['time'], self.df_handAnchor['w'], label='quaternion_w')
        ax[0].legend()
        ax[0].set_title('handAnchor')
        ax[0].set_ylim(handanchor_min, handanchor_max)

        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['x'], label='quaternion_x')
        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['y'], label='quaternion_y')
        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['z'], label='quaternion_z')
        ax[1].plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['w'], label='quaternion_w')
        ax[1].legend()
        ax[1].set_title('indexFingerTipParent')
        ax[1].set_ylim(handanchor_min, handanchor_max)

        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['x'], label='quaternion_x')
        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['y'], label='quaternion_y')
        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['z'], label='quaternion_z')
        ax[2].plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['w'], label='quaternion_w')
        ax[2].legend()
        ax[2].set_title('indexFingerTipAnchor')
        ax[2].set_ylim(handanchor_min, handanchor_max)
        # plt.show()
        plt.savefig(f'out/{self.time}/plot_quaternion.png')

    def all_plot(self):
        # それぞれプロット
        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['3x'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3x'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3x'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['3y'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3y'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3y'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['3z'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['3z'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['3z'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        # それぞれのクォータニオンをプロット
        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['x'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['x'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['x'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['y'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['y'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['y'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['z'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['z'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['z'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()

        fig = plt.figure()
        plt.plot(self.df_handAnchor['time'], self.df_handAnchor['w'], label='handAnchor')
        plt.plot(self.df_indexFingerTipAnchor['time'], self.df_indexFingerTipAnchor['w'], label='indexFingerTipAnchor')
        plt.plot(self.df_indexFingerTipParent['time'], self.df_indexFingerTipParent['w'], label='indexFingerTipParent')
        plt.legend()
        # plt.show()
