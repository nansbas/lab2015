#include <mex.h>
#include <stdlib.h>
#include "MyMexHelper.h"

#define MAX_TREE 30000
#define MAX_LENG 900000

Matrix ridge, ori, map;
double minRidge, minLength;
char * inTree;

#define R(x,y) (((double*)(ridge.data))[(y)+(x)*ridge.h])
#define ORI(x,y) (((double*)(ori.data))[(y)+(x)*ridge.h])
#define MAP(x,y) (((int*)(map.data))[(y)+(x)*ridge.h])
#define INTREE(x,y) (inTree[(y)+(x)*ridge.h])

struct _line_ {
  int count;
  int tail;
  struct _point_ {
    int x, y;
  } p[MAX_LENG];
} lines;

void findLine(int x, int y);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int x, y;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &ridge)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &ori)) return;
  if (!GetInputValue(nrhs, prhs, 2, &minRidge)) return;
  if (!GetInputValue(nrhs, prhs, 3, &minLength)) return;
  map = ori;
  map.classID = mxINT32_CLASS;
  if (!GetOutputMatrix(nlhs, plhs, 0, &map)) return;
  inTree = (char *)calloc(ridge.w * ridge.h, sizeof(char));
  lines.count = 0;
  lines.tail = 0;
  for (x = 0; x < ridge.w; x++)
  for (y = 0; y < ridge.h; y++) {
    if (INTREE(x,y) || MAP(x,y) > 0 || R(x,y) < minRidge) continue;
    findLine(x, y);
  }
  free(inTree);
  if (nlhs > 1) {
    int i, j, k, len;
    mxArray * thisLine;
    double * dLine;
    plhs[1] = mxCreateCellMatrix(1, lines.count);
    for (i = 0, j = 0; i < lines.count; i++) {
      len = lines.p[j].y;
      j++;
      thisLine = mxCreateDoubleMatrix(len, 4, mxREAL);
      dLine = mxGetPr(thisLine);
      for (k = 0; k < len; k++) {
        x = lines.p[j].x;
        y = lines.p[j].y;
        dLine[k] = x;
        dLine[k + len] = y;
        dLine[k + len * 2] = R(x,y);
        dLine[k + len * 3] = ORI(x,y);
        j++;
      }
      mxSetCell(plhs[1], i, thisLine);
    }
  }
}

struct _tree_ {
  struct _node_ {
    int x, y, parent, firstChild, nextSibling, depth;
    int visited, parent2, depth2;
  } nodes[MAX_TREE];
  int size;
} tree;

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
  int i, n, m, j, nx, ny, p;
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
      nx = tree.nodes[i].x + dx[j]; // new x
      ny = tree.nodes[i].y + dy[j]; // new y
      p = tree.size; // p is the index of new node
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
      if (tree.nodes[p].depth > tree.nodes[n].depth) n = p; // n is the deepest node
      INTREE(nx,ny) = 1;
    }
    if (tree.size >= MAX_TREE) break;
  }
  if (tree.size < minLength) return; // keep INTREE to ignore this isolated clique

  // find longest path
  m = n;
  traverse(n, &m, 1, -1);
  if (tree.nodes[m].depth2 < minLength) return; // keep INTREE to ignore this isolated clique
  if (tree.nodes[m].depth2 + lines.tail >= MAX_LENG) return; // cannot do no more line
  lines.count++;
  lines.p[lines.tail].x = -1; // -1 indicates separator between line points
  lines.p[lines.tail].y = 0; // length of the line
  for (i = m; i >= 0 && i < tree.size; i = tree.nodes[i].parent2) {
    lines.p[lines.tail].y++;
    j = lines.tail + lines.p[lines.tail].y;
    nx = tree.nodes[i].x;
    ny = tree.nodes[i].y;
    lines.p[j].x = nx;
    lines.p[j].y = ny;
    MAP(nx,ny) = lines.count;
  }
  lines.tail = j + 1;

  // clear tree
  for (i = 0; i < tree.size; i++) {
    INTREE(tree.nodes[i].x, tree.nodes[i].y) = 0;
  }
  tree.size = 0;
}
