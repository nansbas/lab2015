#include <mex.h>
#include <math.h>
#include "MyMexHelper.h"

Matrix ridge, strength, ori, suppress;
double dist;

#define R(x,y) (((mxLogical*)(ridge.data))[(y)+(x)*ridge.h])
#define ST(x,y) (((double*)(strength.data))[(y)+(x)*ridge.h])
#define ORI(x,y) (((double*)(ori.data))[(y)+(x)*ridge.h])
#define SUP(x,y) (((double*)(suppress.data))[(y)+(x)*ridge.h])

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int x, y, x1, y1, x2, y2;
  if (!GetInputMatrix(nrhs, prhs, 0, mxLOGICAL_CLASS, &ridge)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &strength)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputValue(nrhs, prhs, 3, &dist)) return;
  suppress = ridge;
  suppress.classID = mxDOUBLE_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &suppress)) return;
  for (x = 0; x < ridge.w; x++)
  for (y = 0; y < ridge.h; y++) {
    double a, ca, sa;
    a = ORI(x,y);
    ca = cos(a) * dist;
    sa = sin(a) * dist;
    if (!R(x,y)) continue;
    x1 = x - sa;
    y1 = y + ca;
    x2 = x + sa;
    y2 = y - ca;
    if (x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0 || x1 >= ridge.w || x2 >= ridge.w || y1 >= ridge.h || y2 >= ridge.h) continue;
    SUP(x,y) = ST(x1,y1) * ST(x2,y2);
  }
}
