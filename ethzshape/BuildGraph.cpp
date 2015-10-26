#include "MyMexHelper.hpp"
#include <map>

// Input Params
Matrix<double> in; 
int minLength; 

// Output Params
Matrix<int> ridge;
Matrix<int> lmap;
Matrix<int> pmap;
CellMatrix lcell;
std::vector<Matrix<int> > lines;

// Find Ridge
void findRidge() {
  for (int i = 1; i + 1 < in.h; i++) for (int j = 1; j + 1 < in.w; j++) {
    double ij = in(i,j);
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
    lines.push_back(Matrix<int>());
    Matrix<int> & l = lines.back();
    l.CreateArray(MatrixBase::MakeDims(line.size(), 2), mxINT32_CLASS);
    int lidx = lines.size();
    for (int i = 0; i < t.size(); i++) ridge(t[i].y,t[i].x) = 1;
    for (int i = 0; i < line.size(); i++) {
      int k = line[i];
      ridge(t[k].y,t[k].x) = 2;
      lmap(t[k].y,t[k].x) = lidx;
      pmap(t[k].y,t[k].x) = i + 1;
      l(i,0) = t[k].x + 1;
      l(i,1) = t[k].y + 1;
    }
  }
} tree;
void findLine() {
  lines.clear();
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

// Connect Lines
struct Graph {
  struct Link {
    int fromIdx, toIdx, dist;
  };
  std::map<int,> link;
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double dMinLength;
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  if (!in.SetInput(0, mxDOUBLE_CLASS)) return;
  if (!Matrix<int>::GetInputValue(1, minLength)) return;
  if (!Matrix<int>::GetInputValue(2, maxGap))
  if (!ridge.SetOutput(0, in.dims, mxINT32_CLASS)) return;
  if (!lmap.SetOutput(1, in.dims, mxINT32_CLASS)) return;
  if (!pmap.SetOutput(2, in.dims, mxINT32_CLASS)) return;
  findRidge();
  findLine();
  if (!lcell.SetOutput(3, MatrixBase::MakeDims(lines.size()), mxCELL_CLASS)) return;
  for (int i = 0; i < lines.size(); i++) lcell.Set(i, lines[i]);
}
