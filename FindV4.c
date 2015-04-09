#include <mex.h>
#include "MyMexHelper.h"

#define MAX_LENGTH 2000

Matrix cell, line, out;
double minLength;

#define L(r,c) (((double*)(line.data))[(r)+(c)*line.h])

struct _line_ {
  double similar;
} lineData[MAX_LENGTH];

void doLine();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;
  mxArray * mLine;
  if (!GetInputMatrix(nrhs, prhs, 0, mxCELL_CLASS, &cell)) return;
  if (!GetInputValue(nrhs, prhs, 1, &minLength)) return;
  for (i = 0; i < cell.h * cell.w; i++) {
    mLine = mxGetCell(cell, i);
    if (!GetMatrix(mLine, mxDOUBLE_CLASS, &line)) continue;
    if (line.h > MAX_LENGTH) continue;
    doLine();
  }
}

void doLine()
{
  int i, j, k, minHalf = minLength / 2;
  double d1, d2;
  for (i = 0; i < line.h; i++) lineData[i].similar = 0;
  for (i = minHalf * 2; i + minHalf * 2 < line.h; i++) {
    for (j = -minHalf; j <= minHalf; j++) {
      if (j == 0) continue;
      k = i + j;
      d1 = L(i - minHalf, 3) - L(k - minHalf, 3);
      d2 = L(i + minHalf, 3) - L(k + minHalf, 3);
      if (d1 < 0) d1 = -d1;
      if (d1 > 90) d1 = 180 - d1;
      if (d2 < 0) d2 = -d2;
      if (d2 > 90) d2 = 180 - d2;
    }
  }
}