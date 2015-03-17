#include <mex.h>
#include <stdlib.h>
#include "MyMexHelper.h"

Matrix image, som, som2, neighbor;
double rate;
double * dist;
double * sum;

#define IMG(x,y) (((double*)(image.data))[(y)+(x)*image.h])
#define SOM(x,y,z) (((double*)(som2.data))[(y)+(x)*som.h+(z)*som.h*som.w])
#define NB(x,y) (((double*)(neighbor.data))[(y)+(x)*neighbor.h])
#define DIST(x,y,z) (dist[(y)+(x)*som.h+(z)*som.h*som.w])
#define SUM(x,y,z) (sum[(y)+(x)*som.h+(z)*som.h*som.w])

void doBlock(int sx, int sy);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, sx, sy;
  if (!GetInputMatrix(nrhs, prhs, 0, mxDOUBLE_CLASS, &som)) return;
  if (!GetInputMatrix(nrhs, prhs, 1, mxDOUBLE_CLASS, &image)) return;
  if (!GetInputMatrix(nrhs, prhs, 2, mxDOUBLE_CLASS, &neighbor)) return;
  if (!GetInputValue(nrhs, prhs, 3, &rate)) return;
  som2 = som;
  if (!GetOutputMatrix(nlhs, plhs, 0, &som2)) return;
  for (i = 0; i < som.h * som.w * som.n; i++) {
    ((double*)som2.data)[i] = ((double*)som.data)[i];
  }
  dist = (double *)malloc(sizeof(double) * som.h * som.w * som.n);
  sum = (double *)malloc(sizeof(double) * som.h * som.w * som.n);
  for (sx = 0; sx + som.w * 2 < image.w; sx += 3)
    for (sy = 0; sy + som.h * 2 < image.h; sy += 3)
      doBlock(sx, sy);
  free(dist);
  free(sum);
}

void doBlock(int sx, int sy)
{
  int x, y, i, dx, dy, px, py, mx, my, mi;
  double d, pimg, psom, maxsum = -1, mindist = -1;
  for (x = 0; x < som.w; x++)
  for (y = 0; y < som.h; y++)
  for (i = 0; i < som.n; i++) {
    DIST(x,y,i) = 0;
    SUM(x,y,i) = 0;
    for (dx = 0; dx < som.w; dx++)
    for (dy = 0; dy < som.h; dy++) {
      px = sx + x + dx;
      py = sy + y + dy;
      pimg = IMG(px,py);
      psom = SOM(dx,dy,i);
      d = pimg - psom;
      DIST(x,y,i) += d * d;
      SUM(x,y,i) += psom * pimg; 
    }
    if (maxsum < SUM(x,y,i)) maxsum = SUM(x,y,i);
    if (mindist < 0 || mindist > DIST(x,y,i)) {
      mindist = DIST(x,y,i);
      mx = x;
      my = y;
      mi = i;
    }
  }
  if (SUM(mx,my,mi) * 2 < maxsum) return;
  if (SUM(mx,my,mi) > 1) mexPrintf("SUM: %f\n", SUM(mx,my,mi));
  for (x = 0; x < som.w; x++)
  for (y = 0; y < som.h; y++)
  for (i = 0; i < som.n; i++) {
    SOM(x,y,i) += (IMG(sx+mx+x,sy+my+y) - SOM(x,y,i)) * NB(mi,i) * rate * SUM(mx,my,mi);
  }
}



