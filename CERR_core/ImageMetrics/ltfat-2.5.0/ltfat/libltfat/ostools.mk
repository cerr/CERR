#This file produces system and environment dependent tools for working with files
#It sets the following variables
#
#  RM
#  CP

ifeq ($(OS),Windows_NT) 
$(info Windows detected)
MINGW = 1
RM = del /Q /F
CP = copy /Y
MKDIR = md
RMDIR = rmdir /S /Q
PS2 = \\
PS = $(strip $(PS2))
CC = gcc
ifndef SHELL
ifdef ComSpec
SHELL := $(ComSpec)
endif
ifdef COMSPEC
SHELL := $(COMSPEC)
endif
endif
else
#If not on Windows
RM = rm -rf
CP = cp -f
PS = /
MKDIR = mkdir -p
RMDIR = $(RM)
endif

#CC=gcc
