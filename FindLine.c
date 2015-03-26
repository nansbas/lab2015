#include <mex.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <stdlib.h>
#include "MyMexHelper.h"

#define MAX_TREE 30000
#define MAX_LENG 1000
#define MAX_LINE 2000

Matrix ridge, ori, map, lout, graph;
double maxOriDiff, minRidge, minLength, maxGap;
char * inTree;

struct _lines_ {
  struct _line_record_ {
    int x1, y1, x2, y2, length, cx, cy;
    double sina, cosa, strength;
  } l[MAX_LINE];
  int count;
} lines;

#define R(x,y) (((double*)(ridge.data))[(y)+(x)*ridge.h])
#define ORI(x,y) (((double*)(ori.data))[(y)+(x)*ridge.h])
#define MAP(x,y) (((int*)(map.data))[(y)+(x)*ridge.h])
#define INTREE(x,y) (inTree[(y)+(x)*ridge.h])
#define LOUT(r,c) (((double*)(lout.data))[(r)+(c)*lout.h])
#define G(r,c) (((int*)(graph.data))[(r)+(c)*graph.h])

void buildGraph()
{
  int i, x, y, dx, dy, iGap, j, dist;
  double sqrGap = maxGap * maxGap;
  iGap = (int)(maxGap < 0 ? maxGap - 0.5 : maxGap + 0.5);
  for (i = 0; i < lines.count; i++) {
    for (dx = -iGap; dx <= iGap; dx++)
    for (dy = -iGap; dy <= iGap; dy++) {
      if (dx == 0 && dy == 0) continue;
      dist = dx * dx + dy * dy;
      if (dist > sqrGap) continue;
      x = dx + lines.l[i].x1;
      y = dy + lines.l[i].y1;
      if (x < 0 || y < 0 || x >= ridge.w || y >= ridge.h) continue;
      j = MAP(x,y);
      if (j <= 0 || j > lines.count) continue;
      j = j - 1;
      if (j == i) continue;
      G(i,j) = dist;
      G(j,i) = dist;
    }
    for (dx = -iGap; dx <= iGap; dx++)
    for (dy = -iGap; dy <= iGap; dy++) {
      if (dx == 0 && dy == 0) continue;
      dist = dx * dx + dy * dy;
      if (dist > sqrGap) continue;
      x = dx + lines.l[i].x2;
      y = dy + lines.l[i].y2;
      if (x < 0 || y < 0 || x >= ridge.w || y >= ridge.h) continue;
      j = MAP(x,y);
      if (j <= 0 || j > lines.count) continue;
      j = j - 1;
      if (j == i) continue;
      G(i,j) = dist;
      G(j,i) = dist;
    }
  }
  for (i = 0; i < lines.count; i++) {
    for (j = 0; j < lines.count; j++) if (G(i,j) > 0) break;
    if (j < lines.count) continue;
    if (lines.l[i].length < 2 * minLength) continue;
    G(i,i) = 1;
  }
}

