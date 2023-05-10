#pragma once

#include <string>
#include <memory>
#include <vector>
#include <stdexcept>
#include <type_traits>
#include <algorithm>
#define DR_WAV_IMPLEMENTATION
#include "dr_wav.h"
using namespace std;

template <typename SAMPLE>
class WavReader
{
    public:
        void attachFile(const char* file) { attachFile(string(file)); }
        void attachFile(const string& file)
        {
           // unifile.reset( sf_open(file.c_str(), SFM_READ, &fileInfo));
           unifile.reset( drwav_open_file(file.c_str()));
           if (!unifile)
                throw std::runtime_error("Could not open file");
           // sf_command (unifile.get(), SFC_SET_NORM_FLOAT, NULL, SF_FALSE);
           // sf_command (unifile.get(), SFC_SET_NORM_DOUBLE, NULL, SF_FALSE);
        }

        drwav_uint64 getReadPos() { return unifile->compressed.iCurrentSample; }
        drwav_uint64 getNumSamples() { return unifile->totalSampleCount/unifile->channels; }
        int getNumChannels() { return (int) unifile->channels; }
        int getSampleRate() { return (int) unifile->sampleRate; }
        // drwav_fmt getFormat(){return unifile->fmt;}

        size_t readSamples(vector<vector<SAMPLE>>& v, size_t numSamplesToRead = 0)
        {
            int reqChannels = v.size();
            size_t reqSamples = max_element(v.begin(),v.end(),
                    [](const auto& v1,const auto& v2){ return v1.size() < v2.size();})[0].size();

            if (numSamplesToRead > 0)
                reqSamples = min(reqSamples,numSamplesToRead);

            size_t samplesRead = 0;
            int chNo = getNumChannels();
            if(buffer.size() != reqSamples*chNo)
                buffer.resize(reqSamples*chNo);

            samplesRead = drwav_read_f32(unifile.get(), reqSamples*chNo, buffer.data());

            for(int ch = 0; ch < min(chNo,reqChannels); ch++)
                for(size_t l = 0; l < min((size_t)samplesRead,v[ch].size()); l++)
                    v[ch][l] = static_cast<SAMPLE>( buffer[chNo*l+ch]);

            return samplesRead;
        }

        WavReader(const string& file){ attachFile(file);}
    private:
        //unique_ptr<SNDFILE,void(*)(SNDFILE*)> unifile{ nullptr,[](auto* p){ sf_close(p);}};
        unique_ptr<drwav,void(*)(drwav*)> unifile{ nullptr,[](auto* p){ drwav_close(p);}};
        vector<float> buffer;

    // Make non-copyable
    WavReader(const WavReader& a) = delete;
    WavReader& operator=(const WavReader& a) = delete;
    static_assert( is_floating_point<SAMPLE>::value,
                   "Only double and float can be used as sample datatype");
};

template <typename SAMPLE>
class WavWriter
{
    public:
        void attachFile(const char* file) { attachFile(string(file)); }
        void attachFile(const string& file)
        {

           // unifile.reset( sf_open(file.c_str(), SFM_WRITE, &fileInfo));
           unifile.reset( drwav_open_file_write(file.c_str(), &format));
           if (!unifile)
                throw std::runtime_error("Could not open file");
           // sf_command (unifile.get(), SFC_SET_NORM_FLOAT, NULL, SF_FALSE);
           // sf_command (unifile.get(), SFC_SET_NORM_DOUBLE, NULL, SF_FALSE);
        }

        drwav_uint64 getWritePos() { return unifile->compressed.iCurrentSample; }
        drwav_uint64 getNumSamples() { return unifile->totalSampleCount/unifile->channels; }
        int getNumChannels() { return (int) unifile->channels; }
        int getSampleRate() { return (int) unifile->sampleRate; }

        size_t writeSamples(vector<vector<SAMPLE>>& v, size_t numSamplesToWrite = 0)
        {
            int reqChannels = v.size();
            size_t reqSamples = max_element(v.begin(),v.end(),
                    [](const auto& v1,const auto& v2){ return v1.size() < v2.size();})[0].size();

            if (numSamplesToWrite > 0)
                reqSamples = min(reqSamples,numSamplesToWrite);

            size_t writtenSamples = 0;
            int chNo = getNumChannels();
            if(buffer.size() != reqSamples*chNo)
                buffer.resize(reqSamples*chNo);

            for(int ch = 0; ch < min(chNo,reqChannels); ch++)
                for(size_t l = 0; l < v[ch].size(); l++)
                   buffer[chNo*l+ch] = (drwav_int16) ( v[ch][l] * SHRT_MAX );

            // writtenSamples = fwd_writeSamples(unifile.get(), buffer.data(), reqSamples*chNo);
            writtenSamples = drwav_write(unifile.get(), reqSamples*chNo, buffer.data() );

            return writtenSamples;
        }

        WavWriter(const string& file, int samplerate, int channels ):
                  format{drwav_container_riff,DR_WAVE_FORMAT_PCM,
                         static_cast<drwav_uint32>(channels),
                         static_cast<drwav_uint32>(samplerate),16}
                  { attachFile(file);}
    private:
        unique_ptr<drwav,void(*)(drwav*)> unifile{ nullptr,[](auto* p){ drwav_close(p);}};
        // unique_ptr<SNDFILE,void(*)(SNDFILE*)> unifile{ nullptr,[](auto* p){ sf_close(p);}};
        // SF_INFO fileInfo;
        vector<drwav_int16> buffer;
        drwav_data_format format;

    // Make non-copyable
    WavWriter(const WavWriter& a) = delete;
    WavWriter& operator=(const WavWriter& a) = delete;
    static_assert( is_floating_point<SAMPLE>::value,
                   "Only double and float can be used as sample datatype");
};



