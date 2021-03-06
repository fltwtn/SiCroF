module ArrayClass
    use, intrinsic :: iso_fortran_env
    use MathClass
    use RandomClass
    implicit none


    interface MergeArray
        module procedure MergeArrayInt, MergeArrayReal
    end interface MergeArray


    interface CopyArray
        module procedure CopyArrayInt, CopyArrayReal,CopyArrayIntVec, CopyArrayRealVec
    end interface CopyArray


    interface TrimArray
        module procedure TrimArrayInt, TrimArrayReal
    end interface TrimArray


    interface ImportArray
        module procedure ImportArrayInt, ImportArrayReal
    end interface ImportArray

    interface ExportArray
        module procedure ExportArrayInt, ExportArrayReal
    end interface ExportArray


    interface ExportArraySize
        module procedure ExportArraySizeInt, ExportArraySizeReal
    end interface ExportArraySize

    interface InOrOut
            module procedure InOrOutReal,InOrOutInt
    end interface


    interface ShowArray
        module procedure ShowArrayInt, ShowArrayReal
    end interface ShowArray


    interface ShowArraySize
        module procedure    ShowArraySizeInt, ShowArraySizeReal
        module procedure    ShowArraySizeIntvec, ShowArraySizeRealvec
        module procedure    ShowArraySizeIntThree, ShowArraySizeRealThree
    end interface ShowArraySize


    interface ExtendArray
        module procedure  :: ExtendArrayReal,ExtendArrayInt
    end interface ExtendArray

    interface insertArray
        module procedure :: insertArrayInt, insertArrayReal
    end interface insertArray

    interface removeArray
        module procedure :: removeArrayReal,removeArrayInt 
    end interface removeArray

    interface mean
        module procedure :: meanVecReal,meanVecInt
    end interface mean

    interface distance
        module procedure ::distanceReal,distanceInt
    end interface


    interface countifSame
        module procedure ::countifSameIntArray,countifSameIntVec,countifSameIntArrayVec,countifSameIntVecArray
    end interface

    interface countif
        module procedure ::countifint,countifintvec
    end interface

    interface quicksort
        module procedure :: quicksortreal,quicksortint
    end interface
    
contains

! ############## Elementary Entities ############## 


!=====================================
subroutine MergeArrayInt(a,b,c)
    integer(int32),intent(in)::a(:,:)
    integer(int32),intent(in)::b(:,:)
    integer(int32),allocatable,intent(out)::c(:,:)
    integer(int32) i,j,an,am,bn,bm

    if(allocated(c)) deallocate(c)
    an=size(a,1)
    am=size(a,2)

    bn=size(b,1)
    bm=size(b,2)

    if(am/=bm)then
        print *, "ERROR :: MergeArray, size(a,2)/= size(b,2)"
        return
    endif
    allocate(c(an+bn,am) )
    do i=1,an
        c(i,:)=a(i,:)
    enddo
    do i=1,bn
        c(i+an,:)=b(i,:)
    enddo

end subroutine
!=====================================


!=====================================
subroutine MergeArrayReal(a,b,c)
    real(real64),intent(in)::a(:,:)
    real(real64),intent(in)::b(:,:)
    real(real64),allocatable,intent(out)::c(:,:)
    integer(int32) i,j,an,am,bn,bm
    if(allocated(c)) deallocate(c)
    an=size(a,1)
    am=size(a,2)

    bn=size(b,1)
    bm=size(b,2)

    if(am/=bm)then
        print *, "ERROR :: MergeArray, size(a,2)/= size(b,2)"
        return
    endif
    allocate(c(an+bn,am) )
    do i=1,an
        c(i,:)=a(i,:)
    enddo
    do i=1,bn
        c(i+an,:)=b(i,:)
    enddo

end subroutine
!=====================================




!=====================================
subroutine CopyArrayInt(a,ac)
    integer(int32),allocatable,intent(inout)::a(:,:)
    integer(int32),allocatable,intent(inout)::ac(:,:)
    integer(int32) i,j,n,m

    if(.not.allocated(a) )then
        print *, "CopyArray :: original array is not allocated"
        return
    endif
    n=size(a,1)
    m=size(a,2)
    if(allocated(ac) ) deallocate(ac)

    allocate(ac(n,m) )
    ac(:,:)=a(:,:)
    
end subroutine
!=====================================


!=====================================
subroutine CopyArrayReal(a,ac)
    real(real64),allocatable,intent(inout)::a(:,:)
    real(real64),allocatable,intent(inout)::ac(:,:)
    integer(int32) i,j,n,m

    if(.not.allocated(a) )then
        print *, "CopyArray :: original array is not allocated"
        return
    endif
    n=size(a,1)
    m=size(a,2)

    if(allocated(ac) ) deallocate(ac)
    allocate(ac(n,m) )
    ac(:,:)=a(:,:)
    
end subroutine
!=====================================





