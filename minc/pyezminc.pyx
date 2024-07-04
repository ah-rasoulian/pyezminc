#  Copyright 2013, Haz-Edine Assemlal

#  This file is part of PYEZMINC.
# 
#  PYEZMINC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, version 2.
# 
#  PYEZMINC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with PYEZMINC.  If not, see <http://www.gnu.org/licenses/>.

# cython: c_string_type=unicode, c_string_encoding=utf8

from cpython cimport PyObject, Py_INCREF
from cpython cimport array
from array   import  array

# Import the Python-level symbols of numpy
import numpy as np

# compatibility
import six

# namedtuple support
from collections import namedtuple

# Import the C-level symbols of numpy
cimport numpy as np

from operator import mul

try:
    from functools import reduce
except ImportError:
    pass


# Numpy must be initialized. When using numpy from C or Cython you must
# _always_ do that, or you will have segfaults
np.import_array()


# Constant declarations

# NetCDF
NC_NAT =    0    #/* NAT = 'Not A Type' (c.f. NaN) */
NC_BYTE =   1    #/* signed 1 byte integer */
NC_CHAR =   2    #/* ISO/ASCII character */
NC_SHORT =  3    #/* signed 2 byte integer */
NC_INT =    4    #/* signed 4 byte integer */
NC_FLOAT =  5    #/* single precision floating point number */
NC_DOUBLE = 6    #/* double precision floating point number */

nctype_to_numpy = {NC_BYTE   : {True:np.int8,    False:np.uint8},
                   NC_CHAR   : {True:np.int8,    False:np.uint8},
                   NC_SHORT  : {True:np.int16,   False:np.uint16},
                   NC_INT    : {True:np.int32,   False:np.uint32},
                   NC_FLOAT  : {True:np.float32, False:np.float32},
                   NC_DOUBLE : {True:np.float64, False:np.float64},
                   }  

# define a global name for whatever char type is used in the module
ctypedef unsigned char char_type

cdef  _chars(s):
    if isinstance(s, unicode):
        # encode to the specific encoding used inside of the module
        s_ = (<unicode>s).encode('utf8')
    else:
        s_ = s
    return s_

cdef class EZMincWrapper(object):
    '''
    Wrapper around EZminc reader/writer
    '''
    cdef minc_1_reader *rdrptr
    cdef minc_1_writer *wrtptr
    cdef nc_type minc_datatype
    cdef public loaded
    cdef public np.ndarray data

    def __cinit__(self):
        self.loaded = False
        self.rdrptr = new minc_1_reader()
        self.wrtptr = new minc_1_writer()

    def __check_read_dimensions(self):
        if self.ndim(1) <= 0 or self.ndim(2) <= 0 or self.ndim(3) <= 0 or self.ndim(4) > 0:
            return False
        return True

    def __check_save_dimensions(self):
