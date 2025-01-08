import numpy as np

# Define source points (input points before transformation)
src_points = np.array([[0, 0], [1, 0], [2, 3], [1, 2]])

# Define destination points (output points after transformation)
dst_points = np.array([[0, 0], [1, 0], [1, 1], [0, 1]])

# Construct the linear system to solve for the homography matrix
A = []
for (x, y), (x_prime, y_prime) in zip(src_points, dst_points):
    A.append([-x, -y, -1, 0, 0, 0, x * x_prime, y * x_prime, x_prime])
    A.append([0, 0, 0, -x, -y, -1, x * y_prime, y * y_prime, y_prime])
A = np.array(A)
print(A)

# Solve for H (up to a scale factor) using Singular Value Decomposition (SVD)
_, _, V = np.linalg.svd(A)
print(V)
H = V[-1].reshape(3, 3)
print(H)

# Normalize H so that H[2, 2] = 1 for consistency
H /= H[2, 2]

print(H)
