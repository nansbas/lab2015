#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

Matrix v4, cell, somSize, rects, out, map;
double oriFactor, neighbor;

#define MAX_CELLS 1000
#define C(r,c) (((double*)(cell.data))[(r)+(c)*cell.h])
#define V(r,c) (((double*)(v4.data))[(r)+(c)*v4.h])
#define SR(i) (((double*)(somSize.data))[i])
#define RT(r,c) (((double*)(rects.data))[(r)+(c)*rects.h])
#define O(r,c) (((double*)(out.data))[(r)+(c)*out.h])
#define M(r,c) (((int*)(map.data))[(r)+(c)*map.h])
#define DEGROUND(x) { if(x<0)x=-x; if(x>360)x-=360; if(x>180)x=360-x; }

struct _cell_ {
  int idx;
  double strength, dist;
} cells[MAX_CELLS];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, j, k, idx;
  double x, y, a1, a2, strength, rtx1, rty1, rtW, rtH, d1, d2, d3, d4, d, cx, cy, somW, somH;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &cell)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &v4)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &somSize)) return;
  if (!GetInputMatrix(nrhs, prhs, 3, mxDOUBLE_CLASS, &rects)) return;
  if (!GetInputValue(nrhs, prhs, 4, &oriFactor)) return;
  out.h = cell.h;
  out.w = rects.h;
  out.n = 1;
  out.dims = NULL;
  map = out;
  out.classID = mxDOUBLE_CLASS;
  map.classID = mxINT32_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &out)) return;
  if (!GetOutputMatrix(nlhs, plhs, 1, &map)) return;
  somW = SR(0);
  somH = SR(1);
  for (i = 0; i < rects.h; i++) {
    rtx1 = RT(i,0); rty1 = RT(i,1); 
    rtW = RT(i,2) - rtx1; 
    rtH = RT(i,3) - rty1;
    for (j = 0; j < cell.h; j++) cells[j].idx = -1;
    for (j = 0; j < v4.h; j++) {
      x = (V(j,0) - rtx1) / rtW;
      y = (V(j,1) - rty1) / rtH;
      a1 = V(j,2);
      a2 = V(j,3);
      strength = V(j,4);
      idx = j;
      if (!(x >= 0 && x <= 1 && y >= 0 && y <= 1)) continue;
      x *= somW;
      y *= somH;
      for (k = 0; k < cell.h; k++) {
        cx = C(k,0);
        cy = C(k,1);
        d1 = a1 - C(k,2);
        d2 = a2 - C(k,3);
        d3 = a1 - C(k,3);
        d4 = a2 - C(k,2);
        DEGROUND(d1);
        DEGROUND(d2);
        DEGROUND(d3);
        DEGROUND(d4);
        d1 = d1 * d1 + d2 * d2;
        d2 = d3 * d3 + d4 * d4;
        d = oriFactor * (d1 <= d2 ? d1 : d2) + (cx - x) * (cx - x) + (cy - y) * (cy - y);
        if (cells[k].idx < 0 || d < cells[k].dist) {
          cells[k].idx = idx;
          cells[k].dist = d;
          cells[k].strength = strength;
        }
      }
    }
    for (j = 0; j < cell.h; j++) {
      O(j,i) = 0;
      if (cells[j].idx >= 0 && cells[j].strength > 1/240) {
        O(j,i) = exp(-cells[j].dist / 240) * log(cells[j].strength * 240) / log(2400);
      }
      M(j,i) = cells[j].idx;
    }
  }
}
