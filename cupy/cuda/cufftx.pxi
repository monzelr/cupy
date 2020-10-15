# distutils: language = c++

from libc.stdint cimport intptr_t

from cupy.cuda.cufft cimport Handle, Result, Plan1d, PlanNd
from cupy.cuda.cufft import check_result


cdef extern from 'cufftXt.h' nogil:
    # cuFFT callback
    ctypedef enum callbackType 'cufftXtCallbackType':
        pass
    Result cufftXtSetCallback(Handle, void**, int, void**)
    ctypedef enum fft_type 'cufftType':
        pass
    Result cufftPlan1d(Handle*, int, fft_type, int)
    Result cufftMakePlan1d(Handle, int, fft_type, int, size_t*)
    ctypedef struct Complex 'cufftComplex':
        float x, y

    ctypedef struct DoubleComplex 'cufftDoubleComplex':
        double x, y
    Result cufftExecC2C(Handle plan, Complex *idata, Complex *odata,
                        int direction)
    Result cufftCreate(Handle *plan)
    int CUFFT_FORWARD
    ctypedef Complex (*cufftCallbackLoadC)(void*, size_t, void*, void*)


cdef extern from 'cupy_cufftx.h' nogil:
    Result set_callback(Handle plan, int cb_type, bint cb_load)


cpdef intptr_t createPlan(object plan):
    cdef Handle h
    cdef str plan_type
    cdef tuple plan_args
    cdef int result

    if not isinstance(plan, tuple):
        raise NotImplementedError
    plan_type, plan_args = plan
    if plan_type == 'Plan1d':
        result = cufftPlan1d(&h, plan_args[0], plan_args[1], plan_args[2])
        check_result(result)
    elif plan_type == 'PlanNd':
        pass
    #    result = cufftPlanMany(Handle plan, int rank, int *n, int *inembed,
    #                     int istride, int idist, int *onembed, int ostride,
    #                     int odist, Type type, int batch,
    #                     size_t *workSize)
    #    pN = PlanNd(plan.shape,
    #                plan.inembed, plan.istride, plan.idist,
    #                plan.onembed, plan.ostride, plan.odist,
    #                plan.fft_type, plan.batch, plan.order, plan.last_axis, plan.last_size)
    #    h = pN.handle
    else:
        raise NotImplementedError
    return <intptr_t>h


cpdef intptr_t setCallback(intptr_t plan, int cb_type, bint is_load):
    cdef Handle h = <Handle>plan
    with nogil:
        result = set_callback(h, <callbackType>cb_type, is_load)
    check_result(result)


cpdef transform(intptr_t plan, intptr_t idata, intptr_t odata):
    cdef Handle h = <Handle>plan
    cdef int result

    print("start")
    with nogil:
        result = cufftExecC2C(h, <Complex*>idata, <Complex*>odata, CUFFT_FORWARD)
    check_result(result)
    print("end")