!=====================================
subroutine CopyArrayIntVec(a,ac)
    integer(int32),allocatable,intent(inout)::a(:)
    integer(int32),allocatable,intent(inout)::ac(:)
    integer(int32) i,j,n,m

    if(.not.allocated(a) )then 
        print *, "CopyArray :: original array is not allocated"
        return
    endif
    n=size(a,1)
    if(allocated(ac) ) deallocate(ac)

    allocate(ac(n) )
    ac(:)=a(:)
    
end subroutine
!=====================================


!=====================================
subroutine CopyArrayRealVec(a,ac)
    real(real64),allocatable,intent(inout)::a(:)
    real(real64),allocatable,intent(inout)::ac(:)
    integer(int32) i,j,n,m

    if(.not.allocated(a) )then
        
        print *, "CopyArray :: original array is not allocated"
        return
    endif
    n=size(a,1)
    if(allocated(ac) ) deallocate(ac)

    allocate(ac(n) )
    ac(:)=a(:)
        
end subroutine
!=====================================




!=====================================
subroutine TrimArrayInt(a,k)
    integer(int32),allocatable,intent(inout)::a(:,:)
    integer(int32),intent(in)::k
    integer(int32),allocatable::ac(:,:)
    integer(int32) :: i,j,n,m

    n=size(a,1)
    m=size(a,2)
    allocate(ac(k,m ))

    do i=1,k
        ac(i,:) = a(i,:)
    enddo
    deallocate(a)
    allocate(a(k,m) )
    a(:,:)=ac(:,:)
    return

end subroutine
!=====================================


!=====================================
subroutine TrimArrayReal(a,k)
    real(real64),allocatable,intent(inout)::a(:,:)
    integer(int32),intent(in)::k
    real(real64),allocatable::ac(:,:)
    integer(int32) :: i,j,n,m

    n=size(a,1)
    m=size(a,2)
    allocate(ac(k,m ))


    do i=1,k
        ac(i,:) = a(i,:)
    enddo

    deallocate(a)
    allocate(a(k,m) )
    a(:,:)=ac(:,:)
    return

end subroutine
!=====================================


!##################################################
subroutine ImportArrayInt(Mat,OptionalFileHandle,OptionalSizeX,OptionalSizeY,FileName)
    integer(int32),allocatable,intent(inout)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle,OptionalSizeX,OptionalSizeY
    character(*) ,optional,intent(in) :: FileName
    integer(int32) i,j,n,m,fh

    if(present(FileName) )then
        if(allocated(Mat))then
            deallocate(Mat)
        endif
        fh=input(default=10,option=OptionalFileHandle)
        open(fh,file=FileName)
        read(fh,*) i,j
        allocate(Mat(i,j) )
        do i=1,size(Mat,1)
            read(fh,*) Mat(i,:)
        enddo
        return
    endif

    if(present(OptionalSizeX) )then
        n=OptionalSizeX
    elseif(allocated(Mat) )then
        n=size(Mat,1)
    else
        n=1
        print *, "Caution :: ArrayClass/ImportArray >> No size_X is set"
    endif


    if(present(OptionalSizeY) )then
        m=OptionalSizeY
    elseif(allocated(Mat) )then
        m=size(Mat,2)
    else
        m=1
        print *, "Caution :: ArrayClass/ImportArray >> No size_Y is set"
    endif


    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    if(.not.allocated(Mat))then
        allocate(Mat(n,m) )
    endif

    if(size(Mat,1)/=n .or. size(Mat,2)/=m  )then
        deallocate(Mat)
        allocate(Mat(n,m) )
    endif

    do i=1,size(Mat,1)
        read(fh,*) Mat(i,:)
    enddo

    !include "./ImportArray.f90"

end subroutine ImportArrayInt
!##################################################


!##################################################
subroutine ImportArrayReal(Mat,OptionalFileHandle,OptionalSizeX,OptionalSizeY,FileName)
    real(real64),allocatable,intent(inout)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle,OptionalSizeX,OptionalSizeY
    
    !include "./ImportArray.f90"
    character(*) ,optional,intent(in) :: FileName
    integer(int32) i,j,n,m,fh

    if(present(FileName) )then
        if(allocated(Mat))then
            deallocate(Mat)
        endif
        fh=input(default=10,option=OptionalFileHandle)
        open(fh,file=FileName)
        read(fh,*) i,j
        allocate(Mat(i,j) )
        do i=1,size(Mat,1)
            read(fh,*) Mat(i,:)
        enddo
        return
    endif
    if(present(OptionalSizeX) )then
        n=OptionalSizeX
    elseif(allocated(Mat) )then
        n=size(Mat,1)
    else
        n=1
        print *, "Caution :: ArrayClass/ImportArray >> No size_X is set"
    endif


    if(present(OptionalSizeY) )then
        m=OptionalSizeY
    elseif(allocated(Mat) )then
        m=size(Mat,2)
    else
        m=1
        print *, "Caution :: ArrayClass/ImportArray >> No size_Y is set"
    endif


    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    if(.not.allocated(Mat))then
        allocate(Mat(n,m) )
    endif

    if(size(Mat,1)/=n .or. size(Mat,2)/=m  )then
        deallocate(Mat)
        allocate(Mat(n,m) )
    endif

    do i=1,size(Mat,1)
        read(fh,*) Mat(i,:)
    enddo


