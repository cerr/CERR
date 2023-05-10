#include "ltfat.h"

class DGTProcessor
{
public:
    class Callback
    {
    public:
        virtual int callback(const std::complex<float> in[],
                             const int M2, const int W,
                             std::complex<float> out[]) noexcept = 0;
    };

    DGTProcessor(LTFAT_FIRWIN win, int gl, int a, int M, int Wmax)
    {
        processor_struct = rtdgtreal_processor_wininit_s( g, gl, a, M, Wmax, nullptr, nullptr);
        if (!processor_struct)
            throw std::invalid_argument();
    }

    DGTProcessor(LTFAT_FIRWIN win, int gl, int a, int M, int Wmax, DGTProcessor::Callback callback):
        DGTProcessor(win, gl, a, M, Wmax)
    {
        registerCallback(callback);
    }


    virtual ~DGTProcessor()
    {
        if (processor_struct)
            rtdgtreal_processor_done_s(processor_struct);
    }

    void registerCallback(DGTProcessor::Callback* callback)
    {
        rtdgtreal_processor_setcallback_s( processor_struct, DGTProcessor::callbackWrapper, static_cast<void*>(callback));
    }

    int process(const float in[], int bufLen, float out[]) noexcept
    {
        rtdgtreal_processor_execute_s(processor_struct, in, bufLen, out);
    }

private:
    rtdgtreal_processor_s* processor_struct{ nullptr };

    static void callbackWrapper(
        void* userdata, const float in[][2], const int M2, const int W, float out[][2])
    {
        static_cast<DGTProcessor::Callback*>(userdata)->callback(
            reinterpret_cast<const std::complex<float>*>(in), M2, W,
            reinterpret_cast<std::complex<float>*>(out));
    }
};

class SimpleDGTProcessorCallback : public DGTProcessor::Callback
{
public:
    int callback(
        const std::complex<float> in[],
        const int M2, const int W,
        std::complex<float> out[]) noexcept
    {
        std::copy_n(in, M2 * W, out);
    }
};
