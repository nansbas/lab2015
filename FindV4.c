#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <stdlib.h>
#include "MyMexHelper.h"

#define MAX_LENGTH 3000
#define MAX_LINE 4000
#define MAX_V4FEATURE 20000

Matrix cell, line, v4out, lmap, v4f;
double width, height, v4radius, minLength, maxOriDiff, maxGap;
char * adjMatrix;

#define L(r,c) (((double*)(line.data))[(r)+(c)*line.h])
#define V4(x,y) (((double*)(v4out.data))[(y)+(x)*v4out.h])
#define MAP(x,y) (((int*)(lmap.data))[(y)+(x)*lmap.h])
#define V4F(r,c) (((double*)(v4f.data))[(r)+(c)*v4f.h])
#define ADJ(i,j) (adjMatrix[(i)+(j)*lines.count])
#define DIST(x1,y1,x2,y2) (((x1)-(x2))*((x1)-(x2))+((y1)-(y2))*((y1)-(y2)))

struct _lines_ 
{
  struct _line2_ 
  {
    int x1, y1, x2, y2, cx, cy;
    double ori, strength, length;
  } l[MAX_LINE];
  int count;
} lines;

struct _v4_features_
{
  struct _v4_feature_ {
    int line1, line2, x, y;
    double ori1, ori2, strength;
  } f[MAX_V4FEATURE];
  int count;
} v4features;

void doLine();
void buildGraph();

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
  if (!GetInputValue(nrhs, prhs, 6, &maxGap)) return;
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
  v4features.count = 0;
  adjMatrix = (char *)calloc(sizeof(char), lines.count * lines.count);
  buildGraph();
  free(adjMatrix);
  v4f.h = v4features.count;
  v4f.w = 7;
  v4f.n = 1;
  v4f.dims = NULL;
  v4f.classID = mxDOUBLE_CLASS;
  if (GetOutputMatrix(nlhs, plhs, 2, &v4f)) {
    for (i = 0; i < v4features.count; i++) {
      V4F(i,0) = v4features.f[i].line1;
      V4F(i,1) = v4features.f[i].line2;
      V4F(i,2) = v4features.f[i].x;
      V4F(i,3) = v4features.f[i].y;
      V4F(i,4) = v4features.f[i].ori1;
      V4F(i,5) = v4features.f[i].ori2;
      V4F(i,6) = v4features.f[i].strength;
    }
  }
}