end subroutine ImportArrayReal
!##################################################



!##################################################
subroutine ExportArraySizeInt(Mat,RankNum,OptionalFileHandle)
    integer(int32),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    integer(int32),intent(in)::RankNum
    
    !#include "./ExportArraySize.f90"
    integer(int32) :: fh
    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    endif

    write(fh,*) size(Mat,RankNum)

end subroutine ExportArraySizeInt
!##################################################

!##################################################
subroutine ExportArraySizeReal(Mat,RankNum,OptionalFileHandle)
    real(real64),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    integer(int32),intent(in)::RankNum
    
    !#include "./ExportArraySize.f90"
    integer(int32) :: fh
    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    endif

    write(fh,*) size(Mat,RankNum)

end subroutine ExportArraySizeReal
!##################################################

!##################################################
subroutine ExportArrayInt(Mat,OptionalFileHandle)
    integer(int32),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i

    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    do i=1,size(Mat,1)
        write(fh,*) Mat(i,:)
    enddo


end subroutine ExportArrayInt
!##################################################


!##################################################
subroutine ExportArrayReal(Mat,OptionalFileHandle)
    real(real64),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i

    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif
    
    do i=1,size(Mat,1)
        write(fh,*) Mat(i,:)
    enddo


end subroutine ExportArrayReal
!##################################################



!##################################################
subroutine ShowArrayInt(Mat,IndexArray,FileHandle,Name)
    integer(int32),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in) :: IndexArray(:,:)
    integer(int32),optional,intent(in)::FileHandle 
    character(*),optional,intent(in)::Name
    
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i,j,k,l

    if(present(FileHandle) )then
        fh=FileHandle
    else
        fh=10
    endif

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(present(IndexArray))then
        
        do i=1,size(IndexArray,1)
            do j=1,size(IndexArray,2)
                k = IndexArray(i,j)
                if(k <= 0)then
                    cycle
                endif
                
                
                if(present(FileHandle) .or. present(Name) )then
                    do l=1,size(Mat,2)-1
                        write(fh,'(i0)',advance='no') Mat(k,l)
                        write(fh,'(A)',advance='no') "     "
                    enddo
                    write(fh,'(i0)',advance='yes') Mat(k,size(Mat,2) )
                else
                    print *, Mat(k,:)
                endif
            enddo
        enddo
    else

        do j=1,size(Mat,1)
            
            if(present(FileHandle) .or. present(Name) )then
                !write(fh,*) Mat(j,:)
                do k=1,size(Mat,2)-1
                    write(fh,'(i0)',advance='no') Mat(j,k)
                    write(fh,'(A)',advance='no') "     "
                enddo
                write(fh,'(i0)',advance='yes') Mat(j,size(Mat,2) )
            else
                print *, Mat(j,:)
            endif

        enddo
        
    endif
    
    if(present(FileHandle) .or. present(Name) )then
        flush(fh)
    endif


    if(present(Name) )then
        close(fh)
    endif


end subroutine 
!##################################################


!##################################################
subroutine ShowArrayReal(Mat,IndexArray,FileHandle,Name)
    real(real64),intent(in)::Mat(:,:)
    integer(int32),optional,intent(in) :: IndexArray(:,:)
    integer(int32),optional,intent(in)::FileHandle
    character(*),optional,intent(in)::Name
    
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i,j,k,l

    if(present(FileHandle) )then
        fh=FileHandle
    else
        fh=10
    endif
    

    if(present(Name) )then
        open(fh,file=Name)
    endif

    if(present(IndexArray))then
        
        do i=1,size(IndexArray,1)
            do j=1,size(IndexArray,2)
                k = IndexArray(i,j)
                if(k <= 0)then
                    cycle
                endif
                
                
                if(present(FileHandle) .or. present(Name) )then
                    !write(fh,*) Mat(k,:)
                    do l=1,size(Mat,2)-1
                        write(fh, '(e22.14e3)',advance='no' ) Mat( k,l )
                        write(fh,'(A)',advance='no') "     "
                    enddo
                    write(fh,'(e22.14e3)',advance='yes') Mat( k,size(Mat,2) )
                else
                    print *, Mat(k,:)
                endif
            enddo
        enddo
    else

        do j=1,size(Mat,1)
            
            if(present(FileHandle) .or. present(Name) )then
                !write(fh,*) Mat(j,:)
                do l=1,size(Mat,2)-1
                    write(fh,'(e22.14e3)',advance='no') Mat( j,l )
                    write(fh,'(A)',advance='no') "     "
                enddo
                write(fh,'(e22.14e3)',advance='yes') Mat( j,size(Mat,2) )
            else
                print *, Mat(j,:)
            endif

        enddo
        
    endif
    
    if(present(FileHandle) .or. present(Name) )then
        flush(fh)
    endif



    if(present(Name) )then
        close(fh)
    endif

