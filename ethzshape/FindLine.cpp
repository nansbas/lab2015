/// [ridge, map, lines] = FindLine(in, minLength, minValue)
///   Get ridge and divide ridge into lines.
///   in should be double.
///   minLength is the minimal length of lines. minValue is the minimal value of ridge pixel.
///   ridge is integer, 0 for non-ridge, 1 for ridge, 2 for converted lines.
///   map is integer, index of lines starting from 1.
///   lines is cell, containing line points and point value [x, y, v; ...].

#include "MyMexHelper.hpp"

// Input Params
Matrix<double> in; 
int minLength;
double minValue;

// Output Params
Matrix<int> ridge;
Matrix<int> lmap;
CellMatrix lines;

// Find Ridge
void findRidge() {
  for (int i = 1; i + 1 < in.h; i++) for (int j = 1; j + 1 < in.w; j++) {
    double ij = in(i,j);
    if (ij <= minValue) continue;
    if ((ij >= in(i-1,j) && ij > in(i+1,j)) || (ij >= in(i,j-1) && ij > in(i,j+1)))
      ridge(i,j) = 1;
  }
}

// Find Lines
struct Tree {
  struct TreeNode {
    int parent, firstChild, nextSibling, x, y, link;
    TreeNode(int _x, int _y, int p):x(_x),y(_y),parent(p),firstChild(-1),nextSibling(-1),link(-1) {}
  };
  std::vector<TreeNode> t;
  std::vector<int> line;
  void Clear() { t.clear(); }
  size_t Size() { return t.size(); }
  TreeNode & operator()(int i) { return t[i]; }
  void Add(int x, int y, int p) {
    if (x < 0 || x >= in.w || y < 0 || y >= in.h) return;
    if (ridge(y,x) != 1) return;
    ridge(y,x) = 2;
    t.push_back(TreeNode(x, y, p));
    if (p >= 0 && p < t.size()) {
      t.back().nextSibling = t[p].firstChild;
      t[p].firstChild = t.size() - 1;
    }
  }
  void Traverse(int i) {
    std::vector<int> q;
    q.push_back(i);
    for (int k = 0; k < q.size(); k++) {
      i = q[k];
      if (t[i].parent >= 0 && t[i].parent != t[i].link) {
        t[t[i].parent].link = i;
        q.push_back(t[i].parent);
      }
      for (int j = t[i].firstChild; j >= 0; j = t[j].nextSibling) {
        if (j != t[i].link) {
          t[j].link = i;
          q.push_back(j);
        }
      }
    }
    line.clear();
    for (i = q.back(); i >= 0; i = t[i].link) line.push_back(i);
  }
  void MapLine() {
    Matrix<double> & l = lines.Append<double>(MatrixBase::MakeDim(line.size(), 3), mxDOUBLE_CLASS);
    int lidx = lines.Size();
    for (int i = 0; i < t.size(); i++) ridge(t[i].y,t[i].x) = 1;
    for (int i = 0; i < line.size(); i++) {
      int k = line[i];
      ridge(t[k].y,t[k].x) = 2;
      lmap(t[k].y,t[k].x) = lidx;
      l(i,0) = double(t[k].x + 1);
      l(i,1) = double(t[k].y + 1);
      l(i,2) = in(t[k].y, t[k].x);
    }
  }
} tree;

void findLine() {
  for (int y = 0; y < in.h; y++) for (int x = 0; x < in.w; x++) {
    if (ridge(y,x) != 1) continue;
    tree.Clear();
    tree.Add(x, y, -1);
    for (int i = 0; i < tree.Size(); i++) {
      int ix = tree(i).x, iy = tree(i).y;
      for (int dx = -1; dx <= 1; dx++) for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        tree.Add(ix + dx, iy + dy, i);
      }
    }
    if (tree.Size() < minLength) continue;
    tree.Traverse(tree.Size() - 1);
    if (tree.line.size() < minLength) continue;
    tree.MapLine();
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  if (!in.SetInput(0, mxDOUBLE_CLASS)) return;
  if (!Matrix<int>::GetInputValue(1, minLength)) return;
  if (!Matrix<double>::GetInputValue(2, minValue)) return;
  if (!ridge.SetOutput(0, in.dims, mxINT32_CLASS)) return;
  if (!lmap.SetOutput(1, in.dims, mxINT32_CLASS)) return;
  if (!lines.SetOutput(2)) return;
  findRidge();
  findLine();
  lines.Finish();
}
