#include "MyMexHelper.hpp"

Matrix<double> in;
Matrix<mxLogical> ridge;

void findRidge(const Matrix<double> &in, Matrix<mxLogical> &out) {
  for (int i = 1; i + 1 < in.h; i++)
    for (int j = 1; j + 1 < in.w; j++) {
      double ij = in(i,j);
      if ((ij >= in(i-1,j) && ij > in(i+1,j)) || (ij >= in(i,j-1) && ij > in(i,j+1)))
        out(i,j) = 1;
    }
}

struct Node {
  std::vector<Node *> adj;
  int x, y;
};
Matrix<Node *> node;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  MatrixBase::Bind(nlhs, plhs, nrhs, prhs);
  in.SetInput(0, mxDOUBLE_CLASS);
  ridge.NewData(in.dims);
  findRidge(in, ridge);
  node.NewData(in.dims);
  ridge.DeleteData();
  node.DeleteData();
}