end subroutine 
!##################################################




!##################################################
subroutine ShowArraySizeInt(Mat,OptionalFileHandle,Name)
    integer(int32),allocatable,intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i


    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif


    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle) )then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1), size(Mat,2) 
    if(present(OptionalFileHandle) .or. present(Name) )then
        write(fh,*) size(Mat,1), size(Mat,2)
    endif
    


    if(present(Name) )then
        close(fh)
    endif


end subroutine 
!##################################################


!##################################################
subroutine ShowArraySizeReal(Mat,OptionalFileHandle,Name)
    real(real64),allocatable,intent(in)::Mat(:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i

    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif
    

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle) )then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1), size(Mat,2) 
    if(present(OptionalFileHandle).or. present(Name) )then
        write(fh,*) size(Mat,1), size(Mat,2)
    endif
    

    if(present(Name) )then
        close(fh)
    endif

end subroutine 
!##################################################



!##################################################
subroutine ShowArraySizeIntvec(Mat,OptionalFileHandle,Name)
    integer(int32),allocatable,intent(in)::Mat(:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i


    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif
    

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle).or. present(Name) )then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1) 
    if(present(OptionalFileHandle).or. present(Name) )then
        write(fh,*) size(Mat,1)
    endif
    

    if(present(Name) )then
        close(fh)
    endif


end subroutine 
!##################################################


!##################################################
subroutine ShowArraySizeRealvec(Mat,OptionalFileHandle,Name)
    real(real64),allocatable,intent(in)::Mat(:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i

    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle).or. present(Name) )then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1)
    if(present(OptionalFileHandle) .or. present(Name))then
        write(fh,*) size(Mat,1)
    endif
    

    if(present(Name) )then
        close(fh)
    endif

end subroutine 
!##################################################



!##################################################
subroutine ShowArraySizeIntThree(Mat,OptionalFileHandle,Name)
    integer(int32),allocatable,intent(in)::Mat(:,:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i



    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle) .or. present(Name))then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1), size(Mat,2) , size(Mat,3) 
    if(present(OptionalFileHandle) .or. present(Name))then
        write(fh,*) size(Mat,1), size(Mat,2), size(Mat,3) 
    endif



    if(present(Name) )then
        close(fh)
    endif
end subroutine 
!##################################################


!##################################################
subroutine ShowArraySizeRealThree(Mat,OptionalFileHandle,Name)
    real(real64),allocatable,intent(in)::Mat(:,:,:,:)
    integer(int32),optional,intent(in)::OptionalFileHandle
    character(*),optional,intent(in)::Name
    
    !#include "./ExportArray.f90"
    integer(int32) :: fh,i

    if(present(OptionalFileHandle) )then
        fh=OptionalFileHandle
    else
        fh=10
    endif

    if(present(Name) )then
        open(fh,file=Name)
    endif
    
    if(.not. allocated(Mat) )then
        print *, "Not allocated!"
        if(present(OptionalFileHandle) .or. present(Name))then
            write(fh,*) "Not allocated!"
        endif
    endif
    print *, size(Mat,1), size(Mat,2) , size(Mat,3) 
    if(present(OptionalFileHandle).or. present(Name) )then
        write(fh,*) size(Mat,1), size(Mat,2), size(Mat,3) 
    endif
    


    if(present(Name) )then
        close(fh)
    endif

end subroutine 
!##################################################



!##################################################
function InOrOutReal(x,xmax,xmin,DimNum) result(Inside)
    real(real64),intent(in)::x(:)
    real(real64),intent(in)::xmax(:),xmin(:)
    integer(int32),optional,intent(in)::DimNum
    integer(int32) :: dim_num
    logical ::Inside
    integer(int32) :: i,j,n,cout

    cout=0
    if(present(DimNum) )then
        dim_num=DimNum
    else
        dim_num=size(x)
    endif

    do i=1,dim_num
        if(xmin(i) <= x(i) .and. x(i)<=xmax(i) )then
            cout=cout+1
        else
            cycle
        endif
    enddo

    if(cout==dim_num)then
        Inside = .true.
    else
        Inside = .false.
    endif

end function

!##################################################




!##################################################
function InOrOutInt(x,xmax,xmin,DimNum) result(Inside)
    integer(int32),intent(in)::x(:)
    integer(int32),intent(in)::xmax(:),xmin(:)
    integer(int32),optional,intent(in)::DimNum
    integer(int32) :: dim_num
    logical ::Inside
    integer(int32) :: i,j,n,cout

    cout=0
    if(present(DimNum) )then
        dim_num=DimNum
    else
        dim_num=size(x)
    endif

    do i=1,dim_num
        if(xmin(i) <= x(i) .and. x(i)<=xmax(i) )then
            cout=cout+1
        else
            cycle
        endif
    enddo

    if(cout==dim_num)then
        Inside = .true.
    else
        Inside = .false.
    endif

