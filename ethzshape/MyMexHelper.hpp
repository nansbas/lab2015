#include <mex.h>
#include <vector>

struct MatrixBase {
  
  static int nlhs;
  static int nrhs;
  static mxArray ** plhs;
  static const mxArray ** prhs;
  
  static void Bind(int nl, mxArray ** pl, int nr, const mxArray ** pr)
  {
    nlhs = nl; plhs = pl; nrhs = nr; prhs = pr;
  }

  static std::vector<mwSize> MakeDim(size_t i, size_t j)
  {
    std::vector<mwSize> v;
    v.push_back((mwSize)i);
    v.push_back((mwSize)j);
    return v;
  }

  static std::vector<mwSize> MakeDim(size_t i, size_t j, size_t k)
  {
    std::vector<mwSize> v;
    v.push_back((mwSize)i);
    v.push_back((mwSize)j);
    v.push_back((mwSize)k);
    return v;
  }

  mwSize nDim, h, w, n;
  mxClassID classID;
  std::vector<mwSize> dims;
  mxArray * arr;
  virtual void GetDataPointer() = 0;

  MatrixBase():arr(NULL),h(0),w(0),n(0),nDim(0) {}
  virtual ~MatrixBase() {}
  
  void SetDim(const std::vector<mwSize> & d)
  {
    dims = d;
    nDim = (mwSize) dims.size();
    h = w = 0; n = 1;
    for (int i = 0; i < nDim; i++) {
      if (i == 0) h = dims[0];
      if (i == 1) w = dims[1];
      if (i > 1) n *= dims[i];
    }
  }

  void LoadArray(const mxArray * a)
  {
    nDim = mxGetNumberOfDimensions(a);
    const mwSize * d = mxGetDimensions(a);
    dims.clear();
    for (int i = 0; i < nDim; i++)
      dims.push_back(d[i]);
    arr = (mxArray *) a;
    classID = mxGetClassID(a);
    SetDim(dims);
    GetDataPointer();
  }

  mxArray * CreateArray()
  {
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

  bool SetInput(int idx, mxClassID cid)
  {
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

  bool SetOutput(int idx, const std::vector<mwSize> & d, mxClassID cid)
  {
    classID = cid;
    SetDim(d);
    if (idx != 0 && (idx >= nlhs || idx < 0)) {
      mexErrMsgTxt("Not enough output arguments.");
      return false;
    }
    plhs[idx] = CreateArray();
    return true;
  }

  bool SetInOut(int iIn, int iOut, mxClassID cid)
  {
    if (!SetInput(iIn, cid)) return false;
    if (iOut != 0 && (iOut >= nlhs || iOut < 0)) {
      mexErrMsgTxt("Not enough output arguments.");
      return false;
    }
    plhs[iOut] = mxDuplicateArray(arr);
    arr = plhs[iOut];
    GetDataPointer();
    return true;
  }

  void DestroyArray()
  {
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
  inline T & operator() (int i) {
    return data[i];
  }
  inline const T & operator() (int i, int j, int k) const {
    return data[i + j * h + k * h * w];
  }
  inline const T & operator() (int i, int j) const {
    return data[i + j * h];
  }
  inline const T & operator() (int i) const {
    return data[i];
  }

  virtual void GetDataPointer()
  {
    if (classID == mxLOGICAL_CLASS) {
      data = (T *) mxGetLogicals(arr);
    } else if (classID == mxCELL_CLASS) {
      data = NULL;
    } else {
      data = (T *) mxGetData(arr);
    }
  }

  static bool GetInputValue(int idx, T & value)
  {
    if (idx >= nrhs || idx < 0) {
      mexErrMsgTxt("Not enough input arguments.");
      return false;
    }
    double dValue = mxGetScalar(prhs[idx]);
    value = (T) dValue;
    return true;
  }

};

struct CellMatrix : public Matrix<MatrixBase *> {

  std::vector<MatrixBase *> mpdata;
  int pidx;

  virtual ~CellMatrix()
  {
    ClearMatrixData();
  }

  virtual void GetDataPointer()
  {
    if (mpdata.size() > 0)
      data = &(mpdata[0]);
    else
      data = NULL;
  }

  void ClearMatrixData()
  {
    for (int i = 0; i < mpdata.size(); i++) {
      if (mpdata[i] == NULL) continue;
      delete mpdata[i];
    }
    mpdata.clear();
  }
  
  bool SetOutput(int idx)
  {
    classID = mxCELL_CLASS;
    if (idx != 0 && (idx >= nlhs || idx < 0)) {
      mexErrMsgTxt("Not enough output arguments.");
      return false;
    }
    arr = NULL;
    ClearMatrixData();
    pidx = idx;
    return true;
  }

  template <typename T>
  Matrix<T> & Append(const std::vector<mwSize> & d, mxClassID cid)
  {
    Matrix<T> * mp = new Matrix<T>();
    mpdata.push_back(mp);
    mp->SetDim(d);
    mp->classID = cid;
    mp->CreateArray();
    GetDataPointer();
    return (*mp);
  }

  size_t Size() 
  {
    return mpdata.size();
  }

  void Finish()
  {
    SetDim(MakeDim(1, mpdata.size()));
    classID = mxCELL_CLASS;
    if (pidx != 0 && (pidx >= nlhs || pidx < 0)) {
      mexErrMsgTxt("Not enough output arguments.");
      return;
    }
    plhs[pidx] = CreateArray();
    for (int i = 0; i < mpdata.size(); i++) {
      if (mpdata[i] == NULL) continue;
      mxSetCell(arr, i, mpdata[i]->arr);
    }
  }

};

int MatrixBase::nlhs;
int MatrixBase::nrhs;
mxArray ** MatrixBase::plhs;
const mxArray ** MatrixBase::prhs;