void recordV4(int i, int j)
{
  double d11, d12, d21, d22, cx, cy, cx1, cy1, cx2, cy2, ori1, ori2, d1, d2;
  if (v4features.count >= MAX_V4FEATURE) return;
  ADJ(i,j) = 1;
  ADJ(j,i) = 1;
  if (i == j) {
    cx = lines.l[i].cx;
    cy = lines.l[i].cy;
    cx1 = lines.l[i].x1;
    cy1 = lines.l[i].y1;
    cx2 = lines.l[i].x2;
    cy2 = lines.l[i].y2;
  } else {
    cx1 = lines.l[i].cx;
    cy1 = lines.l[i].cy;
    cx2 = lines.l[j].cx;
    cy2 = lines.l[j].cy;
    d11 = DIST(lines.l[i].x1, lines.l[i].y1, lines.l[j].x1, lines.l[j].y1);
    d12 = DIST(lines.l[i].x1, lines.l[i].y1, lines.l[j].x2, lines.l[j].y2);
    d21 = DIST(lines.l[i].x2, lines.l[i].y2, lines.l[j].x1, lines.l[j].y1);
    d22 = DIST(lines.l[i].x2, lines.l[i].y2, lines.l[j].x2, lines.l[j].y2);
    if (d11 <= d12 && d11 <= d21 && d11 <= d22) {
      cx = (lines.l[i].x1 + lines.l[j].x1) / 2;
      cy = (lines.l[i].y1 + lines.l[j].y1) / 2;
    } else if (d12 <= d11 && d12 <= d21 && d12 <= d22) {
      cx = (lines.l[i].x1 + lines.l[j].x2) / 2;
      cy = (lines.l[i].y1 + lines.l[j].y2) / 2;
    } else if (d21 <= d11 && d21 <= d12 && d21 <= d22) {
      cx = (lines.l[i].x2 + lines.l[j].x1) / 2;
      cy = (lines.l[i].y2 + lines.l[j].y1) / 2;
    } else {
      cx = (lines.l[i].x2 + lines.l[j].x2) / 2;
      cy = (lines.l[i].y2 + lines.l[j].y2) / 2;
    }
  }
  cx1 -= cx;
  cx2 -= cx;
  cy1 -= cy;
  cy2 -= cy;
  ori1 = -lines.l[i].ori;
  ori2 = -lines.l[j].ori;
  d1 = atan2(cy1, cx1) / M_PI * 180 - ori1;
  if (d1 < 0) d1 = -d1;
  if (d1 > 180) d1 = 360 - d1;
  if (d1 > 90) ori1 += 180;
  d2 = atan2(cy2, cx2) / M_PI * 180 - ori2;
  if (d2 < 0) d2 = -d2;
  if (d2 > 180) d2 = 360 - d2;
  if (d2 > 90) ori2 += 180;
  v4features.f[v4features.count].line1 = i;
  v4features.f[v4features.count].line2 = j;
  v4features.f[v4features.count].x = cx;
  v4features.f[v4features.count].y = cy;
  v4features.f[v4features.count].ori1 = ori1;
  v4features.f[v4features.count].ori2 = ori2;
  v4features.f[v4features.count].strength = sqrt(lines.l[i].strength * lines.l[j].strength);
  v4features.count++; 
}

void buildGraph()
{
  int i, j1, j2, dx, dy, iMaxGap = maxGap + 0.5, px, py, iWidth = width + 0.5, iHeight = height + 0.5;
  for (i = 0; i < lines.count; i++) {
    for (dx = -iMaxGap; dx <= iMaxGap; dx++)
    for (dy = -iMaxGap; dy <= iMaxGap; dy++) {
      if (dx == 0 && dy == 0) continue;
      if (dx * dx + dy * dy > iMaxGap * iMaxGap) continue;
      px = lines.l[i].x1 + dx;
      py = lines.l[i].y1 + dy;
      if (px >= 0 && py >= 0 && px < iWidth && py < iHeight) {
        j1 = MAP(px, py) - 1;
        if (j1 >= 0 && !ADJ(i,j1) && !ADJ(j1,i)) {
          recordV4(i, j1);
        }
      }
      px = lines.l[i].x2 + dx;
      py = lines.l[i].y2 + dy;
      if (px >= 0 && py >= 0 && px < iWidth && py < iHeight) {
        j2 = MAP(px, py) - 1;
        if (j2 >= 0 && !ADJ(i,j2) && !ADJ(j2,i)) {
          recordV4(i, j2);
        }
      }
    }
    if (lines.l[i].length >= minLength * 4) {
      recordV4(i, i);
    }
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
  int i, cx = 0, cy = 0;
  double strength = 0;
  lines.count++;
  for (i = start; i < start + length; i++) {
    MAP(thisLine[i].x, thisLine[i].y) = lines.count;
    cx += thisLine[i].x;
    cy += thisLine[i].y;
    strength += L(i,2);
  }
  if (lines.count > MAX_LINE) return;
  lines.l[lines.count - 1].x1 = thisLine[start].x;
  lines.l[lines.count - 1].y1 = thisLine[start].y;
  lines.l[lines.count - 1].x2 = thisLine[start + length - 1].x;
  lines.l[lines.count - 1].y2 = thisLine[start + length - 1].y;
  lines.l[lines.count - 1].ori = ori;
  lines.l[lines.count - 1].cx = cx / length;
  lines.l[lines.count - 1].cy = cy / length;
  lines.l[lines.count - 1].strength = strength / length;
  lines.l[lines.count - 1].length = length;
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