end function

!##################################################




!##################################################
subroutine ExtendArrayReal(mat,extend1stColumn,extend2ndColumn,DefaultValue)
    real(real64),allocatable,intent(inout)::mat(:,:)
    real(real64),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: extend1stColumn,extend2ndColumn
    real(real64),optional,intent(in) :: DefaultValue
    real(real64) :: val
    integer(int32) :: n,m

    if( present(DefaultValue) )then
        val = DefaultValue
    else
        val = 0.0d0
    endif

    n=size(mat,1)
    m=size(mat,2)
    if(present(extend1stColumn) )then
        if(extend1stColumn .eqv. .true.)then
            allocate(buffer(n+1, m ) )
            buffer(:,:)=val
            buffer(1:n,1:m)=mat(1:n,1:m)
            deallocate(mat)
            call copyArray(buffer,mat)
            deallocate(buffer)
        endif
    endif

    n=size(mat,1)
    m=size(mat,2)
    if(present(extend2ndColumn) )then
        if(extend2ndColumn .eqv. .true.)then
            allocate(buffer(n, m+1 ) )
            buffer(:,:)=val
            buffer(1:n,1:m)=mat(1:n,1:m)
            deallocate(mat)
            call copyArray(buffer,mat)
            deallocate(buffer)
        endif
    endif


end subroutine
!##################################################



!##################################################
subroutine ExtendArrayInt(mat,extend1stColumn,extend2ndColumn,DefaultValue)
    integer(int32),allocatable,intent(inout)::mat(:,:)
    integer(int32),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: extend1stColumn,extend2ndColumn
    integer(int32),optional,intent(in) :: DefaultValue
    integer(int32) :: val
    integer(int32) :: i,j,k,n,m

    if( present(DefaultValue) )then
        val = DefaultValue
    else
        val = 0
    endif

    n=size(mat,1)
    m=size(mat,2)
    if(present(extend1stColumn) )then
        if(extend1stColumn .eqv. .true.)then
            allocate(buffer(n+1, m ) )
            buffer(:,:)=val
            buffer(1:n,1:m)=mat(1:n,1:m)
            deallocate(mat)
            call copyArray(buffer,mat)
            deallocate(buffer)
        endif
    endif

    n=size(mat,1)
    m=size(mat,2)
    if(present(extend2ndColumn) )then
        if(extend2ndColumn .eqv. .true.)then
            allocate(buffer(n, m+1 ) )
            buffer(:,:)=val
            buffer(1:n,1:m)=mat(1:n,1:m)
            deallocate(mat)
            call copyArray(buffer,mat)
            deallocate(buffer)
        endif
    endif


end subroutine
!##################################################


!##################################################
subroutine insertArrayInt(mat,insert1stColumn,insert2ndColumn,DefaultValue,NextOf)
    integer(int32),allocatable,intent(inout)::mat(:,:)
    integer(int32),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: insert1stColumn,insert2ndColumn
    integer(int32),optional,intent(in) :: DefaultValue,NextOf
    integer(int32) :: val
    integer(int32) :: i,nof
    
    call extendArray(mat,insert1stColumn,insert2ndColumn,DefaultValue)

    if(present(DefaultValue))then
        val =DefaultValue
    else
        val =0
    endif

    if(present(NextOf))then
        nof=NextOf
    else 
        if( present(insert1stColumn ))then
            if( insert1stColumn .eqv. .true. )then
                nof=size(mat,1)-1
            endif
        endif
        
        if( present(insert2ndColumn ))then
            if( insert2ndColumn .eqv. .true. )then
                nof=size(mat,2)-1
            endif
        endif

    endif
    
    if( present(insert1stColumn ))then
        if( insert1stColumn .eqv. .true. )then
            do i=size(mat,1)-1,nof,-1
                mat(i+1,:)=mat(i,:)
            enddo
            mat(nof+1,:)=val
        endif
    endif
    if( present(insert2ndColumn ))then
        if( insert2ndColumn .eqv. .true. )then
            do i=size(mat,1)-1,nof,-1
                mat(:,i+1)=mat(:,i)
            enddo
            mat(:,nof+1)=val
        endif
    endif
end subroutine
!##################################################



!##################################################
subroutine insertArrayReal(mat,insert1stColumn,insert2ndColumn,DefaultValue,NextOf)
    real(real64),allocatable,intent(inout)::mat(:,:)
    real(real64),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: insert1stColumn,insert2ndColumn
    
    integer(int32),optional,intent(in) :: NextOf
    real(real64),optional,intent(in) :: DefaultValue
    real(real64) :: val
    integer(int32) :: i,nof
    
    call extendArray(mat,insert1stColumn,insert2ndColumn,DefaultValue)

    if(present(DefaultValue))then
        val =DefaultValue
    else
        val =0
    endif

    if(present(NextOf))then
        nof=NextOf
    else 
        if( present(insert1stColumn ))then
            if( insert1stColumn .eqv. .true. )then
                nof=size(mat,1)-1
            endif
        endif
        
        if( present(insert2ndColumn ))then
            if( insert2ndColumn .eqv. .true. )then
                nof=size(mat,2)-1
            endif
        endif

    endif
    
    if( present(insert1stColumn ))then
        if( insert1stColumn .eqv. .true. )then
            do i=size(mat,1)-1,nof,-1
                mat(i+1,:)=mat(i,:)
            enddo
            mat(nof+1,:)=val
        endif
    endif
    if( present(insert2ndColumn ))then
        if( insert2ndColumn .eqv. .true. )then
            do i=size(mat,1)-1,nof,-1
                mat(:,i+1)=mat(:,i)
            enddo
            mat(:,nof+1)=val
        endif
    endif
