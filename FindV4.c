#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "MyMexHelper.h"

#define MAX_LENGTH 3000
#define MAX_LINE 4000

Matrix cell, line, v4out, lmap;
double width, height, v4radius, minLength, maxOriDiff;

#define L(r,c) (((double*)(line.data))[(r)+(c)*line.h])
#define V4(x,y) (((double*)(v4out.data))[(y)+(x)*v4out.h])
#define MAP(x,y) (((int*)(lmap.data))[(y)+(x)*lmap.h])

struct _lines_ 
{
  int count;
} lines;

void doLine();

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;
  mxArray * mLine;
  if (!GetInputMatrix(nrhs, prhs, 0, mxCELL_CLASS, &cell)) return;
  if (!GetInputValue(nrhs, prhs, 1, &width)) return;
  if (!GetInputValue(nrhs, prhs, 2, &height)) return;
  if (!GetInputValue(nrhs, prhs, 3, &v4radius)) return;
  if (!GetInputValue(nrhs, prhs, 4, &minLength)) return;
  if (!GetInputValue(nrhs, prhs, 5, &maxOriDiff)) return;
  lmap.h = v4out.h = height;
  lmap.w = v4out.w = width;
  lmap.n = v4out.n = 1;
  lmap.dims = v4out.dims = NULL;
  v4out.classID = mxDOUBLE_CLASS;
  lmap.classID = mxINT32_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &v4out)) return;
  if (!GetOutputMatrix(nlhs, plhs, 1, &lmap)) return;
  lines.count = 0;
  for (i = 0; i < cell.h * cell.w; i++) {
    mLine = mxGetCell(prhs[0], i);
    if (!GetMatrix(mLine, mxDOUBLE_CLASS, &line)) continue;
    if (line.h > MAX_LENGTH) continue;
    doLine();
  }
}

struct _line_ 
{
  int x, y;
  double ori, oriL, oriR, v4, sina, cosa;
} thisLine[MAX_LENGTH];

double avgLineOri(int start, int length) 
{
  double avgSin = 0, avgCos = 0, ori;
  int i;
  for (i = start; i < start + length; i++) {
    avgSin += thisLine[i].sina;
    avgCos += thisLine[i].cosa;
  }
  ori = atan2(avgSin, avgCos) / M_PI * 90;
  if (ori < 0) ori += 180;
  return ori;
}

void saveLine(int start, int length, double ori)
{
  int i;
  lines.count++;
  for (i = start; i < start + length; i++) {
    MAP(thisLine[i].x, thisLine[i].y) = lines.count;
  }
}

void splitLine(int start, int length)
{
  double avgOri, se = 0, d;
  int i, j;
  avgOri = avgLineOri(start, length);
  if (length < 2 * minLength) {
    saveLine(start, length, avgOri);
    return;
  }
  for (i = start; i < start + length; i++) {
    d = thisLine[i].ori - avgOri;
    if (d < 0) d = -d;
    if (d > 90) d = 180 - d;
    se += d * d;
  }
  se /= length;
  if (se <= maxOriDiff * maxOriDiff) {
    saveLine(start, length, avgOri);
    return;
  }
  for (i = j = minLength - 1; i + minLength < length; i++) {
    if (thisLine[i + start].v4 > thisLine[j + start].v4) j = i;
  }
  splitLine(start, j + 1);
  splitLine(start + j + 1, length - j - 1);
}

void doLine()
{
  int v4r = v4radius + 0.5, i, j;
  double d, d1, d2;
  for (i = 0; i < line.h; i++) {
    thisLine[i].x = L(i,0);
    thisLine[i].y = L(i,1);
    thisLine[i].ori = L(i,3);
    thisLine[i].v4 = 0;
    thisLine[i].sina = sin(thisLine[i].ori / 90 * M_PI);
    thisLine[i].cosa = cos(thisLine[i].ori / 90 * M_PI);
  }
  for (i = v4r - 1; i + v4r < line.h; i++) {
    thisLine[i].oriL = avgLineOri(i - v4r + 1, v4r);
    thisLine[i].oriR = avgLineOri(i + 1, v4r);
    for (j = 0; j < v4r; j++) {
      d = thisLine[i].oriL - thisLine[i].oriR;
      d1 = thisLine[i - j].ori - thisLine[i].oriL;
      d2 = thisLine[i + j + 1].ori - thisLine[i].oriR;
      if (d < 0) d = -d;
      if (d > 90) d = 180 - d;
      if (d1 < 0) d1 = -d1; 
      if (d1 > 90) d1 = 180 - d1;
      if (d2 < 0) d2 = -d2;
      if (d2 > 90) d2 = 180 - d2;
      d -= d1 - d2;
      if (d < 0) d = 0;
      thisLine[i].v4 += d;
    }
  }
  for (i = 0; i < line.h; i++) {
    V4(thisLine[i].x, thisLine[i].y) = thisLine[i].v4;
  }
  splitLine(0, line.h);
}
