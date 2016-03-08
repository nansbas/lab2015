#include <mex.h>
#include "MyMexHelper.h"

Matrix in, ori, out;
double neighbor;

#define IN(x,y,z) (((double*)(in.data))[(y)+(x)*in.h+(z)*in.h*in.w])
#define ORI(x,y,z) (((double*)(ori.data))[(y)+(x)*in.h+(z)*in.h*in.w])
#define OUT(x,y,z) (((mxLogical*)(out.data))[(y)+(x)*in.h+(z)*in.h*in.w])

void doNeighbor1();
void doNeighbor2();
void doNeighborAny();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &in)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputValue(nrhs, prhs, 2, &neighbor)) return;
  out = in;
  out.classID = mxLOGICAL_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &out)) return;
  if (neighbor < 1) return;
  if (neighbor < 2) { doNeighbor1(); return; }
  if (neighbor < 3) { doNeighbor2(); return; }
  doNeighborAny();
}

void doNeighbor1() 
{
  int i, x, y;
  for (i = 0; i < in.n; i++)
  for (x = 1; x + 1 < in.w; x++)
  for (y = 1; y + 1 < in.h; y++) {
    double this = IN(x,y,i);
    double d = ORI(x,y,i) - 90;
    if (d < 0) d = -d;
    if ((this > IN(x+1,y,i) && this >= IN(x-1,y,i) && d <= 45)
      || (this > IN(x,y+1,i) && this >= IN(x,y-1,i) && d >= 45)) {
      OUT(x,y,i) = 1;
    }
  }
}

void doNeighbor2() 
{
  int i, x, y;
  for (i = 0; i < in.n; i++)
  for (x = 2; x + 2 < in.w; x++)
  for (y = 2; y + 2 < in.h; y++) {
    double this = IN(x,y,i);
    double d = ORI(x,y,i) - 90;
    if (d < 0) d = -d;
    if ((this > IN(x+2,y,i) && this > IN(x+1,y,i) && this >= IN(x-1,y,i) && this >= IN(x-2,y,i) && d <= 45)
      || (this > IN(x,y+2,i) && this > IN(x,y+1,i) && this >= IN(x,y-1,i) && this >= IN(x,y-2,i) && d >= 45)) {
      OUT(x,y,i) = 1;
    }
  }
}

void doNeighborAny() 
{
  int i, x, y, d;
  for (i = 0; i < in.n; i++)
  for (x = 2; x + 2 < in.w; x++)
  for (y = 2; y + 2 < in.h; y++) {
    double this = IN(x,y,i);
    int xMax = 1, yMax = 1;
    double od = ORI(x,y,i) - 90;
    if (od < 0) od = -od;
    for (d = 1; d < neighbor + 1; d++) {
      if (this <= IN(x+d,y,i) || this < IN(x-d,y,i)) xMax = 0;
      if (this <= IN(x,y+d,i) || this < IN(x,y-d,i)) yMax = 0;
      if (!xMax && !yMax) break;
    }
    if ((xMax && od <= 45) || (yMax && od >= 45)) OUT(x,y,i) = 1;
  }
}
