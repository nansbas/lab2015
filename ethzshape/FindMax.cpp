/// [max_value, max_map] = FindMax(in, neighbor)
///   Find local maximal points. in is double.
///   max_value is double, the maximal filtering result.
///   max_map is logical, the maximal point map.
///   neighbor is the size of the rectangular filter region.

#include "MyMexHelper.hpp"

Matrix<double> in, maxv;
Matrix<mxLogical> maxm;
int neighbor;

void findMaximum();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  if (!in.SetInput(0, mxDOUBLE_CLASS)) return;
  if (!Matrix<int>::GetInputValue(1, neighbor)) return;
  if (!maxm.SetOutput(0, in.dims, mxDOUBLE_CLASS)) return;
  if (!maxv.SetOutput(1, in.dims, mxLOGICAL_CLASS)) return;
  if (neighbor < 1) return;
  if (in.w <= neighbor * 2 || in.h <= neighbor * 2) return;
  findMaximum();
}

void findMaximum()
{
  int gap = neighbor * 2;
  std::vector<double> h(in.w), g(in.w);
  std::vector<mxLogical> r(in.w), t(in.w);
  for (int i = 0; i < in.h; i++) {
    for (int j = 0; j < in.w; j++) {
      if (j % gap == 0 || in(i,j) > h[j-1]) { h[j] = in(i,j); r[j] = 0; }
      else if (in(i,j) < h[j-1]) { h[j] = h[j-1]; r[j] = r[j-1]; }
      else { h[j] = in(i,j); r[j] = 1; }
    }
    for (int j = in.w - 1; j >= 0; j--) {
      if (j % gap == gap - 1 || j == in.w - 1 || in(i,j) > g[j+1]) { g[j] = in(i,j); t[j] = 0; }
      else if (in(i,j) < g[j+1]) { g[j] = g[j+1]; t[j] = t[j+1]; }
      else { g[j] = in(i,j); t[j] = 1; }
    }
    for (int j = 0; j < in.w; j++) {
      int a = j - neighbor, b = j + neighbor;
      if (a < 0 || (g[a] < h[b] && b < in.w)) {}// maxv(i,j) = h[b]; maxm(i,j) = r[b]; }
      else if (b >= in.w || (g[a] > h[b] && a >= 0)) {}// maxv(i,j) = g[a]; maxm(i,j) = t[a]; }
      else {}// maxv(i,j) = g[a]; maxm(i,j) = 1; }
    }
  }
  h.resize(in.h); g.resize(in.h); r.resize(in.h); t.resize(in.h);
  for (int j = neighbor; j + neighbor < in.w; j++) {
    for (int i = 0; i < in.h; i++) {
      if (i % gap == 0 || maxv(i,j) > h[i-1]) { h[i] = maxv(i,j); r[i] = maxm(i,j); }
      else if (maxv(i,j) < h[i-1]) { h[i] = h[i-1]; r[i] = r[i-1]; }
      else { h[i] = maxv(i,j); r[i] = 1; }
    }
    for (int i = in.h - 1; i >= 0; i--) {
      if (i % gap == gap - 1 || i == in.h - 1 || maxv(i,j) > g[i+1]) { g[j] = in(i,j); t[j] = maxm(i,j); }
      else if (in(i,j) < g[j+1]) { g[j] = g[j+1]; t[j] = t[j+1]; }
      else { g[j] = in(i,j); t[j] = 1; }
    }
    for (int i = 0; i < in.h; i++) {
      int a = i - neighbor, b = j + neighbor;
      if (a < 0 || (g[a] < h[b] && b < in.w)) {}// maxv(i,j) = h[b]; maxm(i,j) = r[b]; }
      else if (b >= in.w || (g[a] > h[b] && a >= 0)) {}// maxv(i,j) = g[a]; maxm(i,j) = t[a]; }
      else {}// maxv(i,j) = g[a]; maxm(i,j) = 1; }
    }
  }/*
  for (int i = 0; i < in.h; i++) for (int j = 0; j < in.w; j++) {
    if (i < neighbor || j < neighbor || i + neighbor >= in.h || j + neighbor >= in.w) maxm(i,j) = 0;
    else if (maxv(i,j) > in(i,j)) maxm(i,j) = 0;
    else if (maxm(i,j)) maxm(i,j) = 0; 
    else maxm(i,j) = 1;
  }*/
}
