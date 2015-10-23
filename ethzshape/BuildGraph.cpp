#include "MyMexHelper.hpp"
#include <deque>

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

// Build Graph of Lines
struct TreeNode {
  int x, y, depth, firstChild, nextSibling, parent;
  TreeNode(int _x, int _y, int d, int p):x(_x),y(_y),depth(d),firstChild(0),nextSibling(0),parent(p){}
};
std::vector<TreeNode> tree;
void treeFromPoint(Matrix<int> & ridge, std::vector<TreeNode> & tree) {
  for (int p = 0; p < tree.size(); p++) {
    int x = tree[p].x, y = tree[p].y, d = tree[p].depth;
    for (int i = -1; i <= 1; i++)
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        if (i + x < 0 || i + x >= ridge.w || j + y < 0 || j + y >= ridge.h) continue;
        if (ridge(j+y,i+x) != 1) continue;
        ridge(j+y,i+x) = 2;
        tree.push_back(TreeNode(i+x, j+y, d+1, p));
      }
  }
}
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
void lineFromTree(Matrix<PointNode> & node, std::vector<Line> & line, std::vector<TreeNode> & tree) {

}
void initGraph(Matrix<int> & ridge, Matrix<PointNode> & node, std::vector<Line> & line) {
  for (int i = 0; i < in.h; i++)
    for (int j = 0; j < in.w; j++) {
      if (ridge(i,j) != 1) continue;
      ridge(i,j) = 2;
      tree.clear();
      tree.push_back(TreeNode(j, i, 0, -1));
      treeFromPoint(ridge, tree);
      lineFromTree(node, line, tree);
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