#!/usr/bin/python

import matplotlib.path as mpath
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import scipy.io as sio

mat = sio.loadmat('bezier.mat')
mat = mat['bezier']
Path = mpath.Path
pathData = []
mainCP = []
otherCP = []
for i in range(mat.shape[0]):
    pathData.append((Path.MOVETO, (mat[i, 0], mat[i, 1])))
    pathData.append((Path.CURVE4, (mat[i, 2], mat[i, 3])))
    pathData.append((Path.CURVE4, (mat[i, 4], mat[i, 5])))
    pathData.append((Path.CURVE4, (mat[i, 6], mat[i, 7])))
    mainCP.append((mat[i, 0], mat[i, 1]))
    mainCP.append((mat[i, 6], mat[i, 7]))
    otherCP.append((mat[i, 2], mat[i, 3]))
    otherCP.append((mat[i, 4], mat[i, 5]))

fig, ax = plt.subplots()
codes, verts = zip(*pathData)
path = mpath.Path(verts, codes)
patch = mpatches.PathPatch(path, edgecolor='r', fill=False)
ax.add_patch(patch)

# plot control points
x, y = zip(*mainCP)
line, = ax.plot(x, y, 'go', alpha=0.5)
# x, y = zip(*otherCP)
# line, = ax.plot(x, y, 'go', alpha=0.5)

# ax.grid()
ax.axis('equal')
ax.invert_yaxis()
plt.show()

