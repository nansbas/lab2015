typedef struct _matrix_ {
  mwSize nDim, h, w, n;
  const mwSize *dims;
  void * data;
  mxClassID classID;
} Matrix;

int GetMatrix(const mxArray * arr, mxClassID classID, Matrix * mat)
{
  int i;
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

int GetInputMatrix(int nrhs, const mxArray *prhs[], int idx, mxClassID classID, Matrix * mat)
{
  if (idx >= nrhs || idx < 0) {
    mexErrMsgTxt("Not enough input arguments.");
    return 0;
  }
  return GetMatrix(prhs[idx], classID, mat);
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

mxArray * CreateMatrix(Matrix * mat)
{
  mxArray * arr = NULL;
  mwSize dims[3];
  if (mat->dims == NULL) {
    dims[0] = mat->h;
    dims[1] = mat->w;
    dims[2] = mat->n;
    mat->dims = (const mwSize *) dims;
    mat->nDim = 3;
  }
  if (mat->classID == mxCELL_CLASS) {
    arr = mxCreateCellArray(mat->nDim, mat->dims);
    mat->data = (void *) arr;
  } else if (mat->classID == mxLOGICAL_CLASS) {
    arr = mxCreateLogicalArray(mat->nDim, mat->dims);
    mat->data = (void *) mxGetLogicals(arr);
  } else {
    arr = mxCreateNumericArray(mat->nDim, mat->dims, mat->classID, mxREAL);
    mat->data = mxGetData(arr);
  }
  return arr;
}

int GetOutputMatrix(int nlhs, mxArray *plhs[], int idx, Matrix * mat)
{
  mat->data = NULL;
  if (idx != 0 && (idx >= nlhs || idx < 0)) {
    // mexErrMsgTxt("Not enough output arguments.");
    return 0;
  }
  plhs[idx] = CreateMatrix(mat);
  return 1;
}

int GetInOutMatrix(int nrhs, const mxArray *prhs[], int inIdx, int nlhs, mxArray *plhs[], int outIdx, mxClassID classID, Matrix * mat)
{
  const mxArray * arr = NULL;
  if (!GetInputMatrix(nrhs, prhs, inIdx, classID, mat)) return 0;
  if (outIdx == 0 || (outIdx < nlhs && outIdx >= 0)) {
    plhs[outIdx] = mxDuplicateArray(prhs[inIdx]);
    arr = plhs[outIdx];
    if (classID == mxLOGICAL_CLASS) {
      mat->data = (void *) mxGetLogicals(arr);
    } else {
      mat->data = mxGetData(arr);
    }
  }
  return 1;
}