end subroutine
!##################################################





!##################################################
subroutine removeArrayInt(mat,remove1stColumn,remove2ndColumn,NextOf)
    integer(int32),allocatable,intent(inout)::mat(:,:)
    integer(int32),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: remove1stColumn,remove2ndColumn
    
    integer(int32),optional,intent(in) :: NextOf
    
    integer(int32) :: i,nof
    
    if( present(remove1stColumn ))then
        if( remove1stColumn .eqv. .true. )then
            nof=size(mat,1)
        endif
    endif
    
    if( present(remove2ndColumn ))then
        if( remove2ndColumn .eqv. .true. )then
            nof=size(mat,2)
        endif
    endif

    if(present(NextOf) )then
        if(NextOf >= nof)then
            return
        endif
    endif
    call copyArray(mat,buffer)


    if(present(NextOf))then
        nof=NextOf
    else 
        if( present(remove1stColumn ))then
            if( remove1stColumn .eqv. .true. )then
                nof=size(mat,1)-1
            endif
        endif
        
        if( present(remove2ndColumn ))then
            if( remove2ndColumn .eqv. .true. )then
                nof=size(mat,2)-1
            endif
        endif
    endif


    deallocate(mat)
    
    if( present(remove1stColumn ))then
        if( remove1stColumn .eqv. .true. )then
            if(size(buffer,1)-1 == 0)then
                print *, "Array is deleted"
                return
            endif
            allocate(mat(size(buffer,1)-1,size(buffer,2)) )
            mat(:,:)=0.0d0
            do i=1,nof
                mat(i,:)=buffer(i,:)
            enddo
            
            do i=nof+1,size(buffer,1)-1
                mat(i,:)=buffer(i+1,:)
            enddo

        endif
    endif
    if( present(remove2ndColumn ))then
        if( remove2ndColumn .eqv. .true. )then
            
            if(size(buffer,2)-1 == 0)then
                print *, "Array is deleted"
                return
            endif
            allocate(mat(size(buffer,1),size(buffer,2)-1) )
            mat(:,:)=0.0d0
            do i=1,nof
                mat(:,i)=buffer(:,i)
            enddo

            do i=nof+1,size(buffer,2)-1
                mat(:,i)=buffer(:,i+1)
            enddo
        endif
    endif

end subroutine
!##################################################



!##################################################
subroutine removeArrayReal(mat,remove1stColumn,remove2ndColumn,NextOf)
    real(real64),allocatable,intent(inout)::mat(:,:)
    real(real64),allocatable :: buffer(:,:)
    logical,optional,intent(in) :: remove1stColumn,remove2ndColumn
    
    integer(int32),optional,intent(in) :: NextOf
    
    integer(int32) :: i,nof,rmsin,m,n
    
    if( present(remove1stColumn ))then
        if( remove1stColumn .eqv. .true. )then
            nof=size(mat,1)
        endif
    endif
    
    if( present(remove2ndColumn ))then
        if( remove2ndColumn .eqv. .true. )then
            nof=size(mat,2)
        endif
    endif

    if(present(NextOf) )then
        if(NextOf >= nof)then
            return
        endif
    endif

    call copyArray(mat,buffer)



    if(present(NextOf))then
        nof=NextOf
    else 
        if( present(remove1stColumn ))then
            if( remove1stColumn .eqv. .true. )then
                nof=size(mat,1)-1
            endif
        endif
        
        if( present(remove2ndColumn ))then
            if( remove2ndColumn .eqv. .true. )then
                nof=size(mat,2)-1
            endif
        endif
    endif


    deallocate(mat)
    
    if( present(remove1stColumn ))then
        if( remove1stColumn .eqv. .true. )then
            if(size(buffer,1)-1 == 0)then
                print *, "Array is deleted"
                return
            endif
            allocate(mat(size(buffer,1)-1,size(buffer,2)) )
            mat(:,:)=0.0d0
            do i=1,nof
                mat(i,:)=buffer(i,:)
            enddo
            
            do i=nof+1,size(buffer,1)-1
                mat(i,:)=buffer(i+1,:)
            enddo

        endif
    endif
    if( present(remove2ndColumn ))then
        if( remove2ndColumn .eqv. .true. )then
            
            if(size(buffer,2)-1 == 0)then
                print *, "Array is deleted"
                return
            endif
            allocate(mat(size(buffer,1),size(buffer,2)-1) )
            mat(:,:)=0.0d0
            do i=1,nof
                mat(:,i)=buffer(:,i)
            enddo

            do i=nof+1,size(buffer,2)-1
                mat(:,i)=buffer(:,i+1)
            enddo
        endif
    endif

