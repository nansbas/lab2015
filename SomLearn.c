#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "MyMexHelper.h"

Matrix ridge, ori, cell, v4pos;
double minRidge, oriFactor, neighbor;
int * map;
int adjx[4] = {-1,-1, 0, 1};
int adjy[4] = { 0,-1,-1,-1};

#define MAX_CELLS 1000
#define C(r,c) (((double*)(cell.data))[(r)+(c)*cell.h])
#define R(x,y,z) (((double*)(ridge.data))[(y)+(x)*ridge.h+(z)*ridge.h*ridge.w])
#define ORI(x,y,z) (((double*)(ori.data))[(y)+(x)*ridge.h+(z)*ridge.h*ridge.w])
#define M(x,y) (map[(y)+(x)*ridge.h])
#define V4P(i,j,k) (((double*)(v4pos.data))[(i)+(j)*cell.h+(k)*v4pos.h])

struct _cell_t_ {
  double x, y, sina, cosa, w, out, nx, ny, nw;
} cells[MAX_CELLS];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int x, y, i, j, k, ax, ay, ak;
  double w, d, minD, o, cx, cy;
  if (!GetInOutMatrix(nrhs, prhs, 0, nlhs, plhs, 0, mxDOUBLE_CLASS, &cell)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &ridge)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputValue(nrhs, prhs, 3, &minRidge)) return;
  if (!GetInputValue(nrhs, prhs, 4, &oriFactor)) return;
  if (!GetInputValue(nrhs, prhs, 5, &neighbor)) return;
  for (i = 0; i < cell.h; i++) {
    cells[i].x = 0;
    cells[i].y = 0;
    cells[i].sina = 0;
    cells[i].cosa = 0;
    cells[i].w = 0;
    cells[i].out = 0;
    cells[i].nx = 0;
    cells[i].ny = 0;
    cells[i].nw = 0;
  }
  for (i = 0; i < ridge.n; i++)
  for (x = 0; x < ridge.w; x++)
  for (y = 0; y < ridge.h; y++) {
    w = R(x,y,i);
    o = ORI(x,y,i);
    if (w <= minRidge) continue;
    k = -1;
    for (j = 0; j < cell.h; j++) {
      d = o - C(j,2);
      cx = C(j,0);
      cy = C(j,1);
      if (d < 0) d = -d;
      if (d > 90) d = 180 - d;
      d = oriFactor * d * d + (cx - x) * (cx - x) + (cy - y) * (cy - y);
      if (k < 0 || d < minD) {
        k = j;
        minD = d;
      }
    }
    cells[k].x += x * w;
    cells[k].y += y * w;
    cells[k].sina += sin(o * 2 / 180 * M_PI) * w;
    cells[k].cosa += cos(o * 2 / 180 * M_PI) * w;
    cells[k].w += w;
    cells[k].out += w * exp(-minD / 80);
  }
  if (neighbor > 0)
  for (i = 0; i < cell.h; i++)
  for (j = 0; j < cell.h; j++) {
    w = C(i,j+4);
    if (w == 0) continue;
    if (cells[j].w == 0) continue;
    cells[i].nw += w * neighbor * cells[j].w;
    cells[i].nx += w * neighbor * cells[j].x;
    cells[i].ny += w * neighbor * cells[j].y;
  }
  for (i = 0; i < cell.h; i++) {
    if (cells[i].w + cells[i].nw <= 0) continue;
    cells[i].x = (cells[i].x + cells[i].nx) / (cells[i].w + cells[i].nw);
    cells[i].y = (cells[i].y + cells[i].ny) / (cells[i].w + cells[i].nw);
    o = atan2(cells[i].sina, cells[i].cosa) / M_PI * 180;
    if (o < 0) o += 360;
    if (o > 360) o = 360;
    C(i,0) = cells[i].x;
    C(i,1) = cells[i].y;
    C(i,2) = o / 2;
    C(i,3) = cells[i].out;
  }
  v4pos.w = 2;
  v4pos.h = cell.h * cell.h;
  v4pos.n = 1;
  v4pos.classID = mxDOUBLE_CLASS;
  v4pos.dims = NULL;
  if (!GetOutputMatrix(nlhs, plhs, 1, &v4pos)) return;
  for (i = 0; i < cell.h; i++)
  for (j = 0; j < cell.h; j++) {
    C(i,j+4) = 0;
  }
  map = (int *)malloc(sizeof(int) * ridge.h * ridge.w);
  for (i = 0; i < ridge.n; i++) {
    for (y = 0; y < ridge.h; y++)
    for (x = 0; x < ridge.w; x++) {
      w = R(x,y,i);
      o = ORI(x,y,i);
      if (w <= minRidge) continue;
      k = -1;
      for (j = 0; j < cell.h; j++) {
        d = o - C(j,2);
        cx = C(j,0);
        cy = C(j,1);
        if (d < 0) d = -d;
        if (d > 90) d = 180 - d;
        d = oriFactor * d * d + (cx - x) * (cx - x) + (cy - y) * (cy - y);
        if (k < 0 || d < minD) {
          k = j;
          minD = d;
        }
      }
      M(x,y) = k;
      for (j = 0; j < 4; j++) {
        ax = adjx[j] + x;
        ay = adjy[j] + y;
        if (ax < 0 || ay < 0 || ax >= ridge.w || ay >= ridge.h) continue;
        if (R(ax,ay,i) <= minRidge) continue;
        ak = M(ax,ay);
        if (ak == k) continue;
        w += R(ax,ay,i);
        C(k,ak+4) += w;
        C(ak,k+4) += w;
        V4P(k,ak,0) += w * (x + ax) / 2;
        V4P(k,ak,1) += w * (y + ay) / 2;
        V4P(ak,k,0) += w * (x + ax) / 2;
        V4P(ak,k,1) += w * (y + ay) / 2;
      }
    }
  }
  for (i = 0; i < cell.h; i++)
  for (j = 0; j < cell.h; j++) {
    if (C(i,j+4) <= 0) continue;
    V4P(i,j,0) /= C(i,j+4);
    V4P(i,j,1) /= C(i,j+4);
  }
  free(map);
}