#        dims = self.data.shape
#        if len(dims) != 3:
#            return False
        return True

    def __setup_read(self, dtype=np.float32):
        if not self.__check_read_dimensions():
            raise Exception('Need a 3D minc file')
        if dtype == np.float32:
            self.rdrptr.setup_read_float()
        elif dtype == np.int32:
            self.rdrptr.setup_read_int()
        elif dtype == np.float64:
            self.rdrptr.setup_read_double()
        else:
            raise Exception('dtype not recognized', dtype)
    
    def __setup_write(self, dtype=np.float32):
        if not self.__check_save_dimensions():
            raise Exception('Need a 3D minc file')
        if dtype == np.float32:
            self.wrtptr.setup_write_float()
        elif dtype == np.float64 :
            self.wrtptr.setup_write_double()
        elif dtype == np.int32 :
            self.wrtptr.setup_write_int()
        elif dtype == np.uint32 :
            self.wrtptr.setup_write_uint()
        elif dtype == np.uint16 :
            self.wrtptr.setup_write_ushort()
        elif dtype == np.int16 :
            self.wrtptr.setup_write_short()
        elif dtype == np.uint8 or dtype == np.int8 :
            self.wrtptr.setup_write_byte()
        else:
            raise Exception('dtype not recognized', dtype)

    def __load_standard_volume(self, dtype=None):
        if dtype == np.float32:
            load_standard_volume(self.rdrptr[0], <float*>self.data.data)
        elif dtype == np.float64:
            load_standard_volume(self.rdrptr[0], <double*>self.data.data)
        elif dtype == np.int32:
            load_standard_volume(self.rdrptr[0], <int*>self.data.data)
        elif dtype == np.int16:
            load_standard_volume(self.rdrptr[0], <short*>self.data.data)
        elif dtype == np.int8:
            load_standard_volume(self.rdrptr[0], <unsigned char*>self.data.data)
        elif dtype == np.uint32:
            load_standard_volume(self.rdrptr[0], <unsigned int*>self.data.data)
        elif dtype == np.uint16:
            load_standard_volume(self.rdrptr[0], <unsigned short*>self.data.data)
        elif dtype == np.uint8:
            load_standard_volume(self.rdrptr[0], <unsigned char*>self.data.data)
        else:
            raise Exception('dtype not recognized', dtype)

    def __make_contiguous(self):
        cdef np.ndarray contdata
        if not self.data.flags['C_CONTIGUOUS']:
            # Array is not contiguous, need to make contiguous copy
            contdata = self.data.copy(order='C')
        else:
            contdata = self.data
        return contdata

    def __save_standard_volume(self, dtype=None):
        cdef np.ndarray contdata = self.__make_contiguous()
        if dtype == np.float32:
            save_standard_volume(self.wrtptr[0], <float*>contdata.data)
        elif dtype == np.int32:
            save_standard_volume(self.wrtptr[0], <int*>contdata.data)
        elif dtype == np.uint32:
            save_standard_volume(self.wrtptr[0], <unsigned int*>contdata.data)
        elif dtype == np.float64:
            save_standard_volume(self.wrtptr[0], <double*>contdata.data)
        elif dtype == np.int16:
            save_standard_volume(self.wrtptr[0], <int*>contdata.data)
        elif dtype == np.uint16:
            save_standard_volume(self.wrtptr[0], <unsigned int*>contdata.data)
        elif dtype == np.int8:
            save_standard_volume(self.wrtptr[0], <unsigned char*>contdata.data)
        elif dtype == np.uint8:
            save_standard_volume(self.wrtptr[0], <unsigned char*>contdata.data)
        else:
            raise Exception('dtype not recognized', dtype)

    def __init_ndarray(self, dtype=None):
        """ Initialize the minc image as a numpy array with dimensions T Z Y X V in that order"""
        cdef int total_size = self.total_size()
        
        if not dtype:
            dtype = self.np_datatype()
        
        self.data = np.zeros(total_size, dtype=dtype, order='C')
        self.__setup_read(dtype=dtype)
        self.__load_standard_volume(dtype=dtype)
        self.data = self.data.reshape((self.ndim(3),self.ndim(2),self.ndim(1)))
        return self.data

    def close(self):
        (<minc_1_base*>self.rdrptr).close()

    def load(self, fname=None, dtype=None, positive_directions=False, metadata_only=False, rw=False):
        ''' Load the mincfile into a numpy array'''
        _fname = _chars(fname) if fname is not None else None
        self.rdrptr.open(<char*?>_fname, positive_directions, metadata_only, rw)
        self.minc_datatype = (<minc_1_base*>self.rdrptr).datatype()
        if not metadata_only:
            self.__init_ndarray(dtype=dtype)
            self.loaded = True
    
    def save(self, fname=None, imitate=None, dtype=None, history=None):
        ''' Write a numpy array in a mincfile'''
        _fname = _chars(fname) if fname is not None else None
        _imitate = _chars(imitate) if imitate is not None else None
        self.wrtptr.open(<char*?>_fname, <char*?>_imitate)
