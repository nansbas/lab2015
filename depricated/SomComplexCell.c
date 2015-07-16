#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

Matrix ridge, ori, cell, somSize, rects, out, map, mapCellArray;
double minRidge, oriFactor;

#define MAX_CELLS 1000
#define C(r,c) (((double*)(cell.data))[(r)+(c)*cell.h])
#define R(x,y) (((double*)(ridge.data))[(y)+(x)*ridge.h])
#define ORI(x,y) (((double*)(ori.data))[(y)+(x)*ridge.h])
#define SR(i) (((double*)(somSize.data))[i])
#define RT(r,c) (((double*)(rects.data))[(r)+(c)*rects.h])
#define O(r,c) (((double*)(out.data))[(r)+(c)*out.h])
#define M(x,y) (((int*)(map.data))[(y)+(x)*map.h])
#define DEGROUND(x) { if(x<0)x=-x; if(x>180)x-=180; if(x>90)x=180-x; }

struct _cell_t_ {
  double value;
} cells[MAX_CELLS];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, x, y, j, k, rtx1, rtx2, rty1, rty2;
  double w, o, dx, dy, rtW, rtH, somH, somW, cx, cy, d, minD, r;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &cell)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &ridge)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputMatrix(nrhs, prhs, 3, mxDOUBLE_CLASS, &somSize)) return;
  if (!GetInputMatrix(nrhs, prhs, 4, mxDOUBLE_CLASS, &rects)) return;
  if (!GetInputValue(nrhs, prhs, 5, &minRidge)) return;
  if (!GetInputValue(nrhs, prhs, 6, &oriFactor)) return;
  out.h = cell.h;
  out.w = rects.h;
  out.n = 1;
  out.dims = NULL;
  out.classID = mxDOUBLE_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &out)) return;
  mapCellArray.h = 1;
  mapCellArray.w = rects.h;
  mapCellArray.n = 1;
  mapCellArray.dims = NULL;
  mapCellArray.classID = mxCELL_CLASS;
  GetOutputMatrix(nlhs, plhs, 1, &mapCellArray);
  somW = SR(0);
  somH = SR(1);
  for (i = 0; i < rects.h; i++) {
    rtx1 = RT(i,0); rty1 = RT(i,1); rtx2 = RT(i,2); rty2 = RT(i,3);
    rtW = somW / (rtx2 - rtx1);
    rtH = somH / (rty2 - rty1);
    if (mapCellArray.data) {
      map.h = rty2 - rty1 + 1;
      map.w = rtx2 - rtx1 + 1;
      map.n = 1;
      map.dims = NULL;
      map.classID = mxINT32_CLASS;
      mxSetCell((mxArray *)(mapCellArray.data), i, CreateMatrix(&map));
    }
    for (j = 0; j < cell.h; j++) cells[j].value = 0;
    for (x = rtx1; x <= rtx2; x++)
    for (y = rty1; y <= rty2; y++) {
      if (x < 0 || y < 0 || x >= ridge.w || y >= ridge.h) continue;
      w = R(x,y);
      if (w <= minRidge || w < 1/240) continue;
      o = ORI(x,y);
      dx = (x - rtx1) * rtW;
      dy = (y - rty1) * rtH;
      k = -1;
      for (j = 0; j < cell.h; j++) {
        cx = C(j,0);
        cy = C(j,1);
        d = o - C(j,2);
        DEGROUND(d);
        d = oriFactor * d * d + (cx - dx) * (cx - dx) + (cy - dy) * (cy - dy);
        if (k < 0 || d < minD) {
          k = j;
          minD = d;
        }
      }
      if (mapCellArray.data) {
        M(x-rtx1,y-rty1) = k;
      }
      cells[k].value += exp(-minD / 80) * log(w * 240) / log(2400);
    }
    r = sqrt(rtH * rtW);
    for (j = 0; j < cell.h; j++) {
      O(j,i) = 2 / (exp(-cells[j].value * r / 3) + 1) - 1;
    }
  }
}