void findLine(int x, int y);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int x, y, i;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &ridge)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputValue(nrhs, prhs, 2, &minRidge)) return;
  if (!GetInputValue(nrhs, prhs, 3, &maxOriDiff)) return;
  if (!GetInputValue(nrhs, prhs, 4, &minLength)) return;
  if (!GetInputValue(nrhs, prhs, 5, &maxGap)) return;
  maxOriDiff = 
    sin(maxOriDiff / 90 * M_PI) * sin(maxOriDiff / 90 * M_PI) 
    + (1-cos(maxOriDiff / 90 * M_PI)) * (1-cos(maxOriDiff / 90 * M_PI));
  map = ori;
  map.classID = mxINT32_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &map)) return;
  inTree = (char *)calloc(ridge.w * ridge.h, sizeof(char));
  lines.count = 0;
  for (x = 0; x < ridge.w; x++)
  for (y = 0; y < ridge.h; y++) {
    if (INTREE(x,y) || MAP(x,y) > 0 || R(x,y) < minRidge) continue;
    findLine(x, y);
  }
  free(inTree);
  lout.h = lines.count;
  lout.w = 10;
  lout.n = 1;
  lout.dims = NULL;
  lout.classID = mxDOUBLE_CLASS;
  if (GetOutputMatrix(nlhs, plhs, 1, &lout)) {
    for (i = 0; i < lines.count; i++) {
      LOUT(i,0) = lines.l[i].x1;
      LOUT(i,1) = lines.l[i].y1;
      LOUT(i,2) = lines.l[i].x2;
      LOUT(i,3) = lines.l[i].y2;
      LOUT(i,4) = lines.l[i].cx;
      LOUT(i,5) = lines.l[i].cy;
      LOUT(i,6) = lines.l[i].length;
      LOUT(i,7) = lines.l[i].strength;
      LOUT(i,8) = lines.l[i].sina;
      LOUT(i,9) = lines.l[i].cosa;
    }
  }
  graph.h = lines.count;
  graph.w = lines.count;
  graph.n = 1;
  graph.dims = NULL;
  graph.classID = mxINT32_CLASS;
  if (GetOutputMatrix(nlhs, plhs, 2, &graph)) {
    buildGraph();
  }
}

struct _tree_ {
  struct _node_ {
    int x, y, parent, firstChild, nextSibling, depth;
    int visited, parent2, depth2;
  } nodes[MAX_TREE];
  int size;
} tree;

struct _line_ {
  int length;
  struct _point_ {
    int x, y;
    double sina, cosa, degree;
  } points[MAX_LENG];
} thisLine;

void splitLine(int start, int length)
{
  int i;
  double avgSin = 0, avgCos = 0, se = 0, norm;
  for (i = 0; i < length; i++) {
    avgSin += thisLine.points[start + i].sina;
    avgCos += thisLine.points[start + i].cosa;
  }
  avgSin /= length;
  avgCos /= length;
  norm = sqrt(avgSin * avgSin + avgCos * avgCos);
  avgSin /= norm;
  avgCos /= norm;
  if (length >= 2 * minLength) {
    for (i = 0; i < length; i++) {
      se += (thisLine.points[start + i].sina - avgSin) * (thisLine.points[start + i].sina - avgSin);
      se += (thisLine.points[start + i].cosa - avgCos) * (thisLine.points[start + i].cosa - avgCos);
    }
    se /= length;
    if (se > maxOriDiff) {
      // split only if the line is long enough and the orientation changes too much
      int m = length / 2;
      int j = 1;
      double mdiff = -1;
      for (i = m; i + minLength < length && i >= minLength; ) {
        double d1 = thisLine.points[start + i - 1].degree;
        double d2 = thisLine.points[start + i].degree;
        double d3 = thisLine.points[start + i + 1].degree;
        d1 = d1 > d2 ? d1 - d2 : d2 - d1;
        d3 = d3 > d2 ? d3 - d2 : d2 - d3;
        if (d1 > 90) d1 = 180 - d1;
        if (d3 > 90) d3 = 180 - d3;
        if (d1 + d3 > mdiff) {
          m = i;
          mdiff = d1 + d3;
        }
        i += j;
        j = (j > 0) ? (-1 - j) : (1 - j);
      }
      splitLine(start, m);
      splitLine(start + m, length - m);
      return;
    }
  }
  if (lines.count >= MAX_LINE) return;
  lines.l[lines.count].x1 = thisLine.points[start].x;
  lines.l[lines.count].y1 = thisLine.points[start].y;
  lines.l[lines.count].x2 = thisLine.points[start + length - 1].x;
  lines.l[lines.count].y2 = thisLine.points[start + length - 1].y;
  lines.l[lines.count].cx = 0;
  lines.l[lines.count].cy = 0;
  lines.l[lines.count].length = length;
  lines.l[lines.count].sina = avgSin;
  lines.l[lines.count].cosa = avgCos;
  lines.l[lines.count].strength = 0;
  lines.count++;
  for (i = 0; i < length; i++) {
    int x = thisLine.points[start + i].x;
    int y = thisLine.points[start + i].y;
    lines.l[lines.count - 1].cx += x;
    lines.l[lines.count - 1].cy += y;
    lines.l[lines.count - 1].strength += R(x,y);
    MAP(x,y) = lines.count;
  }
  lines.l[lines.count - 1].cx /= length;
  lines.l[lines.count - 1].cy /= length;
  lines.l[lines.count - 1].strength /= length;
}

