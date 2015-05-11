#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

#define MAX_MODEL 1000

Matrix model, neighbor, input;
double oriFactor;

#define M(r,c) (((double*)(model.data))[(r)+(c)*model.h])
#define IN(r,c) (((double*)(input.data))[(r)+(c)*input.h])
#define N(r,c) (((double*)(neighbor.data))[(r)+(c)*neighbor.h])

struct _model_ {
  double x, y, sa1, ca1, sa2, ca2, weight, hit, nx, ny, nweight;
} newModel[MAX_MODEL];

void learnSOM();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!GetInOutMatrix(nrhs, prhs, 0, nlhs, plhs, 0, mxDOUBLE_CLASS, &model)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &input)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &neighbor)) return;
  if (!GetInputValue(nrhs, prhs, 3, &oriFactor)) return;
  learnSOM();
}

void learnSOM()
{
  int i, j, reverse, minj;
  double ix, iy, io1, io2, istr, mx, my, mo1, mo2, do11, do22, do12, do21, mindiff, diff, temp, w, nw;
  for (i = 0; i < model.h; i++) {
    newModel[i].x = 0;
    newModel[i].y = 0;
    newModel[i].sa1 = 0;
    newModel[i].sa2 = 0;
    newModel[i].ca1 = 0;
    newModel[i].ca2 = 0;
    newModel[i].weight = 0;
    newModel[i].hit = 0;
    newModel[i].nx = 0;
    newModel[i].ny = 0;
    newModel[i].nweight = 0;
  }
  for (i = 0; i < input.h; i++) {
    ix = IN(i,0);
    iy = IN(i,1);
    io1 = IN(i,2);
    io2 = IN(i,3);
    istr = IN(i,4);
    minj = -1;
    for (j = 0; j < model.h; j++) {
      mx = M(j,0);
      my = M(j,1);
      mo1 = M(j,2);
      mo2 = M(j,3);
      do11 = io1 > mo1 ? io1 - mo1 : mo1 - io1;
      do22 = io2 > mo2 ? io2 - mo2 : mo2 - io2;
      do12 = io1 > mo2 ? io1 - mo2 : mo2 - io1;
      do21 = io2 > mo1 ? io2 - mo1 : mo1 - io2;
      if (do11 > 180) do11 = 360 - do11;
      if (do22 > 180) do22 = 360 - do22;
      if (do12 > 180) do12 = 360 - do12;
      if (do21 > 180) do21 = 360 - do21;
      do11 = do11 * do11 + do22 * do22;
      do12 = do12 * do12 + do21 * do21;
      diff = (ix - mx) * (ix - mx) + (iy - my) * (iy - my) + (do11 <= do12 ? do11 : do12) * oriFactor;
      if (minj < 0 || diff < mindiff) {
        minj = j;
        reverse = do11 > do12;
        mindiff = diff;
      }
    }
    if (minj >= 0 && minj < model.h) {
      if (reverse) {
        temp = io1;
        io1 = io2;
        io2 = temp;
      }
      w = istr * exp(- mindiff * 70); // exp(-0.01*70) ~= 0.5
      newModel[minj].x += ix * w;
      newModel[minj].y += iy * w;
      newModel[minj].sa1 += sin(io1 / 180 * M_PI) * w;
      newModel[minj].ca1 += cos(io1 / 180 * M_PI) * w;
      newModel[minj].sa2 += sin(io2 / 180 * M_PI) * w;
      newModel[minj].ca2 += cos(io2 / 180 * M_PI) * w;
      newModel[minj].weight += w;
      newModel[minj].hit = newModel[minj].hit + 1;
    }
  }
  for (i = 0; i < model.h; i++) {
    if (newModel[i].weight <= 0) {
      newModel[i].x = M(i,0);
      newModel[i].y = M(i,1);
      newModel[i].sa1 = sin(M(i,2) / 180 * M_PI) * M(i,4);
      newModel[i].ca1 = cos(M(i,2) / 180 * M_PI) * M(i,4);
      newModel[i].sa2 = sin(M(i,3) / 180 * M_PI) * M(i,5);
      newModel[i].ca2 = cos(M(i,3) / 180 * M_PI) * M(i,5);
    } else {
      newModel[i].x /= newModel[i].weight;
      newModel[i].y /= newModel[i].weight;
      newModel[i].sa1 /= newModel[i].weight;
      newModel[i].ca1 /= newModel[i].weight;
      newModel[i].sa2 /= newModel[i].weight;
      newModel[i].ca2 /= newModel[i].weight;
    }
  }
  for (i = 0; i < model.h; i++) {
    for (j = 0; j < model.h; j++) {
      if (i == j) continue;
      nw = newModel[j].weight * N(i,j);
      newModel[i].nx += newModel[j].x * nw;
      newModel[i].ny += newModel[j].y * nw;
      newModel[i].nweight += nw;
    }
  }
  for (i = 0; i < model.h; i++) {
    nw = newModel[i].weight + newModel[i].nweight;
    if (nw > 0) {
      M(i,0) = (newModel[i].x * newModel[i].weight + newModel[i].nx) / nw;
      M(i,1) = (newModel[i].y * newModel[i].weight + newModel[i].ny) / nw; 
    }
    M(i,2) = atan2(newModel[i].sa1, newModel[i].ca1) / M_PI * 180;
    M(i,3) = atan2(newModel[i].sa2, newModel[i].ca2) / M_PI * 180;
    M(i,4) = sqrt(newModel[i].sa1 * newModel[i].sa1 + newModel[i].ca1 * newModel[i].ca1);
    M(i,5) = sqrt(newModel[i].sa2 * newModel[i].sa2 + newModel[i].ca2 * newModel[i].ca2);
    M(i,6) = newModel[i].weight;
    M(i,7) = newModel[i].hit;
  }
} 
