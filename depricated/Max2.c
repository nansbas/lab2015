#include <mex.h>
#include <stdlib.h>
#include "MyMexHelper.h"

Matrix in, outmax, outidx;
char *cUse;
int *rMax;

#define IN(r,c) (((double*)(in.data))[(r)+(c)*in.h])
#define MAX(i) (((double*)(outmax.data))[i])
#define IDX(i) (((int*)(outidx.data))[i])

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int r, c, midx, midx2;
  double mval, mval2;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &in)) return;
  cUse = (char*)calloc(in.w, sizeof(char));
  rMax = (int*)malloc(in.h * sizeof(int));
  for (r = 0; r < in.h; r++) {
    midx = -1;
    midx2 = -1;
    for (c = 0; c < in.w; c++) {
      if ((midx < 0 || IN(r,c) > mval) && !cUse[c]) {
        midx = c;
        mval = IN(r,c);
      }
      if (midx2 < 0 || IN(r,c) > mval2) {
        midx2 = c;
        mval2 = IN(r,c);
      }
    }
    if (midx >= 0) {
      rMax[r] = midx;
      cUse[midx] = 1;
      if (midx * 2 < in.w) {
        cUse[midx + in.w/2] = 1;
      } else {
        cUse[midx - in.w/2] = 1;
      } 
    } else {
      rMax[r] = midx2;
    }
  }
  outmax.h = in.h;
  outmax.w = 1;
  outmax.n = 1;
  outmax.dims = NULL;
  outmax.classID = mxDOUBLE_CLASS;
  outidx = outmax;
  outidx.classID = mxINT32_CLASS;
  if (GetOutputMatrix(nlhs, plhs, 0, &outmax)) {
    int setIdx = GetOutputMatrix(nlhs, plhs, 1, &outidx);
    for (r = 0; r < in.h; r++) {
      if (rMax[r] >= 0) MAX(r) = IN(r,rMax[r]);
      if (setIdx) IDX(r) = rMax[r] + 1;
    }
  }
  free(cUse);
  free(rMax);
}