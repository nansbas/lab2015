#include "MyMexHelper.hpp"
#include <deque>
#include <algorithm>

// Find Ridge
Matrix<double> in;
Matrix<int> out;
Matrix<int> ridge;
void findRidge(const Matrix<double> & in, Matrix<int> & out) {
  for (int i = 1; i + 1 < in.h; i++)
    for (int j = 1; j + 1 < in.w; j++) {
      double ij = in(i,j);
      if ((ij >= in(i-1,j) && ij > in(i+1,j)) || (ij >= in(i,j-1) && ij > in(i,j+1)))
        out(i,j) = 1;
    }
}

// Build Spanning Tree
struct Tree {
  struct Node {
    std::vector<Node *> adj;
    Node * parent;
    int x, y;
  };
  Matrix<int> & ridge;
  std::vector<Node> tree;
  size_t Size() { return tree.size(); }
  Node * operator()(int i) { return &(tree[i]); }
  void AddNode(int x, int y, Node * p) {
    tree.push_back(Node());
    Node * t = &(tree.back());
    t->x = x;
    t->y = y;
    t->adj.push_back(p);
    t->parent = p;
    if (p != NULL) p->adj.push_back(t);
  }
  Tree(int x0, int y0, Matrix<int> & r):ridge(r) {
    AddNode(x0, y0, NULL);
    for (int p = 0; p < tree.size(); p++) {
      int x = tree[p].x, y = tree[p].y;
      for (int i = -1; i <= 1; i++)
        for (int j = -1; j <= 1; j++) {
          if (i == 0 && j == 0) continue;
          if (i + x < 0 || i + x >= ridge.w || j + y < 0 || j + y >= ridge.h) continue;
          if (ridge(j+y,i+x) != 1) continue;
          ridge(j+y,i+x) = 2;
          AddNode(i+x, j+y, &(tree[p]));
        }
    }
  }
  Node * Traverse(Node * p) {
    std::deque<Node *> queue;
    p->parent = NULL;
    for (queue.push_back(p); queue.size() > 0; queue.pop_front()) {
      p = queue.front();
      for (int i = 0; i < p->adj.size(); i++) {
        Node * t = p->adj[i];
        if (t == NULL || t == p->parent || ridge(t->y,t->x) != 2) continue;
        t->parent = p;
        queue.push_back(t);
      }
    }
    return p;
  }
};

// Extract Long Lines from Trees
struct PointNode {
  int lineIdx, pointIdx, degree;
  PointNode():lineIdx(0),pointIdx(0),degree(0){}
};
Matrix<PointNode> node;
typedef std::vector<std::pair<int,int> > Line;
typedef std::vector<Line> Lines;
Lines lines;
double minLength;
void initGraph(Matrix<int> & ridge, Matrix<PointNode> & node, Lines & lines) {
  for (int i = 0; i < in.h; i++)
    for (int j = 0; j < in.w; j++) {
      if (ridge(i,j) != 1) continue;
      ridge(i,j) = 2;
      Tree tree(j, i, ridge);
      Tree::Node * p = tree(tree.Size() - 1);
      for (int k = 0; k < tree.Size(); p = NULL) {
        if (ridge(tree(k)->y, tree(k)->x) != 2) { k++; continue; }
        if (p == NULL) p = tree.Traverse(tree(k));
        Line line;
        for (Tree::Node * t = tree.Traverse(p); t != NULL; t = t->parent) {
          mexPrintf("line: %08x\n", t);
          int x = t->x, y = t->y;
          ridge(y,x) = 3;
          line.push_back(std::make_pair(x, y));
        }
        mexPrintf("end line\n");
        if (line.size() >= minLength) {
          lines.push_back(line);
          for (int m = 0; m < line.size(); m++) {
            PointNode & pnode = node(line[m].second, line[m].first);
            mexPrintf("pnode: %d,%d\n", line[m].second, line[m].first);
            pnode.lineIdx = lines.size() - 1;
            pnode.pointIdx = m;
            pnode.degree = (m == 0 || m + 1 == line.size()) ? 1 : 2;
            out(line[m].second, line[m].first) = pnode.lineIdx + 1;
          }
        }
      }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  in.SetInput(0, mxDOUBLE_CLASS);
  in.GetInputValue(1, minLength);
  out.SetOutput(0, in.dims, mxINT32_CLASS);
  ridge.NewData(in.dims);
  findRidge(in, ridge);
  node.NewData(in.dims);
  initGraph(ridge, node, lines);
  ridge.DeleteData();
  node.DeleteData();
}