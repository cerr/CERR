#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#   This script searches all directories listed in dirs (relative to ltfatroot)
#   for occurrence of ltfatarghelper and replaces it with a defined code.
#    
#

from __future__ import print_function
import os
import sys
from collections import defaultdict

# Directories to search (relative to ltfat root)
dirs = ('','auditory','blockproc','demos','filterbank','fourier','frames','gabor',
        'nonstatgab','operators','quadratic','reference','signals','sigproc','wavelets')
#dirs = ('g1','g2','g3')

def query_yes_no(question, default="no"):
    """Ask a yes/no question via raw_input() and return their answer.
    
    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is one of "yes" or "no".
    """
    valid = {"yes":True,   "y":True,  "ye":True,
             "no":False,     "n":False}
    if default == None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while 1:
        sys.stdout.write(question + prompt)
        choice = raw_input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid.keys():
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "\
                             "(or 'y' or 'n').\n")


def main():
    ltfatroot = os.path.join(os.path.dirname(os.path.realpath(__file__)),os.pardir)

    mfileswithltfatarghelper = defaultdict(list)

    for directory in dirs:
        files = list( x for x in os.listdir(os.path.join(ltfatroot,directory)) if x.endswith('.m') )
        for ff in files:
            if ff == 'ltfatarghelper.m': continue
            fullpath = os.path.join(ltfatroot,os.path.join(directory,ff))
            with open(fullpath,'r') as f:
                flines = f.readlines()
                for lineNo,line in enumerate(flines):
                    if 'ltfatarghelper' in line and not line.startswith('%'):
                        if '%MARKER' in line or 'error' in line: break # Do not use this file 
                        mfileswithltfatarghelper[fullpath].append(lineNo)
                        print('Found in file {}:\n   {}'.format(ff,line))

    #for k,v in mfileswithltfatarghelper.items():
    #    print(k + '->' +  str(v) )

    for k,v in mfileswithltfatarghelper.items():
        filelines = []
        with open(k,'r') as f:
            filelines = f.readlines()

        for lineNo in reversed(v):
            print('Processing ' + k + ' with line ' + str(lineNo))
            origline = filelines[lineNo]
            if not 'ltfatarghelper' in origline:
                print('This is wrong in '+k + str(v)+ '\n ' + origline)
                continue

            fcall = filelines[lineNo].split("=")
            toinsert = []
            if len(fcall)<2:
                # No ret args
                toinsert.append("origpath = pwd;\n")
                toinsert.append("cd(ltfatbasepath);\n")
                toinsert.append(origline.rstrip()+'%MARKER\n')
                toinsert.append("cd([ltfatbasepath,filesep,'mex']);\n")
                toinsert.append(origline)
                toinsert.append("cd(origpath);\n")

            else:
                lhs = fcall[0]
                if '[' in lhs:
                    lhs = lhs[lhs.find('[')+1:lhs.rfind(']')]
                rhs = fcall[1][fcall[1].find("(")+1:fcall[1].rfind(")")]

                lhsList = list(x.strip() for x in lhs.split(','))
                lhsList2 = list(x+'2' if not x.strip()=='~' else x for x in lhsList)
                rhsList = rhs.split(',')
                #print(str(lhsList) + " ----> " + str(rhsList))

                newline = '['+ ','.join(lhsList2)  +']' + '=' + fcall[1] + '\n'
                
                toinsert.append("origpath = pwd;\n")
                toinsert.append("cd(ltfatbasepath);\n")
                toinsert.append("tic;\n")
                toinsert.append(origline.rstrip()+'%MARKER\n')
                toinsert.append("t0 =toc;\n")
                toinsert.append("fprintf('MAT: %d using  %s\\n',t0,which('ltfatarghelper'));\n")
                toinsert.append("cd([ltfatbasepath,filesep,'mex']);\n")
                toinsert.append("tic;\n")
                toinsert.append(newline)
                toinsert.append("t0 =toc;\n")
                toinsert.append("fprintf('MEX: %d using  %s\\n',t0,which('ltfatarghelper'));\n")
                toinsert.append("cd(origpath);\n")
                compareline = 'if ~('
                arglist = []
                for one,two in zip(lhsList,lhsList2):
                    if one == '~': continue
                    arglist.append('isequal('+one +','+two+')')
                compareline += '&&'.join(arglist)
                compareline += ')\n'
                toinsert.append(compareline);
                toinsert.append("error('ltfatarghelper test failed in "
                        "%s',upper(mfilename));\n");
                toinsert.append('end\n');
                
                #print('\n'.join(filelines))

            del filelines[lineNo]
            filelines[lineNo:lineNo] =  toinsert

        with open(k,'w') as f:
            f.writelines(filelines)



if __name__ == '__main__':
    if not query_yes_no('This will overwrite a bunch of files. Make sure you have a backup.'
            ' Should I continue?'):
        print('Quitting...')
        sys.exit()
    main()