end subroutine
!##################################################


!##################################################
function meanVecReal(vec) result(mean_val)
    real(real64),intent(in)::vec(:)
    real(real64)::mean_val

    integer(int32) :: i
    mean_val=0.0d0
    do i=1,size(vec)
        mean_val=mean_val+vec(i)
    enddo
    mean_val=mean_val/dble(size(vec))
    
end function
!##################################################

!##################################################
function meanVecint(vec) result(mean_val)
    integer(int32),intent(in)::vec(:)
    integer(int32)::mean_val
    integer(int32) :: i
    mean_val=0
    do i=1,size(vec)
        mean_val=mean_val+vec(i)
    enddo
    mean_val=mean_val/size(vec)
    
end function
!##################################################


!##################################################
function distanceReal(x,y) result(dist)
    real(real64),intent(in)::x(:),y(:)
    real(real64)::dist

    integer(int32) :: i

    if(size(x)/=size(y) )then
        print *, "ERROR ArrayClass ::  distanceReal(x,y) size(x)/=size(y) "
        return
    endif
    dist=0.0d0
    do i=1,size(x)
        dist=dist+(x(i)-y(i) )*(x(i)-y(i) )
    enddo
    dist=sqrt(dist)
    return
end function
!##################################################


!##################################################
function distanceInt(x,y) result(dist)
    integer(int32),intent(in)::x(:),y(:)
    integer(int32)::dist

    integer(int32) :: i

    if(size(x)/=size(y) )then
        print *, "ERROR ArrayClass ::  distanceReal(x,y) size(x)/=size(y) "
        return
    endif
    dist=0
    do i=1,size(x)
        dist=dist+(x(i)-y(i) )*(x(i)-y(i) )
    enddo
    dist=int(sqrt(dble(dist)))
    return
end function
!##################################################


!##################################################
function countifSameIntArray(Array1,Array2) result(count_num)
    integer(int32),intent(in)::Array1(:,:),Array2(:,:)
    integer(int32) :: i,j,k,l,n,count_num,exist

    count_num=0
    do i=1,size(Array1,1)
        do j=1,size(Array1,2)
            exist=0
            do k=1,size(Array2,1)
                do l=1,size(Array2,2)
                    if(Array1(i,j)==Array2(k,l) )then
                        exist=1
                        exit
                    endif     
                enddo
                if(exist==1)then
                    exit
                endif
            enddo

            if(exist==1)then
                count_num=count_num+1
            endif
        enddo
    enddo

end function
!##################################################


!##################################################
function countifSameIntVec(Array1,Array2) result(count_num)
    integer(int32),intent(in)::Array1(:),Array2(:)
    integer(int32) :: i,j,k,l,n,count_num,exist

    count_num=0
    do i=1,size(Array1)
        exist=0
        do j=1,size(Array2,1)
            if(Array1(i)==Array2(j) )then
                exist=1
            endif    
        enddo
        if(exist==1)then
            count_num=count_num+1
        endif
    enddo

end function
!##################################################


!##################################################
function countifSameIntArrayVec(Array1,Array2) result(count_num)
    integer(int32),intent(in)::Array1(:,:),Array2(:)
    integer(int32) :: i,j,k,l,n,count_num,exist

    count_num=0
    do i=1,size(Array1,1)
        do j=1,size(Array1,2)
            exist=0
            do k=1,size(Array2,1)
                if(Array1(i,j)==Array2(k) )then
                    exist=1
                    exit
                endif  
                
                if(exist==1)then
                    exit
                endif  
            enddo
            if(exist==1)then
                count_num=count_num+1
            endif
        enddo
    enddo

end function
!##################################################



!##################################################
function countifSameIntVecArray(Array1,Array2) result(count_num)
    integer(int32),intent(in)::Array2(:,:),Array1(:)
    integer(int32) :: i,j,k,l,n,count_num,exist

    count_num=0
    do i=1,size(Array1,1)
        exist=0
        do j=1,size(Array2,1)
            do k=1,size(Array2,2)
                if(Array1(i)==Array2(j,k) )then
                    exist=1
                    exit
                endif    
            enddo
        enddo
        if(exist==1)then
            count_num=count_num+1
        endif
    enddo

end function
!##################################################

