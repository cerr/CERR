#include "ltfathelper.h"
#include "cxxopts.hpp"
#include "wavhandler.h"
#include <algorithm>


template<class T>
using uni_ptrdel = unique_ptr<T, void(*)( T*)>;

int main(int argc, char* argv[])
{
    if (!ltfat_int_is_compatible(sizeof(int)))
    {
        std::cout << "Incompatible size of int. libltfat was probably"
                     " compiled with -DLTFAT_LARGEARRAYS" << std::endl;
        exit(1);
    }

    string inFile, outFile, resFile;
    double targetsnrdb = 40;
    double atprodreltoldb = -80;
    size_t maxit = 0, maxat = 0;
    double seglen = 0.0;
    double kernthr = 1e-4;
    vector<tuple<string,int,int,int,int>> dicts;
    size_t numSamples = 0;
    int numChannels = 0;
    int sampRate = 0;
    bool do_pedanticsearch = false;
    bool do_verbose = false;
    int alg = ltfat_dgtmp_alg_mp;

    try
    {
        string examplestr{"Usage:\n" + 
            string(argv[0]) + " -d win,a,M input.wav"
            + "\nExample:\n" +
            string(argv[0]) + " -d HANN,512,2048 input.wav"
        };
        cxxopts::Options options(argv[0], "\nMatching Pursuit Decomposition with Multi-Gabor dictionaties");
        options
        .positional_help("-s snr -d win,a,M[:win2,a2,M2:...] input.wav"
                         "\n\nPerforms matching pursuit decomposition of input.wav using"
                         " given (multi-)Gabor dictionary such that the target SNR is"
                         " snr.")
        .show_positional_help();

        options.add_options()
        ("i,input", "Input *.wav filei (REQUIRED)", cxxopts::value<string>())
        ("o,output","Output *.wav file", cxxopts::value<string>())
        ("r,residual","Residual *.wav file", cxxopts::value<string>() )
        ("d,dict","Dictionary specification (REQUIRED). Format: win1,hop1,channels1:win2,hop2,channels2. "
                  "Example: blackman,512,2048:blackman,256,1024:... Supported windows are: blackman, hann",
                  cxxopts::value<string>() )
        ("s,snr", "Target signal-to-noise ratio in dB",
         cxxopts::value<double>()->default_value(to_string(targetsnrdb)))
        ("atprodtol", "Relative inner product tolerance in dB",
         cxxopts::value<double>()->default_value(to_string(atprodreltoldb)))
        ("maxit", "Maximum number of iterations", cxxopts::value<size_t>() )
        ("maxat", "Maximum number of atoms", cxxopts::value<size_t>() )
        ("alg", "MP algorithm. Available: mp(default),cyclicmp,selfprojmp", cxxopts::value<string>() )
        ("kernthr", "Kernel truncation threshold",
         cxxopts::value<double>()->default_value(to_string(kernthr)))
        ("seglen", "Segment length in seconds. 0 disables the segmentation.",
         cxxopts::value<double>()->default_value(to_string(seglen)) )
        ("pedanticsearch", "Enables pedantic search. Pedantic search is always enabled for cyclic MP.",
         cxxopts::value<bool>(do_pedanticsearch) )
        ("verbose", "Print additional information.",
         cxxopts::value<bool>(do_verbose) )
        ("help", "Print help");

        options.parse_positional({"input"});

        auto result = options.parse(argc, argv);

        if (result.count("help"))
        {
            cout << options.help({""}) << endl;
            exit(0);
        }

        if (result.count("input"))
        {
            inFile = result["input"].as<string>();
            try
            {
                WavReader<LTFAT_REAL> wrtmp{inFile};
                numSamples = wrtmp.getNumSamples();
                numChannels = wrtmp.getNumChannels();
                sampRate = wrtmp.getSampleRate();
                if( numSamples == 0)
                {
                    cout << "Empty input wav file" << endl;
                    exit(1);
                }
            }
            catch(...)
            {
                cout << "Cannot open " << inFile << endl;
                exit(1);
            }
        }
        else
        {
            cout << "No input file specified." << endl;
            cout << examplestr << endl;
            exit(1);
        }

        if (result.count("output"))
            outFile = result["output"].as<string>();

        if (result.count("residual"))
            resFile = result["residual"].as<string>();

        if(result.count("seglen"))
        {
            seglen =  result["seglen"].as<double>();
            if(seglen < 0.0)
            {
                cout << "seglen must be greater than 0." << endl;
                exit(1);
            }
        }

        if (result.count("atprodtol"))
        {
            atprodreltoldb = result["atprodtol"].as<double>();
            if(atprodreltoldb > 0)
            {
                cout << "The relative inner product tolernace must be less than 0 dB." << endl;
                exit(1);
            }
        }

        if (result.count("snr"))
        {
            targetsnrdb = result["snr"].as<double>();
            if(targetsnrdb < 0)
            {
                cout << "Target SNR must be greater than 0 dB." << endl;
                exit(1);
            }
        }

        if (result.count("alg"))
        {
            string algstr = result["alg"].as<string>();
            if( algstr.compare("mp") == 0 ) alg = ltfat_dgtmp_alg_mp;
            else if( algstr.compare("cyclicmp") == 0 ) alg = ltfat_dgtmp_alg_loccyclicmp;
            else if( algstr.compare("selfprojmp") == 0 ) alg = ltfat_dgtmp_alg_locselfprojmp;
            else
            {
                cout << "Unrecognized algorithm." << endl;
                exit(1);
            }
        }

        if (result.count("dict"))
        {
             string toparse = result["dict"].as<string>() + ":";

             int pos;
             while ((pos = toparse.find(":")) != -1)
             {
                 string dictstr = toparse.substr(0,pos);
                 toparse = toparse.substr(pos+1,toparse.size()-pos);
                 if( !dictstr.empty() )
                 {
                    dictstr += ",";
                    vector<string> dictvec;
                    int pos2;
                    while ((pos2 = dictstr.find(",")) != -1)
                    {
                        string itemstr = dictstr.substr(0,pos2);
                        dictstr = dictstr.substr(pos2+1,dictstr.size()-pos2);
                        if( !itemstr.empty())
                            dictvec.push_back(itemstr);
                    }
                    if(dictvec.size() != 3 && dictvec.size() != 4)
                    {
                        cout << "Parse error: Dictionary should consist of 3 or 4 items: win,a,M or win,a,M,gl" << endl;
                        exit(1);
                    }
                    transform(dictvec[0].begin(), dictvec[0].end(), dictvec[0].begin(), ::tolower);
                    int winenum = -1;
                    if( 0 > (winenum = ltfat_str2firwin(dictvec[0].c_str())) )
                    {
                       cout << "Parse error: Window " << dictvec[0]
                            << " not recognized." << endl;
                       exit(1);
                    }
                    if(dictvec.size() == 3)
                        dicts.push_back(make_tuple(dictvec[0],winenum,stoi(dictvec[1]),stoi(dictvec[2]),stoi(dictvec[2])));
                    else if(dictvec.size() == 4)
                        dicts.push_back(make_tuple(dictvec[0],winenum,stoi(dictvec[1]),stoi(dictvec[2]),stoi(dictvec[3])));
                 }
             }
        }
        else
        {
            cout << "No dictionary specified." << endl;
            cout << examplestr << endl;
            exit(1);
        }

        if (!result.count("maxat"))
            maxat = (size_t) (numSamples);
        else
            maxat = result["maxat"].as<size_t>();

        if (!result.count("maxit"))
            maxit = (size_t) numSamples;
        else
            maxit =  result["maxit"].as<size_t>();

        if(maxat == 0) maxat = maxit;
        if(maxit == 0) maxit = 2*maxat;

        if (result.count("kernthr"))
        {
            kernthr = result["kernthr"].as<double>();
        }
    }
    catch (const cxxopts::OptionException& e)
    {
        std::cout << "error parsing options: " << e.what() << std::endl;
        exit(1);
    }


    LTFAT_NAME(dgtrealmp_parbuf)* pbuf = NULL;
    LTFAT_NAME(dgtrealmp_parbuf_init)(&pbuf);
    auto unipb = uni_ptrdel<LTFAT_NAME(dgtrealmp_parbuf)>(
    pbuf,[](auto* p){ LTFAT_NAME(dgtrealmp_parbuf_done)(&p); });

    // LTFAT_NAME(dgtrealmp_setparbuf_alg)(pbuf, ltfat_dgtmp_alg_LocOMP);

    for(auto dict:dicts)
    {
       if( 0 > LTFAT_NAME(dgtrealmp_parbuf_add_firwin)(pbuf, (LTFAT_FIRWIN)(get<1>(dict)), get<4>(dict), get<2>(dict), get<3>(dict)))
       {
          cout << "Bad dictionary: " << get<0>(dict) << "," << get<2>(dict)  << "," << get<3>(dict) << endl;
          exit(1);
       }
    }

    if( seglen == 0.0 || numSamples <= seglen*sampRate )
    {
        ltfat_int L = LTFAT_NAME(dgtrealmp_getparbuf_siglen)(pbuf, numSamples);

        LTFAT_NAME(dgtrealmp_setparbuf_phaseconv)(pbuf, LTFAT_TIMEINV);
        LTFAT_NAME(dgtrealmp_setparbuf_pedanticsearch)(pbuf, do_pedanticsearch);
        LTFAT_NAME(dgtrealmp_setparbuf_atprodreltoldb)(pbuf, atprodreltoldb);
        LTFAT_NAME(dgtrealmp_setparbuf_snrdb)(pbuf, targetsnrdb);
        LTFAT_NAME(dgtrealmp_setparbuf_kernrelthr)(pbuf, kernthr);
        LTFAT_NAME(dgtrealmp_setparbuf_maxatoms)(pbuf, maxat);
        LTFAT_NAME(dgtrealmp_setparbuf_maxit)(pbuf, maxit);
        LTFAT_NAME(dgtrealmp_setparbuf_iterstep)(pbuf, L);
        LTFAT_NAME(dgtrealmp_setparbuf_alg)(pbuf, static_cast<ltfat_dgtmp_alg>(alg));

        vector<vector<LTFAT_REAL>> f(numChannels);
        for(auto& fEl:f) fEl = vector<LTFAT_REAL>(L,0.0);

        vector<vector<LTFAT_REAL>> fout(numChannels);
        for(auto& fEl:fout) fEl = vector<LTFAT_REAL>(L);

        vector<unique_ptr<LTFAT_COMPLEX[]>> coef;

        for (int pidx = 0; pidx < LTFAT_NAME(dgtrealmp_getparbuf_dictno)(pbuf); pidx++ )
        {
            ltfat_int clen = LTFAT_NAME(dgtrealmp_getparbuf_coeflen)(pbuf, numSamples, pidx);
            coef.push_back( unique_ptr<LTFAT_COMPLEX[]>(new LTFAT_COMPLEX[clen]) );
        }

        {
            WavReader<LTFAT_REAL> wr{inFile};
            wr.readSamples(f);
        }

        LTFAT_NAME(dgtrealmp_state)*  plan = NULL;
        auto t1 = Clock::now();
        if( 0 != LTFAT_NAME(dgtrealmp_init)( pbuf, L, &plan)) return -1;
        auto t2 = Clock::now();
        int dur = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
        cout << "INIT DURATION: " << dur << " ms" << std::endl;
        auto uniplan = uni_ptrdel<LTFAT_NAME(dgtrealmp_state)>(
        plan,[](auto* p){ LTFAT_NAME(dgtrealmp_done)(&p); });

        for (int nCh=0;nCh<numChannels;nCh++)
        {
            t1 = Clock::now();
            int status = LTFAT_NAME(dgtrealmp_execute_decompose)(plan, f[nCh].data(), (LTFAT_COMPLEX**) coef.data());
            t2 = Clock::now();
            dur = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
            cout << "DURATION: " << dur << " ms" << std::endl;

            t1 = Clock::now();
            LTFAT_NAME(dgtrealmp_execute_synthesize)(plan, (const LTFAT_COMPLEX**) coef.data(), NULL, fout[nCh].data());
            t2 = Clock::now();
            int dur2 = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
            cout << "SYN DURATION: " << dur2 << " ms" << std::endl;

            size_t atoms; LTFAT_NAME(dgtrealmp_get_numatoms)(plan, &atoms);
            size_t iters; LTFAT_NAME(dgtrealmp_get_numiters)(plan, &iters);
            LTFAT_REAL snr; LTFAT_NAME(snr)(f[nCh].data(), fout[nCh].data(), L, &snr);

            cout << "atoms=" << atoms << ", iters=" << iters << ", SNR=" << snr << " dB"
                 << ", perit=" << 1000.0 * dur / ((double)iters) << "us, exit code=" << status <<endl;

        }

        if(!outFile.empty())
        {
            WavWriter<LTFAT_REAL> ww{outFile,sampRate,(int)fout.size()};
            ww.writeSamples(fout);
        }

        if(!resFile.empty())
        {
            for(size_t nCh=0;nCh<fout.size();nCh++)
                for(size_t l=0;l<fout[nCh].size();l++)
                    fout[nCh][l] =  f[nCh][l] - fout[nCh][l];

            WavWriter<LTFAT_REAL> ww{resFile,sampRate,(int)fout.size()};
            ww.writeSamples(fout);
        }
    }
    else
    {
        cout << "Segment-wise processing is not supported yet." << endl;
    }
    return 0;
}
