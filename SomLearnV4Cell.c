#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

Matrix v4, cell;
double oriFactor, neighbor;

#define MAX_CELLS 1000
#define C(r,c) (((double*)(cell.data))[(r)+(c)*cell.h])
#define V(r,c) (((double*)(v4.data))[(r)+(c)*v4.h])
#define DEGROUND(x) { if(x<0)x=-x; if(x>360)x-=360; if(x>180)x=360-x; }

struct _cell_t_ {
  double x, y, s1, c1, s2, c2, w, out, nx, ny, nw;
} cells[MAX_CELLS];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, j, k, swap;
  double x, y, a1, a2, w, cx, cy, d1, d2, d3, d4, d, minD, temp;
  if (!GetInOutMatrix(nrhs, prhs, 0, nlhs, plhs, 0, mxDOUBLE_CLASS, &cell)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &v4)) return;
  if (!GetInputValue(nrhs, prhs, 2, &oriFactor)) return;
  if (!GetInputValue(nrhs, prhs, 3, &neighbor)) return;
  for (i = 0; i < cell.h; i++) {
    cells[i].x = 0;
    cells[i].y = 0;
    cells[i].s1 = 0;
    cells[i].c1 = 0;
    cells[i].s2 = 0;
    cells[i].c2 = 0;
    cells[i].w = 0;
    cells[i].out = 0;
    cells[i].nx = 0;
    cells[i].ny = 0;
    cells[i].nw = 0;
  }
  for (i = 0; i < v4.h; i++) {
    x = V(i,0);
    y = V(i,1);
    a1 = V(i,2);
    a2 = V(i,3);
    w = V(i,4);
    k = -1;
    swap = 0;
    for (j = 0; j < cell.h; j++) {
      d1 = a1 - C(j,2);
      d2 = a2 - C(j,3);
      d3 = a1 - C(j,3);
      d4 = a2 - C(j,2);
      cx = C(j,0);
      cy = C(j,1);
      DEGROUND(d1);
      DEGROUND(d2);
      DEGROUND(d3);
      DEGROUND(d4);
      d1 = d1 * d1 + d2 * d2;
      d2 = d3 * d3 + d4 * d4;
      d = oriFactor * (d1 <= d2 ? d1 : d2) + (cx - x) * (cx - x) + (cy - y) * (cy - y);
      if (k < 0 || d < minD) {
        k = j;
        minD = d;
        swap = (d1 > d2);
      }
    }
    if (swap) {
      temp = a1;
      a1 = a2;
      a2 = temp;
    }
    cells[k].x += x * w;
    cells[k].y += y * w;
    cells[k].s1 += sin(a1 / 180 * M_PI) * w;
    cells[k].c1 += cos(a1 / 180 * M_PI) * w;
    cells[k].s2 += sin(a2 / 180 * M_PI) * w;
    cells[k].c2 += cos(a2 / 180 * M_PI) * w;
    cells[k].w += w;
    cells[k].out += w * exp(-minD / 240);
  }
  if (neighbor > 0)
  for (i = 0; i < cell.h; i++)
  for (j = 0; j < cell.h; j++) {
    w = C(i,j+5);
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
    a1 = atan2(cells[i].s1, cells[i].c1) / M_PI * 180;
    a2 = atan2(cells[i].s2, cells[i].c2) / M_PI * 180;
    C(i,0) = cells[i].x;
    C(i,1) = cells[i].y;
    C(i,2) = a1;
    C(i,3) = a2;
    C(i,4) = cells[i].out;
  }
}
