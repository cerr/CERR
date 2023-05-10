# Use Make to process this file. 

JC=javac

FLAGS=-source 1.6 -target 1.6
include ostools.mk

default:
	$(JC) $(FLAGS) net/sourceforge/ltfat/*.java net/sourceforge/ltfat/thirdparty/*.java
	jar cf blockproc.jar net/sourceforge/ltfat/*.class net/sourceforge/ltfat/thirdparty/*.class

clean: classclean
	$(RM)  *.jar

classclean:
	$(RM) net$(PS)sourceforge$(PS)ltfat$(PS)*.class
	$(RM) net$(PS)sourceforge$(PS)ltfat$(PS)thirdparty$(PS)*.class