# Works but then the rdrptr destructor fails
#        else:
#            self.wrtptr.open(<char*?>fname, <minc_1_base>self.rdrptr[0])
        if history is not None:
            if isinstance(history, six.string_types):
                _history=_chars(history)
                self.wrtptr.append_history(<const char*?>_history)
            else: # assume it's a list
                for i in history:
                    _i=_chars(i)
                    self.wrtptr.append_history(<const char*?>_i)

        self.__setup_write(dtype=dtype)
        self.__save_standard_volume(dtype=dtype)
        #(<minc_1_base*>self.wrtptr).close()
        del self.wrtptr
        self.wrtptr = new minc_1_writer()
    
    def append_history(self, comment):
        ''' Append history to the mincfile'''
        _comment=_chars(comment)
        self.wrtptr.append_history(<char*?>_comment)
    
    def is_signed(self):
        return (<minc_1_base*>self.rdrptr).is_signed()

    def np_datatype(self):
        ''' Equivalent numpy datatype'''
        return nctype_to_numpy[self.minc_datatype][self.is_signed()]
    
    def nb_dim(self):
        return (<minc_1_base*>self.rdrptr).dim_no()
    
    def ndim(self, i):
        ''' Dimensions length: 1-x 2-y 3-z'''
        return (<minc_1_base*>self.rdrptr).ndim(i)

    def total_size(self):
        return reduce(mul, [self.ndim(i) for i in range(1, self.nb_dim()+1)])
        
    def nspacing(self, i):
        return (<minc_1_base*>self.rdrptr).nspacing(i)
    
    def nstart(self, i):
        return (<minc_1_base*>self.rdrptr).nstart(i)
    
    def ndir_cos(self, i, j):
        if not self.have_dir_cos(i):
            return None
        return (<minc_1_base*>self.rdrptr).ndir_cos(i, j)
    
    def have_dir_cos(self, i):
        return (<minc_1_base*>self.rdrptr).have_dir_cos(i)

    def datatype(self):
        return (<minc_1_base*>self.rdrptr).datatype()
    
    def is_minc2(self):
        return <bool>(<minc_1_base*>self.rdrptr).is_minc2()
    
    def history(self):
        return (<minc_1_base*>self.rdrptr).history().c_str()
    
    def parse_header(self, debug=False):
        nbvars = (<minc_1_base*>self.rdrptr).var_number()
        header = dict()
        
        for varid in range(nbvars):
            varname = (<minc_1_base*>self.rdrptr).var_name(varid)
            header[varname] = dict()
            nbattrs = (<minc_1_base*>self.rdrptr).att_number(varid)
            for attrid in range(nbattrs):
                attrname = (<minc_1_base*>self.rdrptr).att_name(varid, attrid)
                attrtype = (<minc_1_base*>self.rdrptr).att_type(varid, <char*?>attrname.c_str())

                if attrtype == NC_NAT:
                    attrvalue = np.nan
                elif attrtype == NC_BYTE:
                    attrvalue = <bytes>(<minc_1_base*>self.rdrptr).att_value_byte(<char*>varname.c_str(), attrname.c_str())
                elif attrtype == NC_CHAR:
                    attrvalue = <bytes>(<minc_1_base*>self.rdrptr).att_value_string(varname.c_str(), attrname.c_str())
                elif attrtype == NC_SHORT:
                    attrvalue = (<minc_1_base*>self.rdrptr).att_value_short(varname.c_str(), attrname.c_str())
                elif attrtype == NC_INT:
                    attrvalue = (<minc_1_base*>self.rdrptr).att_value_int(varname.c_str(), attrname.c_str())
                elif attrtype == NC_FLOAT:
                    # For unknown reason, ezminc does not have att_value_float. A bit hackish but should work.
                    attrvalue = (<minc_1_base*>self.rdrptr).att_value_double(varname.c_str(), attrname.c_str())
                elif attrtype == NC_DOUBLE:
                    attrvalue = (<minc_1_base*>self.rdrptr).att_value_double(varname.c_str(), attrname.c_str())
                else:
                    raise Exception('attribute type not recognized:{} {} {}'.format(varname, attrname, attrtype))

                if debug:
                    print("{0}:{1} = '{2}' ({3})".format(varname,attrname,attrvalue,attrtype))
                header[varname][attrname] = attrvalue
                pass


        return header

    def __dealloc__ (self):
        del self.rdrptr
        del self.wrtptr
        del self.data

