#include <mex.h>
#include "MyMexHelper.h"

Matrix in, out, size;

#define MAX_OUT 1000
#define IN(x,y) (((double*)(in.data))[(y)+(x)*in.h])
#define OUT(r,c) (((double*)(out.data))[(r)+(c)*out.h])
#define S(i) (((double*)(size.data))[i])

struct _out_ {
  int x, y;
  double value;
} list[MAX_OUT];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int w, h, x, y, dx, dy, px, py, isMax, nMax, i;
  double v;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &in)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &size)) return;
  w = S(0) / 2;
  h = S(1) / 2;
  nMax = 0;
  for (x = 0; x < in.w; x++)
  for (y = 0; y < in.h; y++) {
    v = IN(x,y);
    if (x > 0 && v < IN(x-1,y)) continue;
    if (x > 0 && y > 0 && v < IN(x-1,y-1)) continue;
    if (x > 0 && y + 1 < in.h && v < IN(x-1,y+1)) continue;
    if (y > 0 && v < IN(x,y-1)) continue;
    if (x + 1 < in.w && v <= IN(x+1,y)) continue;
    if (x + 1 < in.w && y + 1 < in.h && v <= IN(x+1,y+1)) continue;
    if (x + 1 < in.w && y > 0 && v <= IN(x+1,y-1)) continue;
    if (y + 1 < in.h && v <= IN(x,y+1)) continue;
    isMax = 1;
    for (dx = -w; dx <= w; dx++)
    for (dy = -h; dy <= h; dy++) {
      px = x + dx;
      py = y + dy;
      if (px < 0 || py < 0 || px >= in.w || py >= in.h) continue;
      if (dx <= 1 && dx >= -1 && dy <= 1 && dy >= -1) continue;
      if (IN(px,py) > v) {
        isMax = 0;
        break;
      }
    }
    if (isMax) {
      list[nMax].x = x;
      list[nMax].y = y;
      list[nMax].value = v;
      nMax++;
    }
  }
  out.h = nMax;
  out.w = 4;
  out.n = 1;
  out.dims = NULL;
  out.classID = mxDOUBLE_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &out)) return;
  for (i = 0; i < nMax; i++) {
    OUT(i,0) = list[i].x;
    OUT(i,1) = list[i].y;
    OUT(i,2) = list[i].value;
  }
}
