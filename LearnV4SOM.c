#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

#define MAX_MODEL 1000

Matrix model, input;
double neighborFactor, oriRadius;

#define M(r,c) (((double*)(model.data))[(r)+(c)*model.h])
#define IN(r,c) (((double*)(input.data))[(r)+(c)*input.h])

struct _model_ {
  double x, y, sa1, ca1, sa2, ca2, weight;
} newModel[MAX_MODEL];

void learnSOM();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (!GetInOutMatrix(nrhs, prhs, 0, nlhs, plhs, 0, mxDOUBLE_CLASS, &model)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &input)) return;
  if (!GetInputValue(nrhs, prhs, 2, &neighborFactor)) return;
  if (!GetInputValue(nrhs, prhs, 3, &oriRadius)) return;
  oriRadius = oriRadius * oriRadius; // balance point where orientation and distance have equal effect.
  learnSOM();
}

void learnSOM() 
{
  int i, j, k, reverse;
  double minDist, dist, d1, d2, d3, d4, w, x, y, a1, a2, mx, my, ma1, ma2;
  for (i = 0; i < model.h; i++) {
    newModel[i].weight = 0;
    newModel[i].x = 0;
    newModel[i].y = 0;
    newModel[i].sa1 = 0;
    newModel[i].ca1 = 0;
    newModel[i].sa2 = 0;
    newModel[i].ca2 = 0;
  }
  for (i = 0; i < input.h; i++) {
    w = IN(i,0);
    x = IN(i,1);
    y = IN(i,2);
    a1 = IN(i,3);
    a2 = IN(i,4);
    k = -1;
    for (j = 0; j < model.h; j++) {
      mx = M(j,1);
      my = M(j,2);
      ma1 = M(j,3);
      ma2 = M(j,4);
      dist = (mx-x)*(mx-x) + (my-y)*(my-y);
      d1 = ma1 - a1;
      if (d1 < 0) d1 = -d1;
      if (d1 > M_PI) d1 = M_PI * 2 - d1;
      d2 = ma2 - a2;
      if (d2 < 0) d2 = -d2;
      if (d2 > M_PI) d2 = M_PI * 2 - d2;
      d3 = ma1 - a2;
      if (d3 < 0) d3 = -d3;
      if (d3 > M_PI) d3 = M_PI * 2 - d3;
      d4 = ma2 - a1;
      if (d4 < 0) d4 = -d4;
      if (d4 > M_PI) d4 = M_PI * 2 - d4;
      d1 = d1*d1 + d2*d2;
      d2 = d3*d3 + d4*d4;
      d3 = (d1 > d2 ? d2 : d1)/M_PI/M_PI/2*oriRadius;
      dist = (dist * dist + d3) / (dist + oriRadius);
      if (k < 0 || dist < minDist) {
        minDist = dist;
        k = j;
        reverse = (d1 > d2);
      }
    }
    if (reverse) {
      d4 = a1;
      a1 = a2;
      a2 = d4;
    }
    newModel[k].x += w * x;
    newModel[k].y += w * y;
    newModel[k].sa1 += w * sin(a1);
    newModel[k].ca1 += w * cos(a1);
    newModel[k].sa2 += w * sin(a2);
    newModel[k].ca2 += w * cos(a2);
    newModel[k].weight += w;
  }
  for (i = 0; i < model.h; i++) {
    M(i,0) = newModel[i].weight;
    newModel[i].x /= newModel[i].weight;
    newModel[i].y /= newModel[i].weight;
    M(i,3) = atan2(newModel[i].sa1, newModel[i].ca1);
    M(i,4) = atan2(newModel[i].sa2, newModel[i].ca2);
  }
  for (i = 0; i < model.h; i++) {
    j = ((i > 0) ? (i - 1) : (model.h - 1));
    k = ((i + 1 < model.h) ? (i + 1) : 0);
    M(i,1) = (newModel[i].x 
      + newModel[j].x * neighborFactor
      + newModel[k].x * neighborFactor) / (1 + neighborFactor * 2);
    M(i,2) = (newModel[i].y 
      + newModel[j].y * neighborFactor
      + newModel[k].y * neighborFactor) / (1 + neighborFactor * 2);
  }
}