cdef class input_iterator_real(object):
    cdef minc_input_iterator[double] * _it
    cdef minc_1_reader *rdrptr

    def __cinit__(self,file=None):
        if file is not None:
            _file=_chars(file)
            self.rdrptr = new minc_1_reader()
            self.rdrptr.open(<char*?>_file)
            self.rdrptr.setup_read_double()
            self._it = new minc_input_iterator[double](self.rdrptr[0])
            self._it.begin()
        else:
            self._it = NULL
            self.rdrptr = NULL
    
    def open(self,file):
        _file=_chars(file)
        if self._it != NULL:
            del self._it
        if self.rdrptr != NULL:
            del self.rdrptr
        self.rdrptr = new minc_1_reader()
        self.rdrptr.open(<char*?>_file)
        self.rdrptr.setup_read_double()
        self._it = new minc_input_iterator[double](self.rdrptr[0])
        self._it.begin()
            
    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            v=self.value()
            self._it.next()
            return v

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self):
        return self._it.value()

    def __dealloc__ (self):
        if self._it!= NULL:
            del self._it
        if self.rdrptr!= NULL:
            del self.rdrptr


cdef class input_iterator_int(object):
    cdef minc_input_iterator[int] * _it
    cdef minc_1_reader *rdrptr

    def __cinit__(self,file=None):
        if file is not None:
            _file=_chars(file)
            self.rdrptr = new minc_1_reader()
            self.rdrptr.open(<char*?>_file)
            self.rdrptr.setup_read_int()
            self._it = new minc_input_iterator[int](self.rdrptr[0])
            self._it.begin()
        else:
            self._it = NULL
            self.rdrptr = NULL
    
    def open(self,file):
        _file=_chars(file)
        if self._it != NULL:
            del self._it
        if self.rdrptr != NULL:
            del self.rdrptr
        self.rdrptr = new minc_1_reader()
        self.rdrptr.open(<char*?>_file)
        self.rdrptr.setup_read_int()
        self._it = new minc_input_iterator[int](self.rdrptr[0])
        self._it.begin()
            
    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            v=self.value()
            self._it.next()
            return v

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self):
        return self._it.value()

    def __dealloc__ (self):
        if self._it!= NULL:
            del self._it
        if self.rdrptr!= NULL:
            del self.rdrptr

cdef class output_iterator_real(object):
    cdef minc_output_iterator[float] * _it
    cdef minc_1_writer *wrtptr

    def __cinit__(self,file=None, reference=None, reference_file=None):
        self.open(file, reference=reference, reference_file=reference_file)

    def open(self,file,input_iterator_real reference=None, reference_file=None):
        if self._it != NULL:
            del self._it
        if self.wrtptr != NULL:
            del self.wrtptr
        self.wrtptr = new minc_1_writer()
        _file=_chars(file)
        if reference is not None:
            self.wrtptr.open(<char*?>_file, reference.rdrptr[0])
        else:
            _reference_file=_chars(reference_file)
            self.wrtptr.open(<char*?>_file, <char*?>_reference_file)

        self.wrtptr.setup_write_float()
        self._it = new minc_output_iterator[float](self.wrtptr[0])
        self._it.begin()

    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            self._it.next()
            return 0

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self, float value):
        self._it.value(value)

    def __dealloc__ (self):
        if self._it != NULL:
            del self._it
        if self.wrtptr != NULL:
            del self.wrtptr

    def progress(self):
        return self._it.progress()



cdef class output_iterator_int(object):
    cdef minc_output_iterator[int] * _it
    cdef minc_1_writer *wrtptr

    def __cinit__(self,file=None, reference=None, reference_file=None):
        self.open(file, reference=reference, reference_file=reference_file)

    def open(self,file,input_iterator_int reference=None,reference_file=None):
        if self._it != NULL:
            del self._it
        if self.wrtptr != NULL:
            del self.wrtptr
        
        self.wrtptr = new minc_1_writer()
        _file=_chars(file)
        if reference is not None:
            self.wrtptr.open(<char*?>_file,reference.rdrptr[0])
        else:
            _reference_file=_chars(reference_file)
            self.wrtptr.open(<char*?>_file,<char*?>_reference_file)
            
        self.wrtptr.setup_write_int()
        self._it = new minc_output_iterator[int](self.wrtptr[0])
        self._it.begin()

    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            self._it.next()
            return 0

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self,value):
        self._it.value(<int?>value)

    def __dealloc__ (self):
        if self._it != NULL:
            del self._it
        if self.wrtptr != NULL:
            del self.wrtptr

    def progress(self):
        return self._it.progress()


