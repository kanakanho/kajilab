from visualization import Visualization
import os


def __main__():
    filenames = os.listdir("data")
    for filename in filenames:
        time = filename.split(".")[0]
        Visualization(time)
        Visualization.plot()