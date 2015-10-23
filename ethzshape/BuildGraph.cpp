#include "MyMexHelper.hpp"
#include <deque>
#include <algorithm>

// Find Ridge
Matrix<double> in;
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
  struct TreeNode {
    std::vector<TreeNode *> adj;
    TreeNode * parent;
    int x, y;
    TreeNode(int _x, int _y, TreeNode * p):x(_x),y(_y),parent(p) {
      adj.push_back(p);
      p->adj.push_back(this);
    }
  };
  Matrix<int> & ridge;
  std::vector<TreeNode> tree;
  Tree(int x0, int y0, Matrix<int> & r):ridge(r) {
    tree.push_back(TreeNode(x0, y0, 0, NULL));
    for (int p = 0; p < tree.size(); p++) {
      int x = tree[p].x, y = tree[p].y;
      for (int i = -1; i <= 1; i++)
        for (int j = -1; j <= 1; j++) {
          if (i == 0 && j == 0) continue;
          if (i + x < 0 || i + x >= ridge.w || j + y < 0 || j + y >= ridge.h) continue;
          if (ridge(j+y,i+x) != 1) continue;
          ridge(j+y,i+x) = 2;
          tree.push_back(TreeNode(i+x, j+y, &(tree[p])));
        }
    }
  }
  TreeNode * Traverse(int i) {
    std::deque<TreeNode *> queue;
    TreeNode * p = &(tree[i]);
    p->parent = NULL;
    for (queue.push_back(p); queue.size() > 0; queue.pop_front()) {
      p = queue.front();
      for (int i = 0; i < p->adj.size(); i++) {
        TreeNode * t = p->adj[i];
        if (t == p->parent || ridge(t->y,t->x) != 2) continue;
        t->parent = p;
        queue.push_back(t);
      }
    }
    return p;
  }
  void PathToRoot(TreeNode * n, std::vector<pair<int> > & line) {
    line.clear();
    while (n != NULL) {
      int x = n->x, y = n->y;
      ridge(y,x) = 3;
      line.push_back(make_pair(x, y));
      n = n->parent;
    }
  }
};

// Extract Long Lines from Trees
struct Point { 
  int x, y;
  Point(int _x, int _y):x(_x),y(_y){} 
};
typedef std::vector<Point> Line;
std::vector<Line> line;
struct PointNode {
  int lineIdx, pointIdx, degree;
};
Matrix<PointNode> node;
void initGraph(Matrix<int> & ridge, Matrix<PointNode> & node, std::vector<Line> & line) {
  for (int i = 0; i < in.h; i++)
    for (int j = 0; j < in.w; j++) {
      if (ridge(i,j) != 1) continue;
      ridge(i,j) = 2;
      Tree tree(j, i, ridge);
      for (int k = 0, p = tree.tree.size() - 1; k < tree.tree.size(); k++) {
        if (p > 0) {}
        TreeNode * t = tree.Traverse(p);
        while (t != NULL) {
          int x = t->x, y = t->y;
          ridge(y,x) = 3;
        }
      }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  in.SetInput(0, mxDOUBLE_CLASS);
  ridge.NewData(in.dims);
  findRidge(in, ridge);
  node.NewData(in.dims);
  initGraph(ridge, node, line);
  ridge.DeleteData();
  node.DeleteData();
}