cdef class parallel_input_iterator:
    cdef minc_parallel_input_iterator _it
    
    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            self._it.next()
            return 0

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self,np.ndarray ret=None):
        if ret is None:
            ret=np.ndarray([self._it.dim()],dtype=np.float64,order='C')

        self._it.value(<double*>ret.data)
        return ret
    
    def value_mask(self):
        return self._it.mask_value()
    
#    def py_value(self,vector[double] ret):
#        self._it.value(ret)
#        return ret

    def open(self,vector[string] output,string mask="".encode('utf8')):
        self._it.open(output,mask)


    def dim(self):
        return self._it.dim()

    def progress(self):
        return self._it.progress()


cdef class parallel_output_iterator:
    cdef minc_parallel_output_iterator _it
    
    def __iter__(self):
        return self

    def __next__(self):
        if self._it.last():
            raise StopIteration
        else:
            self._it.next()
            return 0

    def begin(self):
        self._it.begin()

    def last(self):
        return self._it.last()

    def value(self,np.ndarray v):
        self._it.value(<double*>v.data)
        
    def dim(self):
        return self._it.dim()
        
#    def py_value(self,vector[double] ret):
#        self._it.value(ret)

    def open(self,vector[string] output,string ref):
        cdef minc_1_reader rdr
        rdr.open(<char*?>ref.c_str(),True,True)
        self._it.open(output,rdr.info())

    def progress(self):
        return self._it.progress()

xfm_entry=namedtuple('xfm_entry',['lin','inv','trans'])
xfm_param=namedtuple('xfm_param',['center','translations','rotations','scales','shears'])

def xfm_identity_transform_par():
    return xfm_param(np.zeros(3, 'float64','C'),
                     np.zeros(3, 'float64','C'),
                     np.zeros(3, 'float64','C'),
                     np.ones (3, 'float64','C'),
                     np.zeros(3, 'float64','C'))

def xfm_identity_transform_mat():
    return np.eye(4)

def xfm_identity():
    return xfm_entry(True, False, xfm_identity_transform_mat())

cdef object read_one_transform(VIO_General_transform * _xfm):
    cdef VIO_Transform_types _tt
    cdef VIO_Transform *lin
    
    _tt=get_transform_type(_xfm)
    
    if _tt==LINEAR:
        lin = get_linear_transform_ptr(_xfm);

        x = np.zeros((4,4), 'float64','C')

        for i in range(4):
            for j in range(4):
                x[i,j] = lin.m[j][i]

        return [xfm_entry(True, (_xfm.inverse_flag==1), x)]
        
    elif _tt==GRID_TRANSFORM:
        return [xfm_entry(False, (_xfm.inverse_flag==1), _xfm.displacement_volume_file )]
        
    elif _tt==CONCATENATED_TRANSFORM:
        transforms=[]
        for i in range( get_n_concated_transforms(_xfm)):
            transforms.extend( read_one_transform(get_nth_general_transform(_xfm, i)) )
        return transforms
    else:
        raise Exception('Unsupoorted transformation type:{}'.format(_tt))

def read_xfm(input_xfm):
    cdef VIO_General_transform _xfm
    _input_xfm=_chars(input_xfm)
    if input_transform_file(<char*?>_input_xfm, &_xfm) != VIO_OK:
        raise Exception('Unable to open {}'.format(input_xfm))
    x=read_one_transform(&_xfm)
    delete_general_transform(&_xfm)
    return x