void traverse(int i, int * m, int depth, int parent)
{
  int j;
  if (i < 0 || i >= tree.size) return;
  if (tree.nodes[i].visited) return;
  tree.nodes[i].visited = 1;
  tree.nodes[i].parent2 = parent;
  tree.nodes[i].depth2 = depth;
  if (depth > tree.nodes[*m].depth2) *m = i;
  traverse(tree.nodes[i].parent, m, depth + 1, i);
  for (j = tree.nodes[i].firstChild; j >= 0 && j < tree.size; j = tree.nodes[j].nextSibling) {
    traverse(j, m, depth + 1, i);
  }
}

void findLine(int x, int y)
{
  int i, n, m, j;
  double lastOri;
  static int dx[] = {-1,0,1,-1,1,-1,0,1};
  static int dy[] = {-1,-1,-1,0,0,1,1,1};

  // construct tree from (x,y)
  tree.size = 1;
  tree.nodes[0].x = x;
  tree.nodes[0].y = y;
  tree.nodes[0].parent = -1;
  tree.nodes[0].firstChild = -1;
  tree.nodes[0].nextSibling = -1;
  tree.nodes[0].depth = 1;
  tree.nodes[0].visited = 0;
  for (n = i = 0; i < tree.size; i++) {
    for (j = 0; j < 8; j++) {
      int nx = tree.nodes[i].x + dx[j];
      int ny = tree.nodes[i].y + dy[j];
      int p = tree.size;
      if (tree.size >= MAX_TREE) break;
      if (nx < 0 || ny < 0 || nx >= ridge.w || ny >= ridge.h) continue;
      if (MAP(nx,ny) > 0 || INTREE(nx,ny) || R(nx,ny) < minRidge) continue;
      tree.size++;
      tree.nodes[p].x = nx;
      tree.nodes[p].y = ny;
      tree.nodes[p].parent = i;
      tree.nodes[p].firstChild = -1;
      tree.nodes[p].nextSibling = tree.nodes[i].firstChild;
      tree.nodes[p].depth = tree.nodes[i].depth + 1;
      tree.nodes[p].visited = 0;
      tree.nodes[i].firstChild = p;
      if (tree.nodes[p].depth > tree.nodes[n].depth) n = p;
      INTREE(nx,ny) = 1;
    }
    if (tree.size >= MAX_TREE) break;
  }
  if (tree.size < minLength) return; // keep INTREE to ignore this isolated clique

  // find longest path
  m = n;
  traverse(n, &m, 1, -1);
  if (tree.nodes[m].depth2 < minLength) return; // keep INTREE to ignore this isolated clique
  if (tree.nodes[m].depth2 > MAX_LENG) return; // cannot do too long line
  thisLine.length = tree.nodes[m].depth2;
  for (i = m, j = 0; i >= 0 && i < tree.size; i = tree.nodes[i].parent2) {
    int x = tree.nodes[i].x;
    int y = tree.nodes[i].y;
    double deg = ORI(x,y);
    thisLine.points[j].x = x;
    thisLine.points[j].y = y;
    thisLine.points[j].degree = deg;
    thisLine.points[j].sina = sin(deg / 90 * M_PI);
    thisLine.points[j].cosa = cos(deg / 90 * M_PI);
    j++;
  }
  splitLine(0, thisLine.length);

  // clear tree
  for (i = 0; i < tree.size; i++) {
    INTREE(tree.nodes[i].x, tree.nodes[i].y) = 0;
  }
  tree.size = 0;
}
