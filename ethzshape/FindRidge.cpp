/// out = FindRidge(in, orientation, neighbor)
///   Find ridge pixels with orientation constraints.
///   orientation is defined as [0,180) degree, ridge goes along the orientation.
///   in, orientation should be double; out is logical.
///   neighbor is the number of neighbors compared in x- or y-direction when getting ridge.

#include "MyMexHelper.hpp"

Matrix<double> in;
Matrix<double> ori;
Matrix<mxLogical> out;
int neighbor;

void doNeighbor1();
void doNeighbor2();
void doNeighborAny();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  if (!in.SetInput(0, mxDOUBLE_CLASS)) return;
  if (!ori.SetInput(1, mxDOUBLE_CLASS)) return;
  if (!Matrix<int>::GetInputValue(2, neighbor)) return;
  if (!out.SetOutput(0, in.dims, mxLOGICAL_CLASS)) return;
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
    double in0 = in(y,x,i);
    double d = ori(y,x,i) - 90;
    if (d < 0) d = -d;
    if ((in0 > in(y,x+1,i) && in0 >= in(y,x-1,i) && d <= 45)
      || (in0 > in(y+1,x,i) && in0 >= in(y-1,x,i) && d >= 45)) {
      out(y,x,i) = 1;
    }
  }
}

void doNeighbor2() 
{
  int i, x, y;
  for (i = 0; i < in.n; i++)
  for (x = 2; x + 2 < in.w; x++)
  for (y = 2; y + 2 < in.h; y++) {
    double in0 = in(y,x,i);
    double d = ori(y,x,i) - 90;
    if (d < 0) d = -d;
    if ((in0 > in(y,x+2,i) && in0 > in(y,x+1,i) && in0 >= in(y,x-1,i) && in0 >= in(y,x-2,i) && d <= 45)
      || (in0 > in(y+2,x,i) && in0 > in(y+1,x,i) && in0 >= in(y-1,x,i) && in0 >= in(y-2,x,i) && d >= 45)) {
      out(y,x,i) = 1;
    }
  }
}

void doNeighborAny() 
{
  int i, x, y, d;
  for (i = 0; i < in.n; i++)
  for (x = 2; x + 2 < in.w; x++)
  for (y = 2; y + 2 < in.h; y++) {
    double in0 = in(y,x,i);
    int xMax = 1, yMax = 1;
    double od = ori(y,x,i) - 90;
    if (od < 0) od = -od;
    for (d = 1; d < neighbor + 1; d++) {
      if (in0 <= in(y,x+d,i) || in0 < in(y,x-d,i)) xMax = 0;
      if (in0 <= in(y+d,x,i) || in0 < in(y-d,x,i)) yMax = 0;
      if (!xMax && !yMax) break;
    }
    if ((xMax && od <= 45) || (yMax && od >= 45)) out(y,x,i) = 1;
  }
}
