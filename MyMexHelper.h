typedef struct _matrix_ {
  mwSize nDim, h, w, n;
  const mwSize *dims;
  void * data;
  mxClassID classID;
} Matrix;

int GetInputMatrix(int nrhs, const mxArray *prhs[], int idx, mxClassID classID, Matrix * mat)
{
  const mxArray * arr = NULL;
  int i = 0;
  if (idx >= nrhs || idx < 0) {
    mexErrMsgTxt("Not enough input arguments.");
    return 0;
  }
  arr = prhs[idx];
  mat->nDim = mxGetNumberOfDimensions(arr);
  mat->dims = mxGetDimensions(arr);
  mat->classID = mxGetClassID(arr);
  if (classID != mat->classID) {
    mexErrMsgTxt("Not expected type of arguments.");
    return 0;
  }
  if (classID == mxLOGICAL_CLASS) {
    mat->data = (void *) mxGetLogicals(arr);
  } else {
    mat->data = mxGetData(arr);
  }
  if (mat->nDim > 0) mat->h = mat->dims[0];
  if (mat->nDim > 1) mat->w = mat->dims[1];
  for (i = 2, mat->n = 1; i < mat->nDim; i++) mat->n *= mat->dims[i];
  return 1;
}

int GetInputValue(int nrhs, const mxArray *prhs[], int idx, double * val) 
{
  if (idx >= nrhs || idx < 0) {
    mexErrMsgTxt("Not enough input arguments.");
    return 0;
  }
  *val = mxGetScalar(prhs[idx]);
  return 1; 
}

int GetOutputMatrix(int nlhs, mxArray *plhs[], int idx, Matrix * mat)
{
  if (idx != 0 && (idx >= nlhs || idx < 0)) {
    mexErrMsgTxt("Not enough input arguments.");
    return 0;
  }
  if (mat->classID == mxLOGICAL_CLASS) {
    plhs[idx] = mxCreateLogicalArray(mat->nDim, mat->dims);
    mat->data = (void *) mxGetLogicals(plhs[idx]);
  } else {
    plhs[idx] = mxCreateNumericArray(mat->nDim, mat->dims, mat->classID, mxREAL);
    mat->data = mxGetData(plhs[idx]);
  }
  return 1;
}
