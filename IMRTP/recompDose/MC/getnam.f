!!! JC
! In getnam.f, "read(*,'(80a1)') (phyname(i),i=1,80)" is still here. 
! No need for subroutine 'GETNAM', since the lenth of the input file name,
! is directly determined by "mxGetString" function.
! However, GETNA2 is still called in dpm.f

C***********************************************************************
C                                                                       
C  Section GETNAM
C
      subroutine GETNAM(iounit,physics,n)
C
C  Declarations for Globals                                             
C                                                                       
      character physics*80                                              
      integer n,iounit                                                  
C                                                                       
C  Declarations for Locals                                              
C                                                                       
      character phyname(80)                                             
      integer i                                                         
C                                                                       
      if(iounit .eq. 5) then
        read(*,'(80a1)') (phyname(i),i=1,80)                         
      else
        read(iounit,'(80a1)') (phyname(i),i=1,80)                         
      endif
C                                                                       
      do 10 i=1,80                                                      
         if(phyname(i).ne.' ') then                                     
            physics(i:i)=phyname(i)                                     
         else                                                           
            n=i-1                                                       
            return                                                      
         endif                                                          
   10 continue                                                          
C                                                                       
      end                                                               



      subroutine GETNA2(iounit,physics,n)
C
C  Declarations for Globals                                             
C                                                                       
      character physics*40                                              
      integer n,iounit                                                  
C                                                                       
C  Declarations for Locals                                              
C                                                                       
      character phyname(80)                                             
      integer*8 i, j, istart
C                                                                       
      if(iounit .eq. 5) then
        read(*,'(80a1)') (phyname(i),i=1,80)                         
      else
        read(iounit,'(80a1)') (phyname(i),i=1,80)
      endif
C                                                                       
C  look for the ':' in the line with the name
C
      do 5 i=1,80
        if(phyname(i).eq.':') then
          istart = i+2
          go to 8
        endif
    5 continue
C
    8 do 10 i=istart,80
         j=i-istart+1
         if(phyname(i).ne.' ' .and. phyname(i).ne.'') then
             physics(j:j)=phyname(i)
         else                                                           
            n=i-istart
            return                                                      
         endif                                                          
   10 continue                                                          
C                                                                       
      end                                                               
