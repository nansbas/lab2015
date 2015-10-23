#include <mex.h>
#include <vector>

struct MatrixBase {
  mwSize nDim, h, w, n;
  mxClassID classID;
  std::vector<mwSize> dims;
  mxArray * arr;
  static int nlhs;
  static int nrhs;
  static mxArray ** plhs;
  static const mxArray ** prhs;
  static void Bind(int nl, mxArray ** pl, int nr, const mxArray ** pr) {
    nlhs = nl; plhs = pl; nrhs = nr; prhs = pr;
  }
  static bool GetInputValue(int idx, double & value) {
    if (idx >= nrhs || idx < 0) {
      mexErrMsgTxt("Not enough input arguments.");
      return false;
    }
    value = mxGetScalar(prhs[idx]);
    return true;
  }
  virtual void GetDataPointer() = 0;
  MatrixBase():arr(NULL){}
  void SetDims(const std::vector<mwSize> & d) {
    dims = d;
    nDim = (mwSize) dims.size();
    h = w = 0; n = 1;
    for (int i = 0; i < nDim; i++) {
      if (i == 0) h = dims[0];
      if (i == 1) w = dims[1];
      if (i > 1) n *= dims[i];
    }
  }
  void LoadArray(const mxArray * a) {
    nDim = mxGetNumberOfDimensions(a);
    const mwSize * d = mxGetDimensions(a);
    classID = mxGetClassID(a);
    dims.clear();
    h = w = 0; n = 1;
    for (int i = 0; i < nDim; i++) {
      if (i == 0) h = d[0];
      if (i == 1) w = d[1];
      if (i > 1) n *= d[i];
      dims.push_back(d[i]); 
    }
    arr = (mxArray *) a;
    GetDataPointer();
  }
  mxArray * CreateArray() {
    if (classID == mxCELL_CLASS) {
      arr = mxCreateCellArray(nDim, &(dims[0]));
    } else if (classID == mxLOGICAL_CLASS) {
      arr = mxCreateLogicalArray(nDim, &(dims[0]));
    } else {
      arr = mxCreateNumericArray(nDim, &(dims[0]), classID, mxREAL);
    }
    GetDataPointer();
    return arr;
  }
  mxArray * CreateArray(const std::vector<mwSize> & d, mxClassID cid) {
    classID = cid;
    SetDims(d);
    return CreateArray();
  }
  bool SetInput(int idx, mxClassID cid) {
    if (idx >= nrhs || idx < 0) {
      mexErrMsgTxt("Not enough input arguments.");
      return false;
    }
    LoadArray(prhs[idx]);
    if (cid != classID) {
      mexErrMsgTxt("Not expected type of arguments.");
      return false;
    }
    return true;
  }
  bool SetOutput(int idx, std::vector<mwSize> d, mxClassID cid) {
    dims = d;
    classID = cid;
    return SetOutput(idx);
  }
  bool SetOutput(int idx) {
    if (idx != 0 && (idx >= nlhs || idx < 0)) return false;
    plhs[idx] = CreateArray();
    return true;
  }
  bool SetInOut(int iIn, int iOut, mxClassID cid) {
    if (!SetInput(iIn, cid)) return false;
    if (iOut != 0 && (iOut >= nlhs || iOut < 0)) return false;
    plhs[iOut] = mxDuplicateArray(arr);
    arr = plhs[iOut];
    GetDataPointer();
    return true;
  }
  void DestroyArray() {
    if (arr) {
      mxDestroyArray(arr);
      arr = NULL;
    }
  }
};

template <typename T>
struct Matrix : public MatrixBase {
  T * data;
  inline T & operator() (int i, int j, int k) {
    return data[i + j * h + k * h * w];
  }
  inline T & operator() (int i, int j) {
    return data[i + j * h];
  }
  inline const T & operator() (int i, int j, int k) const {
    return data[i + j * h + k * h * w];
  }
  inline const T & operator() (int i, int j) const {
    return data[i + j * h];
  }
  virtual void GetDataPointer() {
    if (classID == mxLOGICAL_CLASS) {
      data = (T *) mxGetLogicals(arr);
    } else {
      data = (T *) mxGetData(arr);
    }
  }
  void NewData(const std::vector<mwSize> & d) {
    SetDims(d);
    data = new T[h * w * n]();
  }
  void DeleteData() {
    delete[] data;
    data = NULL;
  }
};

int MatrixBase::nlhs;
int MatrixBase::nrhs;
mxArray ** MatrixBase::plhs;
const mxArray ** MatrixBase::prhs;