!##################################################
function countifint(Array,Equal,notEqual,Value) result(count_num)
    integer(int32),intent(in)::Array(:,:),Value
    integer(int32) :: i,j,n,case,count_num
    logical,optional,intent(in)::Equal,notEqual
    

    if(present(Equal) )then
        if(Equal .eqv. .true.)then
            case=1
        else
            case=0
        endif
    
    elseif(present(notEqual) )then
        if(notEqual .eqv. .true.)then
            case=0
        else
            case=1
        endif
    else
        print *, "caution :: ArrayClass :: countifint :: please check Equal or notEqual"
        print *, "performed as Equal"
        case=0
    endif

    count_num=0
    if(case==0)then
        do i=1,size(Array,1)
            do j=1,size(Array,2)
                ! not Equal => count
                if(Array(i,j) /= Value )then
                    count_num=count_num+1
                else
                    cycle
                endif
            enddo
        enddo
    elseif(case==1)then

        do i=1,size(Array,1)
            do j=1,size(Array,2)
                ! Equal => count
                if(Array(i,j) == Value )then
                    count_num=count_num+1
                else
                    cycle
                endif
            enddo
        enddo
    else
        print *, "ERROR :: ArrayClass :: countifint :: please check Equal or notEqual"
    endif
end function
!##################################################

!##################################################
function countifintVec(Array,Equal,notEqual,Value) result(count_num)
    integer(int32),intent(in)::Array(:),Value
    integer(int32) :: i,j,n,case,count_num
    logical,optional,intent(in)::Equal,notEqual
    

    if(present(Equal) )then
        if(Equal .eqv. .true.)then
            case=1
        else
            case=0
        endif
    
    elseif(present(notEqual) )then
        if(notEqual .eqv. .true.)then
            case=0
        else
            case=1
        endif
    else
        print *, "caution :: ArrayClass :: countifint :: please check Equal or notEqual"
        print *, "performed as Equal"
        case=0
    endif

    count_num=0
    if(case==0)then
        do i=1,size(Array,1)
            ! not Equal => count
            if(Array(i) /= Value )then
                count_num=count_num+1
            else
                cycle
            endif
        
        enddo
    elseif(case==1)then

        do i=1,size(Array,1)
            ! Equal => count
            if(Array(i) == Value )then
                count_num=count_num+1
            else
                cycle
            endif
            
        enddo
    else
        print *, "ERROR :: ArrayClass :: countifint :: please check Equal or notEqual"
    endif
end function
!##################################################


!##################################################
recursive subroutine quicksortint(list) 
    integer(int32),intent(inout) :: list(:)
    integer(int32) :: border,a,b,buf
    integer(int32) :: i,j,border_id,n,start,last,scope1_out,scope2_out
    integer(int32) :: scope1,scope2
    logical :: crossed
    ! http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/quick-sort.html


    
    scope1=1
    scope2=size(list)
    
    if(size(list)==1)then
        return
    endif

    ! determine border
    n=size(list)
    a=list(1)
    b=list(2)

    
    if(a >= b)then
        border=a
        if(size(list)==2 )then
            list(1)=b
            list(2)=a
            return
        endif
    else
        border=b
        if(size(list)==2 )then
            list(1)=a
            list(2)=b
            return
        endif
    endif

    last=scope2
    crossed=.false.

    
    do start=scope1,scope2
        if(list(start)>=border)then
            do 
                if(list(last)<border )then
                    ! exchange
                    buf=list(start)
                    list(start)=list(last)
                    list(last)=buf
                    exit
                else
                    if(start >=last )then
                        crossed = .true.
                        exit
                    else
                        last=last-1
                    endif
                endif
            enddo
        else
            cycle
        endif 

        if(crossed .eqv. .true.)then
            call quicksort(list(scope1:start))
            call quicksort(list(last:scope2))
            exit
        else
            cycle
        endif

    enddo

end subroutine
!##################################################



!##################################################
recursive subroutine quicksortreal(list) 
    real(real64),intent(inout) :: list(:)
    real(real64) :: border,a,b,buf
    integer(int32) :: i,j,border_id,n,start,last,scope1_out,scope2_out
    integer(int32) :: scope1,scope2
    logical :: crossed
    ! http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/quick-sort.html


    
    scope1=1
    scope2=size(list)
    
    if(size(list)==1)then
        return
    endif

    ! determine border
    n=size(list)
    a=list(1)
    b=list(2)

    
    if(a >= b)then
        border=a
        if(size(list)==2 )then
            list(1)=b
            list(2)=a
            return
        endif
    else
        border=b
        if(size(list)==2 )then
            list(1)=a
            list(2)=b
            return
        endif
    endif

    last=scope2
    crossed=.false.

    
    do start=scope1,scope2
        if(list(start)>=border)then
            do 
                if(list(last)<border )then
                    ! exchange
                    buf=list(start)
                    list(start)=list(last)
                    list(last)=buf
                    exit
                else
                    if(start >=last )then
                        crossed = .true.
                        exit
                    else
                        last=last-1
                    endif
                endif
            enddo
        else
            cycle
        endif 

        if(crossed .eqv. .true.)then
            call quicksort(list(scope1:start))
            call quicksort(list(last:scope2))
            exit
        else
            cycle
        endif

    enddo

end subroutine
!##################################################

end module ArrayClass