def write_xfm(output_xfm, trans, comment=None):
    cdef VIO_General_transform _xfm
    cdef VIO_General_transform x
    cdef VIO_Transform lin
    cdef VIO_General_transform concated
    cdef VIO_Status wrt 
    
    for (k,t) in enumerate(trans):
        if t.lin: # it's linear transform
            for i in range(4):
                for j in range(4):
                    lin.m[j][i]=t.trans[i,j]
            
            create_linear_transform(&x, &lin)
        else:
            create_grid_transform_no_copy( &x, <VIO_Volume>NULL, <char *>t.trans )
            #TODO: copy files (?)
        if t.inv:
            x.inverse_flag=1
        else:
            x.inverse_flag=0

        if k>0:
            concat_general_transforms( &_xfm, &x, &concated )
            _xfm=concated
        else:
            _xfm=x
    if comment is None:
        comment="PyEZMINC {}".format(repr(trans))
    _comment=_chars(comment)
    _output_xfm=_chars(output_xfm)
    wrt = output_transform_file(<char*>_output_xfm,<char*>_comment,<VIO_General_transform*>&_xfm)
    delete_general_transform(&_xfm)

    if wrt!=VIO_OK:
        raise Exception('Unable to write {}'.format(output_xfm))

def xfm_to_param(trans):
    cdef np.ndarray tt=None
    inv=False

    if isinstance(trans, np.ndarray):
        tt=np.asarray(trans,'float64','C')
    if isinstance(trans, np.matrix):
        tt=np.asarray(trans,'float64','C')
    elif isinstance(trans, list):
        if len(trans)!=1:
            raise Exception('xfm_to_param supports a single transform only')
        if not trans[0].lin:
            raise Exception('xfm_to_param supports a linear transform only')
        tt=np.asarray(trans[0].trans,'float64','C')
        inv=trans[0].inv

    if inv:
        tt=np.linalg.inv(tt)

    cdef np.ndarray center=np.zeros(3,'float64','C')
    cdef np.ndarray translations=np.zeros(3,'float64','C')
    cdef np.ndarray rotations=np.zeros(3,'float64','C')
    cdef np.ndarray scales=np.zeros(3,'float64','C')
    cdef np.ndarray shears=np.zeros(3,'float64','C')

    if matrix_extract_linear_param(<double*> tt.data, <double*> center.data, <double*> translations.data, <double*> scales.data, <double*> shears.data, <double*> rotations.data)!=0:
        raise Exception('xfm_to_param transformation failed')

    rotations*=180.0/3.1415927

    return xfm_param(center, translations, rotations, scales, shears)

def param_to_xfm(par):
    cdef np.ndarray center=np.asarray(par.center,'float64','C')
    cdef np.ndarray translations=np.asarray(par.translations,'float64','C')
    cdef np.ndarray rotations=np.asarray(par.rotations,'float64','C').copy()
    cdef np.ndarray scales=np.asarray(par.scales,'float64','C')
    cdef np.ndarray shears=np.asarray(par.shears,'float64','C')

    cdef np.ndarray tt = np.zeros((4,4), 'float64','C')

    rotations*=3.1415927/180.0

    if linear_param_to_matrix(<double*> tt.data, <double*>center.data, <double*>translations.data, <double*>scales.data, <double*>shears.data,<double*>rotations.data)!=0:
        raise Exception('param_to_xfm transformation failed')

    return xfm_entry(True, False, tt)

def check_xfm_components(trans, eps=1e-6):
    """
    Checks XFM transform for non-identity linear transforms and non-linear transforms
    :param trans:
    :return: tuple N_lin,N_nl  -
    """
    _identity = xfm_identity_transform_mat()
    _N_lin = 0
    _N_nl = 0
    for i,j in enumerate(trans):
        if j.lin and np.linalg.norm(j.trans-_identity)>=eps:
            _N_lin +=1
        elif not j.lin :
            _N_nl +=1

    return _N_lin,_N_nl

def reduce_xfm_components(trans, eps=1e-6):
    """
    Removes identity transforms
    :param trans:
    :param eps:
    :return: transform object with identity parts removed, still returns identity transforms if input is identity
    """
    _identity = xfm_identity_transform_mat()
    _out = []

    for i,j in enumerate(trans):
        if j.lin and np.linalg.norm(j.trans-_identity)>=eps:
            _out.append(j)
        elif not j.lin :
            _out.append(j)

    if len(_out)==0:
        _out=[xfm_identity()]

    return _out


# kate: space-indent on; indent-width 4; indent-mode python;replace-tabs on;word-wrap-column 80;show-tabs on;hl python
