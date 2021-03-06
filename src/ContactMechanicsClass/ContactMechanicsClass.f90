module ContactMechanicsClass
    use, intrinsic :: iso_fortran_env
	use MathClass
	use MPIClass
    use FEMIfaceClass
	use FEMDomainClass
	use FiniteDeformationClass
    
    implicit none

    type :: ContactMechanics_
        type(FEMIface_),pointer::FEMIface
        type(FEMDomain_),pointer::FEMDomain1
		type(FEMDomain_),pointer::FEMDomain2

		! common fields
		real(real64),allocatable		:: NTSGap(:,:)
		real(real64),allocatable		:: NTSGzi(:,:)
		real(real64)		  			:: penaltypara

		! for weak coupling contact analysis
		real(real64),allocatable    :: Domain1Force(:,:)
		real(real64),allocatable    :: Domain2Force(:,:)


		! for strong coupling contact analysys
        real(real64),allocatable    ::KcontactEBE(:,:,:)
        real(real64),allocatable    ::KcontactGlo(:,:)
        real(real64),allocatable    ::FcontactEBE(:,:)
        real(real64),allocatable    ::FcontactGlo(:)
        real(real64),allocatable    ::DispVecEBE(:,:)
        real(real64),allocatable    ::DispVecGlo(:)
        real(real64),allocatable    ::NTSvariables(:,:)
        real(real64),allocatable    ::ContactMatPara(:,:)
        real(real64),allocatable    ::GloNodCoord(:,:)
        integer,allocatable    ::NTSMaterial(:)
		integer,allocatable    ::StickOrSlip(:)
		integer :: step
		
	contains
		procedure :: Update			=> UpdateContactConfiguration
        procedure :: Init			=> InitializeContactMechanics
		procedure :: Import         => ImportContactMechanics 
		procedure :: deploy			=> deployContactMechanics
		procedure :: ContactSearch  => ContactSearch 
        procedure :: getKcmat       => getKcmat
        procedure :: getKcmatStick  => getKcmatStick
		procedure :: getKcmatStickSlip 		=> getKcmatStickSlip 
		procedure :: setPenaltyParameter 	=> setPenaltyParaCM 
		procedure :: updateContactStress 	=> updateContactStressCM
		procedure :: updateTimestep => updateTimestepContact
		procedure :: getGap			=> getGapCM
		procedure :: getForce		=> getForceCM
		procedure :: exportForceAsTraction 	=> exportForceAsTractionCM
    end type

contains

! #####################################################
subroutine InitializeContactMechanics(obj)
    class(ContactMechanics_),intent(inout)  :: obj

    if(allocated(obj%KcontactEBE) )then
        deallocate(obj%KcontactEBE)
    endif
    if(allocated(obj%KcontactGlo) )then
        deallocate(obj%KcontactGlo)
    endif
    if(allocated(obj%FcontactEBE) )then
        deallocate(obj%FcontactEBE)
    endif
    if(allocated(obj%FcontactGlo) )then
        deallocate(obj%FcontactGlo)
    endif
    if(allocated(obj%DispVecEBE) )then
        deallocate(obj%DispVecEBE)
    endif
    if(allocated(obj%DispVecGlo) )then
        deallocate(obj%DispVecGlo)
    endif
    if(allocated(obj%NTSvariables) )then
        deallocate(obj%NTSvariables)
    endif
    
    if(.not. associated(obj%FEMDomain1) )then
        print *, "ContactMechanics%Init >> FEMDomain1 is not imported"
        return
    endif
    if(.not. associated(obj%FEMDomain2) )then
        print *, "ContactMechanics%Init >> FEMDomain2 is not imported"
        return
    endif
    if(.not. associated(obj%FEMIface) )then
        print *, "ContactMechanics%Init >> FEMIface is not imported"
        return
    endif


end subroutine
! #####################################################


! #####################################################
subroutine UpdateContactConfiguration(obj,WeakCoupling,StrongCoupling)
	class(ContactMechanics_),intent(inout)::obj
	logical,optional,intent(in) :: WeakCoupling,StrongCoupling
	type(MPI_)::mpidata



	
	if( present(WeakCoupling))then
		if(WeakCoupling .eqv. .true.)then


			! only 3-D is supported.

			call obj%FEMIface%GetFEMIface()
			call obj%deploy(obj%FEMIface)
			call obj%setPenaltyParameter( dble(1.0e-4) )
			call obj%updateContactStress()
			call obj%updateTimeStep()
			

			! debug :: Contact-Traction conversion has errors
			
			call obj%FEMDomain1%export(OptionalProjectName="1ontact_1_",FileHandle=120,SolverType="FiniteDeform_",MeshDimension=3)
			call obj%FEMDomain2%export(OptionalProjectName="2ontact_2_",FileHandle=121,SolverType="FiniteDeform_",MeshDimension=3)
			
			
			call mpidata%end()
			stop "debug update contact"
			! debug :: Contact-Traction conversion has errors

			
			return
		endif
	endif

	if( present(StrongCoupling))then
		if(StrongCoupling .eqv. .true.)then
			
			! only 2-D is supported.
			call obj%FEMIface%GetFEMIface()
			call obj%deploy(obj%FEMIface)
			call obj%setPenaltyParameter( dble(1.0e-4) )
			
			print *, "Debugging ls25"
			return
			
			call obj%updateContactStress()
			call obj%updateTimeStep()
			
			! debug :: Contact-Traction conversion has errors
			
			call obj%FEMDomain1%export(OptionalProjectName="1ontact_1_",FileHandle=120,SolverType="FiniteDeform_",MeshDimension=2)
			call obj%FEMDomain2%export(OptionalProjectName="2ontact_2_",FileHandle=121,SolverType="FiniteDeform_",MeshDimension=2)
			
			! debug :: Contact-Traction conversion has errors

			return
		endif
	endif

	
end subroutine
! #####################################################




! #####################################################
subroutine ImportContactMechanics(obj)
    class(ContactMechanics_),intent(inout)::obj
    

end subroutine
! #####################################################

! #####################################################
subroutine deployContactMechanics(obj,IfaceObj)
	class(ContactMechanics_),intent(inout)::obj
	class(FEMIface_),target,intent(in)::IfaceObj
	type(MPI_)::mpidata

	obj%FEMIface => IfaceObj

end subroutine
! #####################################################


! #####################################################
subroutine ContactSearch(obj)
    class(ContactMechanics_),intent(inout)::obj

    integer :: ierr,i,n

	
	call obj%FEMIface%GetFEMIface(obj%FEMDomain1,obj%FEMDomain2)
	
	
	call GetActiveContactElement(obj)

end subroutine
! #####################################################


! #####################################################
subroutine GetActiveContactElement(obj)
    class(ContactMechanics_),intent(inout)::obj

    ! Check Active/Incative of contact elements
    ! For Node-To-Segment
    call GetActiveNTS(obj)

end subroutine
! #####################################################



! #####################################################
subroutine GetActiveNTS(obj)
    class(ContactMechanics_),intent(inout)::obj
	type(MPI_)::mpidata
    real(real64) :: gap
    real(real64),allocatable :: xs(:),xm(:,:)
	integer i,j,n,dim_num,mnod_num
	

    
    dim_num = size(obj%FEMDomain1%Mesh%NodCoord,2)
    if(dim_num < 1 .or. dim_num >4)then
        print *, "ContactMechanics_ >> GetActiveNTS >> dim_num should be 2 or 3 "
        stop 
    endif
    mnod_num = size(obj%FEMIface%NTS_NodCoord,2)/dim_num-1
    allocate(xs(dim_num),xm(mnod_num,dim_num))



    do i=1,size(obj%FEMIface%NTS_NodCoord,1) ! NTS_NodeCoordID
        xs(1:dim_num)=obj%FEMIface%NTS_NodCoord(i,1:dim_num)
		
		do j=1,mnod_num
            if(dim_num*(j+1) > size(obj%FEMIface%NTS_NodCoord,2)  )then
                print *, "ContactMechanics_ >> GetActiveNTS >> dim_num(j+1) > size(obj%FEMIface%NTS_NodCoord,2)  "
                stop
			endif
            xm(j, 1:3)=obj%FEMIface%NTS_NodCoord(i,dim_num*j+1:dim_num*(j+1) ) ! ### Bug is here ### !
		enddo
		



		call GetNormalGap(xs,xm,gap)
		

    enddo

end subroutine
! #####################################################




! #####################################################
subroutine GetNormalGap(xs,xm,gap)
    real(real64),intent(in)::xs(:),xm(:,:)
    real(real64),intent(out)::gap

    real(real64),allocatable :: nm(:),am1(:),am2(:),mid(:),gvec(:)
    integer :: i,j,n,dim_num,ierr

    dim_num = size(xs)
    allocate(nm(3),am1(3),am2(3),mid(3),gvec(3) )

    if(dim_num == 1)then
        nm(:)=1.0d0
    elseif(dim_num == 2)then
        am1(1:2)=xm(1,1:2)
        am2(1:2)=0.0d0
        am2(3)=1.0d0
        nm(:)=cross_product(am1,am2)
        nm(:)=nm(:)/dsqrt(dot_product(nm,nm))
        gvec(:)=0.0d0
        gvec(:)=xs(:) - xm(1,:)
        gap=dot_product(gvec,nm)
    elseif(dim_num == 3)then
        
        am1(:)=xm(1,:)
        am2(:)=xm(2,:)
        nm(:)=cross_product(am1,am2)
        if(dot_product(nm,nm) == 0.0d0)then
            
            stop "df"            
        endif
        nm(:)=nm(:)/dsqrt(dot_product(nm,nm))
        gvec(:)=xs(:) - xm(1,:)
        gap=dot_product(gvec,nm)
    else
        print *, "Error >> GetNormalGap >> dim_num should be 1,2 or 3. "
        stop
    endif

end subroutine
! #####################################################


! #####################################################
subroutine getKcmat(obj,stick,StickSlip)
    class(ContactMechanics_),intent(inout)  :: obj
    logical,optional,intent(in)             :: Stick
    logical,optional,intent(in)             :: StickSlip

    if( present(stick) )then
        if(stick .eqv. .true.)then
            call obj%getKcmatStick()
        endif
    endif

    if( present(StickSlip) )then
        if(stick .eqv. .true.)then
            call obj%getKcmatStickSlip()
        endif
    endif

end subroutine
! #####################################################

! #####################################################
subroutine getKcmatStick(obj)
    class(ContactMechanics_),intent(inout)  :: obj


	real(real64),allocatable ::nts_amo(:,:),k_contact(:,:),fvec_contact(:)
	real(real64),allocatable :: old_nod_coord(:,:),uvec(:),contact_mat_para(:,:)
    integer             :: elem_id,nod_max
    integer,allocatable :: nts_elem_nod(:,:),active_nts(:),nts_mat(:)
    integer,allocatable :: stick_slip(:)
    
    integer             :: NumOfNode,NumOfNTSElem,i,nts_elem_id
     
    NumOfNTSElem=size(obj%FEMIface%NTS_ElemNod,1)
    
    NumOfNode=size(obj%FEMDomain1%Mesh%NodCoord,1)+size(obj%FEMDomain1%Mesh%NodCoord,2)
    
    do i=1,NumOfNTSElem
        nts_elem_id=i
        nod_max = NumOfNode

        call state_stick(nts_elem_id,nod_max,obj%GloNodCoord,obj%FEMIface%NTS_ElemNod,&
        obj%FEMIface%NTS_Active&
        ,obj%NTSVariables, obj%KcontactGlo,obj%NTSMaterial,&
        obj%ContactMatPara,obj%DispVecGlo,obj%FcontactGlo,obj%StickOrSlip)
    enddo
end subroutine
! #####################################################


! #####################################################
subroutine getKcmatStickSlip(obj)
    class(ContactMechanics_),intent(inout)  :: obj
    
end subroutine
! #####################################################


! #####################################################
! From here, imported from old library
! #####################################################
!=============================================================
!itr =1 ;state stick
!----------------------

 subroutine state_stick(j,nod_max,old_nod_coord,nts_elem_nod,active_nts&
     ,nts_amo, k_contact,nts_mat,contact_mat_para,uvec,fvec_contact,stick_slip)
      !現在のnts_elementについて、すべてstick状態としてk_contactの計算
    real(real64), allocatable ::x2s(:),x11(:),x12(:),evec(:),avec(:),nvec(:)&
	,k_st(:,:),ns(:),n0s(:),ts(:),ts_st(:),t0s(:),ngz0(:),fvec_e(:),nod_coord(:,:),&
	nvec_(:),tvec_(:),x1(:),x2(:),x3(:),x4(:),x5(:),x6(:),tvec(:),mvec(:),yi(:),Dns(:,:),&
	ym(:),ys(:),nvec__(:),ovec(:),mvec_(:),mvec__(:),Dns_1(:),Dns_2(:),Dns_3(:),domega_mat(:),&
	Dns_1_1(:),Ivec(:),dtmat(:,:),dmmat(:,:),dnmat__(:,:),dgzivec(:),dalpha(:),dHvec(:),nt(:),&
	Dnt(:,:),dT0vec(:),dtmat_(:,:),dselvec(:),dmmat_(:,:),dgzi_hat_vec(:),dganma_hat_vec(:),&
	dganmavec_(:),dnmat_(:,:),dgzivec_(:),dsjkvec(:),dlamdavec_(:),Svec(:),Ft(:),yL(:),tvec__(:),&
	ye(:),yj(:),yk(:),c_nod_coord(:,:)
	

	real(real64) ,intent(inout)::nts_amo(:,:),k_contact(:,:),fvec_contact(:)
	real(real64), intent(in) :: old_nod_coord(:,:),uvec(:),contact_mat_para(:,:)
    integer, intent(in) :: j, nod_max,nts_elem_nod(:,:),active_nts(:),nts_mat(:)
	integer, intent(inout) :: stick_slip(:)
    real(real64) c,phy,en,ct,gns,gz,l,pn,tts,gt,gz0,alpha,omega,gns_,gz_,sjk,delta
	real(real64) gzi_hat,delta_hat,ganma_,kappa,S0,ganma,gzi_,ganma_hat,lamda_,T0,dfdtn,HH,sel
	integer i, ii , k,beta,i_1,ii_1,node_ID
	 
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 allocate(x2s(2),x11(2),x12(2),evec(3),avec(3),nvec(3),k_st(8,8),&
	 ns(8),n0s(8),ts(8),t0s(8),ngz0(8),ts_st(8),fvec_e(8),tvec(2),mvec(2) )
	 allocate( nvec_(3),tvec_(3),x1(2),x2(2),x3(2),x4(2),x5(2),x6(2),yi(2) )
	 allocate(ym(2),ys(2),nvec__(2),ovec(2),mvec_(2),mvec__(2),Dns(8,8),Dns_1_1(8) )
	 allocate(Dns_1(8),domega_mat(8),Ivec(2) )
	allocate(dtmat(2,8),dmmat(2,8),dnmat__(2,8),dgzivec(8),dalpha(8),dHvec(8) )
	allocate(nod_coord(size(old_nod_coord,1),size(old_nod_coord,2)))
	allocate(nt(8),Dnt(8,8),dT0vec(8),dtmat_(2,8),dselvec(8),dmmat_(2,8),dgzi_hat_vec(8)  )
	allocate( dganma_hat_vec(8),dganmavec_(8),dnmat_(2,8),dgzivec_(8),dsjkvec(8),dlamdavec_(8)  )
	allocate(Svec(8),Ft(8),yL(2),tvec__(1:2) )
	
	allocate(ye(2),yj(2),yk(2),c_nod_coord(size(nod_coord,1),size(nod_coord,2)  )  )
	
	do i=1, size(nod_coord,1)
		nod_coord(i,1)=old_nod_coord(i,1)
		nod_coord(i,2)=old_nod_coord(i,2)
	enddo
	 do i=1,size(nod_coord,1)
		c_nod_coord(i,1)=nod_coord(i,1)+uvec(2*i-1)
		c_nod_coord(i,2)=nod_coord(i,2)+uvec(2*i  )
	 enddo
	 !-----材料パラメータの読み込み------
	 en=contact_mat_para(nts_mat( active_nts(j) ),2 )
	 ct=contact_mat_para(nts_mat( active_nts(j) ),1 )
	 c = contact_mat_para(nts_mat( active_nts(j) ),3 )
	 phy=contact_mat_para(nts_mat( active_nts(j) ),4 )
	 !--------------------------------
	 delta=1.0e-5
	 tts=nts_amo(active_nts(j),12)
	 nts_amo(active_nts(j),11)=tts 
	 !dfdtn=nts_amo(active_nts(j),10) 
	 if(tts>=0.0d0)then
		dfdtn=1.0d0
	  elseif(tts<0.0d0)then
		dfdtn=-1.0d0
	 else
		 stop "invalid tTs"
	  endif
	 !以下、初期座標＋変位により、位置ベクトルを更新し、諸量を更新
	 !gz更新
	 x1(1:2) = uvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		nod_coord(nts_elem_nod(active_nts(j),1),1:2)
	 x2(1:2) = uvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		nod_coord(nts_elem_nod(active_nts(j),2),1:2)
	 x3(1:2) = uvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		nod_coord(nts_elem_nod(active_nts(j),3),1:2)	 
	 x4(1:2) = uvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		nod_coord(nts_elem_nod(active_nts(j),4),1:2)
	x5(1:2) = uvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		nod_coord(nts_elem_nod(active_nts(j),5),1:2)
	x6(1:2) = uvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		nod_coord(nts_elem_nod(active_nts(j),6),1:2)
	 node_ID=active_nts(j)
	 
	 
	call get_beta_st_nts(node_ID,nts_elem_nod,c_nod_coord,beta)
	
	if(beta==1)then
		x2s(1:2) = x1(:)
		x11(1:2) = x2(:)
		x12(1:2) = x3(:)
		yi(1:2) = x4(:)
		yj(1:2) = x2(1:2)
		yk(1:2) = x3(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x3(1:2)
		
		
		
	else
		x2s(1:2) = x1(:)
		x11(1:2) = x4(:)
		x12(1:2) = x2(:)
		yi(1:2) = x3(:)
		yj(1:2) = x4(1:2)
		yk(1:2) = x2(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x4(1:2)
		
	endif
	
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 !-----------------------------------------------------------------------
	 
     !-----------------------------------------------------------------------

	 nvec(3) = 0.0d0
	 
	 avec(3) = 0.0d0
	 
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	 
	 Ivec(1) = 1.0d0
	 Ivec(2) = 1.0d0
	 
	 nvec_(3) = 0.0d0
	 tvec_(3) = 0.0d0
	!----------------------------------
	 l = dot_product( yj(1:2)-yk(1:2), yj(1:2)-yk(1:2)) 
	 l=dsqrt(l)
	sjk=l
	 if(l==0.0d0)then
		print *, "l=0 at element No.",node_ID
		 stop 
	 endif
	
	avec(1:2) = ( yk(1:2)-yj(1:2)  )/l

	 nvec(:) = cross_product(evec,avec)
	 gz=1.0d0/l*dot_product(ys(1:2)-yj(1:2),avec(1:2) )
	 gns = dot_product((ys(:)-ym(:)),nvec(1:2))
	 
	 

	 !alpha=4.0d0*gz*(1.0d0-gz)
	 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
	 !alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
	 alpha=1.0d0
	 !alpha=0.0d0
	 yL(:)=yi(:)+alpha*(ym(:)-yi(:))
	 sel=dsqrt(dot_product(ye-yL,ye-yL))
	 gz0=gz-tts/ct/sel

	 if(sel==0.0d0)then
			 stop  "error check_gn"
	endif
	tvec_(1:2)=(ye(:)-yL(:) )/sel
	nvec_(:)=cross_product(evec,tvec_)
	tvec(1:2)=avec(1:2)
	mvec(:)=gz*tvec(:)-gns/sjk*nvec(:)
	nvec__(1:2)=nvec_(1:2)*dble(beta) 
	 
	 !gnsの計算と更新-----------------------------------------------------
	 gns_ = dot_product((ys(:)-ym(:)),nvec__(1:2))	 
	 gz_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2) )
	 
	 !get f_contact(normal),K_contact(normal)
	 !compute common variables
	 gzi_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2) )
	 ganma_hat=1.0d0/sel*dot_product(ym-yi,nvec_(1:2) )
	 !HH=4.0d0*(1.0d0-2.0d0*gz)
	 !HH=-3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 HH=alpha*(delta*delta)*(4.0d0-8.0d0*gz)
	 HH=0.0d0
	 
	 omega=1.0d0/sjk*HH*gz_*dot_product(ym-yi,nvec__(1:2) )
	 
	 gzi_hat=1.0d0/sel*dot_product(ym-yi,tvec_(1:2) )
	 delta_hat=dot_product(ym-yi,nvec_(1:2) )
	 ganma_=1.0d0/sel*dot_product(ys-ym,nvec_(1:2) )
	
	 ganma=gns/sjk
	 ovec(1:2)=gz*nvec(1:2)+ganma*tvec(1:2)
	 mvec_(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 mvec__(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 !kappa=-8.0d0
	 !kappa=-2.0d0*3.1415926535d0*3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 !kappa=8.0d0
	 kappa=alpha*(delta)*(delta)*(delta)*(delta)*(4.0d0-8.0d0*gz) - 8.0d0*alpha*(delta*delta)
	 kappa=0.0d0
	 tvec__(1:2)=dble(beta)*tvec_(1:2)
	 S0=delta_hat*dble(beta)/sjk*( kappa*gzi_+HH*HH*(2.0d0*gzi_*gzi_hat-ganma_*ganma_hat)  )
	 
	 if(beta==1)then
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(5:6)=omega*(-mvec(1:2)  )
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=mvec(1:2)-tvec(1:2)
		Dns_1_1(5:6)=-mvec(:)
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(5:6)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,5:6)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk!!+-
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(5:6)=-1.0d0/sjk*mvec(1:2)
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(5:6)=-HH/sjk*mvec(1:2)
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(5:6)=-kappa/sjk*mvec(1:2)
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(5:6)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+(-alpha)*tvec_(1:2) !!+-
		dselvec(5:6)=dselvec(5:6)+tvec_(1:2)
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(5:6)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(5:6)=T0*(-mvec(1:2) )
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(5:6,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8) 
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))
		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration
		do i = 1,4
			do ii = 1, 4
			
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i-1,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i-1,2*ii)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i,2*ii)
		
			enddo
		enddo
		
		do i=1,4
			fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 )+fvec_e(2*i-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i))+fvec_e(2*i)	
		enddo
	

	

		
	 elseif(beta==-1)then
		!normal part >>>
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(-mvec(1:2)  )
		ns(5:6)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=-mvec(:)
		Dns_1_1(5:6)=mvec(1:2)-tvec(1:2)!!+-
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(5:6)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,5:6)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk!!+-
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=-1.0d0/sjk*mvec(1:2)
		dgzivec(5:6)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=-HH/sjk*mvec(1:2)
		dalpha(5:6)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=-kappa/sjk*mvec(1:2)
		dHvec(5:6)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(5:6)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+tvec_(1:2)
		dselvec(5:6)=dselvec(5:6)+(-alpha)*tvec_(1:2) !!+-
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(5:6)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*(-mvec(1:2) )
		nt(5:6)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(5:6,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8)
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))
		
		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration
		do i = 1,4
			do ii = 1, 4
				if(i==3)then
					i_1=4
				elseif(i==4)then
					i_1=3
				else
					i_1=i
				endif
				
				if(ii==3)then
					ii_1=4
				elseif(ii==4)then
					ii_1=3
				else
					ii_1=ii
				endif
				
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1-1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1-1,2*ii_1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1,2*ii_1)
			
			enddo
		enddo
		
		do i=1,4
			if(i==3)then
				i_1=4
			elseif(i==4)then
				i_1=3
			else
				i_1=i
			endif
			
			
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 )+fvec_e(2*i_1-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1))+fvec_e(2*i_1)	
		enddo		
			
			
		else
		
			 stop  "error :: invalid beta"
		endif


	
	 !諸量の更新
	 nts_amo(active_nts(j),1)     =gz0 !trial gzi0 on current timestep
	 nts_amo(active_nts(j),2)     =dble(beta) !trial beta on current timestep
	 !nts_amo(active_nts(j),10)    =gz !converged gzi at last timestep
	 !nts_amo(active_nts(j),11)    =pn !inactive
	 
	 
     
 
 end subroutine state_stick
 !============================================================
 !check for contact: gn<0 → active NTS-element----------------
 
 subroutine check_active(uvec,duvec,old_nod_coord,active_nts,nts_elem_nod)
    real(real64),intent(in)::uvec(:),duvec(:),old_nod_coord(:,:)
	real(real64),allocatable::nod_coord(:,:)
	integer,allocatable,intent(inout)::active_nts(:)
	integer,intent(in)::nts_elem_nod(:,:)
	integer,allocatable ::check_active_nts(:)
	integer active_nts_max,i,j
	
	allocate(nod_coord(size(old_nod_coord,1),size(old_nod_coord,2)))
	do i=1, size(nod_coord,1)
		nod_coord(i,1)=old_nod_coord(i,1)+uvec(2*i-1)+duvec(2*i-1)
		nod_coord(i,2)=old_nod_coord(i,2)+uvec(2*i  )+duvec(2*i  )
	enddo	
	
	allocate( check_active_nts(size(nts_elem_nod,1) )  )
	do i=1, size(nts_elem_nod,1)
	    call check_gn(i,nts_elem_nod,check_active_nts,nod_coord)
	enddo
	active_nts_max=0
	
	do i=1, size(nts_elem_nod,1 )
	   if( check_active_nts(i)==1 )then
	       active_nts_max=active_nts_max+1 !active
       elseif(check_active_nts(i)==0)then
	       cycle
	   else
	        stop "something wrong at check_active_nts"
	   endif
	enddo
	if( allocated(active_nts) )deallocate(active_nts)
	!print *, "active nts= ",active_nts_max,"/",size(nts_elem_nod,1)
	allocate(active_nts(active_nts_max) )
	
	j=0
	do i=1, size(nts_elem_nod,1)
	   if( check_active_nts(i)==1  )then
	      j=j+1
		  active_nts(j)=i
	   else
	      cycle
	   endif
	enddo
	
	
 end subroutine check_active
!=============================================================
!check gn
!-------------------
 subroutine check_gn(j,nts_elem_nod,check_active_nts,nod_coord)
	 real(real64), allocatable ::x2s(:),x11(:),x12(:),avec(:),nvec(:),evec(:),yL(:),tvec_(:),nvec_(:)
	
	real(real64), intent(in) :: nod_coord(:,:)
    integer, intent(in) :: j, nts_elem_nod(:,:)
    real(real64) gz,l,gns,alpha,sel,delta
	integer i,beta
	integer:: check_active_nts(:)
	delta=1.0e-5
	!get beta to determine the case (cf. W.N. Liu et al., 2003)
	call get_beta_st_nts(j,nts_elem_nod,nod_coord,beta)

	allocate(x2s(2),x11(2),x12(2),yL(2),tvec_(3),nvec_(3),avec(3),nvec(3),evec(3))
	 
	if(beta==1)then
		x2s(1:2) = nod_coord(nts_elem_nod(j,1),1:2)
		x11(1:2) = nod_coord(nts_elem_nod(j,2),1:2)
		x12(1:2) = nod_coord(nts_elem_nod(j,3),1:2)
	else
		x2s(1:2) = nod_coord(nts_elem_nod(j,1),1:2)
		x11(1:2) = nod_coord(nts_elem_nod(j,4),1:2)
		x12(1:2) = nod_coord(nts_elem_nod(j,2),1:2)
	endif
	
	
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 !-----------------------------------------------------------------------
	 
     !-----------------------------------------------------------------------

	 nvec(3) = 0.0d0
	 avec(3) = 0.0d0
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	 nvec_(3) = 0.0d0
	 tvec_(3) = 0.0d0
	!----------------------------------
	 l = dot_product( x12(1:2)-x11(1:2), x12(1:2)-x11(1:2)) 
	 l=dsqrt(l)

	 if(l==0.0d0)then
		print *, "l=0 at element No.",j
		 stop 
	 endif

	 avec(1:2) = ( x12(1:2)-x11(1:2)  )/l

	 nvec(:) = cross_product(evec,avec)
	 gz=1.0d0/l*dot_product(x2s(1:2)-x11(1:2),avec(1:2) )
	 
	
	 if(beta==1)then
		 !alpha=4.0d0*gz*(1.0d0-gz)
		 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
		 !alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
		 alpha=1.0d0
		 !alpha=0.0d0
		yL(:)=nod_coord(nts_elem_nod(j,4),1:2)+alpha*&
			(nod_coord(nts_elem_nod(j,2),1:2)-nod_coord(nts_elem_nod(j,4),1:2) )
		sel=dsqrt(dot_product(x12-yL,x12-yL))
		
		if(sel==0.0d0)then
			 stop  "error check_gn"
		endif
		tvec_(1:2)=(x12(:)-yL(:) )/sel
		nvec_(:)=cross_product(evec,tvec_)
		 nvec_(:)=nvec_(:)*dble(beta) 
		 gns = dot_product((x2s(:)-x11(:)),nvec_(1:2))
	else
		!alpha=4.0d0*gz*(1.0d0-gz)
		!alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
		!alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
		alpha=1.0d0
		!alpha=0.0d0
		yL(:)=nod_coord(nts_elem_nod(j,3),1:2)+alpha*&
			(nod_coord(nts_elem_nod(j,2),1:2)-nod_coord(nts_elem_nod(j,3),1:2) )
		sel=dsqrt(dot_product(x11-yL,x11-yL))
		if(sel==0.0d0)then
			 stop  "error check_gn"
		endif
		tvec_(1:2)=(x11(:)-yL(:) )/sel
		nvec_(:)=cross_product(evec,tvec_)
		nvec_(:)=nvec_(:)*dble(beta) 
		gns = dot_product((x2s(:)-x12(:)),nvec_(1:2))
	endif
	
	
	 
	 !gnsの計算と更新-----------------------------------------------------
	 
	 !---------------------------------------------------------------------
	
	 
	 if(gns > 0.0d0)then
	    check_active_nts(j)=0
	 elseif(gns <= 0.0d0)then
	    check_active_nts(j)=1
	 else
	     stop 'invalid No. on check_active_nts'
	 endif
	 
	 deallocate(x2s,x11,x12,avec,nvec,evec)
	  
	  
 end subroutine check_gn

!=============================================================
!update friction
!-------------------
 subroutine update_friction(j,nod_max,nod_coord,nts_elem_nod,active_nts,surface_nod,sur_nod_inf&
              ,nts_amo, k_contact,uvec,duvec,fvec_contact,stick_slip,contact_mat_para,nts_mat,itr_contact)
	 real(real64), allocatable ::x2s(:), dgt(:),tt_tr(:),gslt(:),&
	n_t(:),K_st(:,:),ns(:),n0s(:),ts(:),t0s(:),ngz0(:), &
	x11(:),x12(:),evec(:),gt(:),avec(:),&
	nvec(:),k_sl(:,:),n_tr(:),ts_st(:),ts_sl(:),fvec_e(:),&
	x1(:),x2(:),x3(:),x4(:),x5(:),x6(:),&
	x1_0(:),x2_0(:),x3_0(:),x4_0(:),x5_0(:),x6_0(:),c_nod_coord(:,:),&
	tvec_(:),nvec_(:),xe(:), xL(:),xs_1(:),xs_2(:),xs_0(:)

	real(real64), intent(inout) ::nts_amo(:,:),k_contact(:,:),fvec_contact(:)
	real(real64), intent(in) :: nod_coord(:,:),uvec(:),duvec(:),contact_mat_para(:,:)
    integer, intent(in) :: j, nod_max,nts_elem_nod(:,:),active_nts(:),nts_mat(:),itr_contact
	integer, intent(in) :: surface_nod(:),sur_nod_inf(:,:)
	integer, intent(inout) ::stick_slip(:)
    real(real64) c,phy,en,ct,f_tr,Lamda,gns,gz0,gz,l,pn,f_tr0,x,tts,tol_rmm,signm,beta_0,alpha,sel,gz0_,gz_,c_num,delta
	real(real64) l_s1,l_s2,ls_ave
	integer i, ii ,k,ss,itr_rm,z,gzn,node_ID,beta,shift,old_slave,slave1,slave2
	 
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 tol_rmm=1.0e-12
	 delta=1.0e-5
	 allocate(x2s(2),x11(2),x12(2),evec(3),&
	 dgt(2),gt(2),gslt(2),tt_tr(2),avec(3),nvec(3),k_st(6,6),k_sl(6,6),&
	 ns(6),n0s(6),ts(6),t0s(6),ngz0(6),ts_st(6),ts_sl(6),fvec_e(6) )
	 allocate(x1(2),x2(2),x3(2),x4(2),x5(2),x6(2))
	 allocate(x1_0(2),x2_0(2),x3_0(2),x4_0(2),x5_0(2),x6_0(2))
	 allocate( c_nod_coord(size(nod_coord,1) ,size(nod_coord,2)),tvec_(3),nvec_(3) )
	 allocate(xe(2), xL(2),xs_1(2),xs_2(2),xs_0(2) )
	 tvec_(3)=0.0d0
	 nvec_(3)=0.0d0
     !-----諸量の読み込み------
	 !tts = nts_amo(active_nts(j),12)!初期または全ステップ終了時のξ
	 !gt(1:2)=nts_amo(active_nts(j),2:3)
	 !gslt(1:2)=nts_amo(active_nts(j),4:5)
	 !en=nts_amo(active_nts(j),6)
	! ct = nts_amo(active_nts(j),7)
	 !c = nts_amo(active_nts(j),8)
	! gslt(1:2)=nts_amo(active_nts(j),4:5)
	 tts=nts_amo(active_nts(j),11) !previous step
	 !tts = nts_amo(active_nts(j),12) !converged gz0 at last timestep
	 !beta_0 = nts_amo(active_nts(j),2) !converged gz0 at last timestep
	 !--------------------------
	 !-----材料パラメータの読み込み------
	 en=contact_mat_para(nts_mat( active_nts(j) ),2 )
	 ct=contact_mat_para(nts_mat( active_nts(j) ),1 )
	 c = contact_mat_para(nts_mat( active_nts(j) ),3 )
	 phy=contact_mat_para(nts_mat( active_nts(j) ),4 )
	 !--------------------------
	 
	 do i=1,size(nod_coord,1)
		c_nod_coord(i,1)=nod_coord(i,1)+uvec(2*i-1)+duvec(2*i-1)
		c_nod_coord(i,2)=nod_coord(i,2)+uvec(2*i  )+duvec(2*i  )
	 enddo
	 
!以下、初期座標＋変位により、位置ベクトルを更新し、諸量を更新
	 !gz更新
	 x1(1:2) = uvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		duvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		nod_coord(nts_elem_nod(active_nts(j),1),1:2)
	 x2(1:2) = uvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		duvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		nod_coord(nts_elem_nod(active_nts(j),2),1:2)
	 x3(1:2) = uvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		duvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		nod_coord(nts_elem_nod(active_nts(j),3),1:2)	 
	 x4(1:2) = uvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		duvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		nod_coord(nts_elem_nod(active_nts(j),4),1:2)
	x5(1:2) = uvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		duvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		nod_coord(nts_elem_nod(active_nts(j),5),1:2)
	x6(1:2) = uvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		duvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		nod_coord(nts_elem_nod(active_nts(j),6),1:2)
		
		
	x1_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		nod_coord(nts_elem_nod(active_nts(j),1),1:2)
	 x2_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		nod_coord(nts_elem_nod(active_nts(j),2),1:2)
	 x3_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		nod_coord(nts_elem_nod(active_nts(j),3),1:2)	 
	 x4_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		nod_coord(nts_elem_nod(active_nts(j),4),1:2)
	x5_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		nod_coord(nts_elem_nod(active_nts(j),5),1:2)
	x6_0(1:2) = uvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		nod_coord(nts_elem_nod(active_nts(j),6),1:2)
	 node_ID=active_nts(j)
	 
	 
	call get_beta_st_nts(node_ID,nts_elem_nod,c_nod_coord,beta)

	!============================
	!compute gzi_0
	if(beta==1)then
		x2s(1:2) = x1_0(:)
		x11(1:2) = x2_0(:)
		x12(1:2) = x3_0(:)
	else
		x2s(1:2) = x1_0(:)
		x11(1:2) = x4_0(:)
		x12(1:2) = x2_0(:)
	endif
	 nvec(3) = 0.0d0
	 avec(3) = 0.0d0
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	!----------------------------------
	 l = dot_product( x12(1:2)-x11(1:2), &
		 x12(1:2)-x11(1:2)) 
	 l=dsqrt(l)
	 
	 if(l==0.0d0)then
		print *, "l=0 at element No.",j
		 stop 
	 endif
	 if(ct==0.0d0)then

		print *, "ct=0 at element No.",j
		 stop 
	 endif
	 
	 avec(1:2) = ( x12(1:2)-x11(1:2)  )/l
	 
	 nvec(:) = cross_product(evec,avec)
	 nvec(:)=nvec(:)/sqrt(dot_product(nvec,nvec)  )
	 gz0=1.0d0/l*dot_product(x2s(1:2)-x11(1:2),avec(1:2) )	
	 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz0) )
	 !alpha=exp( -delta*delta*(2.0d0*gz0-1.0d0)**2.0d0 )
	 !alpha=1.0d0
	 !alpha=0.0d0
	 if(beta==1)then
		xe(1:2)=x3_0(1:2)
		xL(1:2)=x4_0(1:2)+alpha*( x2_0(1:2) - x4_0(1:2)  )
		tvec_(1:2)=(xe(1:2)-xL(1:2))/dsqrt(dot_product(xe-xL,xe-xL)  )
		nvec_(1:3)=cross_product(evec,tvec_)
		nvec_(1:2)=nvec_(1:2)*dble(beta)
		gns=dot_product( x1_0(1:2)-x2_0(1:2),nvec_(1:2) )
		
	else
		xe(1:2)=x4_0(1:2)
		xL(1:2)=x3_0(1:2)+alpha*( x2_0(1:2) - x3_0(1:2)  )
		tvec_(1:2)=(xe(1:2)-xL(1:2))/dsqrt(dot_product(xe-xL,xe-xL)  )
		nvec_(1:3)=cross_product(evec,tvec_)
		nvec_(1:2)=nvec_(1:2)*dble(beta)
		gns=dot_product( x1_0(1:2)-x2_0(1:2),nvec_(1:2) )
		
		
	endif
	sel=dsqrt(dot_product(xL(1:2)-xe(1:2),xL(1:2)-xe(1:2) ))
	gz0_=1.0d0/sel*dot_product( x1_0(:)-x2_0(:),dble(beta)*tvec_(1:2) )
	
	!=====================
	!compute gzi
	if(beta==1)then
		x2s(1:2) = x1(:)
		x11(1:2) = x2(:)
		x12(1:2) = x3(:)
		
	else
		x2s(1:2) = x1(:)
		x11(1:2) = x4(:)
		x12(1:2) = x2(:)
		
	endif
	 nvec(3) = 0.0d0
	 avec(3) = 0.0d0
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	!----------------------------------
	 l = dot_product( x12(1:2)-x11(1:2), &
		 x12(1:2)-x11(1:2)) 
	 l=dsqrt(l)
	 
	 if(l==0.0d0)then
		print *, "l=0 at element No.",j
		 stop 
	 endif
	 if(ct==0.0d0)then

		print *, "ct=0 at element No.",j
		 stop 
	 endif
	 
	 avec(1:2) = ( x12(1:2)-x11(1:2)  )/l
	 
	 nvec(:) = cross_product(evec,avec)
	 nvec(:)=nvec(:)/dsqrt(dot_product(nvec,nvec)  )
	 gz=1.0d0/l*dot_product(x2s(1:2)-x11(1:2),avec(1:2) )
	 !alpha=4.0d0*gz*(1.0d0-gz)
	 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
	 
	 !alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
	 alpha=1.0d0
	!alpha=0.0d0
	!gz0=gz-tts/ct/l
	 !gnsの計算と更新-----------------------------------------------------
	 if(beta==1)then
		xe(1:2)=x3(1:2)
		xL(1:2)=x4(1:2)+alpha*( x2(1:2) - x4(1:2)  )
		tvec_(1:2)=(xe(1:2)-xL(1:2))/dsqrt(dot_product(xe-xL,xe-xL)  )
		nvec_(1:3)=cross_product(evec,tvec_)
		nvec_(1:2)=nvec_(1:2)*dble(beta)
		gns=dot_product( x1(1:2)-x2(1:2),nvec_(1:2) )
		
	else
		xe(1:2)=x4(1:2)
		xL(1:2)=x3(1:2)+alpha*( x2(1:2) - x3(1:2)  )
		tvec_(1:2)=(xe(1:2)-xL(1:2))/dsqrt(dot_product(xe-xL,xe-xL)  )
		nvec_(1:3)=cross_product(evec,tvec_)
		nvec_(1:2)=nvec_(1:2)*dble(beta)
		gns=dot_product( x1(1:2)-x2(1:2),nvec_(1:2) )
		
		
	endif
	 !gns = dot_product((x2s(:)-(1.0d0-gz)*x11(:)-gz*x12(:)),nvec(1:2))
	 sel=dsqrt(dot_product(xL(1:2)-xe(1:2),xL(1:2)-xe(1:2) ))
	 gz_=1.0d0/sel*dot_product( x1(:)-x2(:),dble(beta)*tvec_(1:2) )
	 pn=en*gns
	 
	 
	 !---------------------------------------------------------------------
	 !trial tTs(frictional force)
	 gz0_=gz0_-tts/ct/sel !gzi_0の補正(現時点でのfrictional stress を考慮)
	 tts=ct*( gz_ -gz0_ )*sel ! compute trial tts 
	 
	 
	
	 !------降伏関数の計算------------------------
	 !compute numerical c (kPa)
	 shift=1
	 old_slave=nts_elem_nod(active_nts(j),4)
	 call get_next_segment(surface_nod,sur_nod_inf,shift,old_slave,slave1,slave2)
	 shift=-1
	 old_slave=nts_elem_nod(active_nts(j),4)
	 call get_next_segment(surface_nod,sur_nod_inf,shift,old_slave,slave2,slave1)
	 xs_0(1:2)=uvec(2*old_slave-1:2*old_slave)+&
		duvec(2*old_slave-1:2*old_slave)+&
		nod_coord(old_slave,1:2)
	xs_1(1:2)=uvec(2*slave1-1:2*slave1)+&
		duvec(2*slave1-1:2*slave1)+&
		nod_coord(slave1,1:2)
	xs_2(1:2)=uvec(2*slave2-1:2*slave2)+&
		duvec(2*slave2-1:2*slave2)+&
		nod_coord(slave2,1:2)
	l_s1=dsqrt(dot_product(xs_0-xs_1,xs_0-xs_1)  )
	l_s2=dsqrt(dot_product(xs_0-xs_2,xs_0-xs_2)  )
	ls_ave=0.50d0*(l_s1+l_s2)
	
	c_num=c*ls_ave/l 
	 
	 ! print *,"tts=",tts,pn,sel,l,c,c_num,alpha
	 
	 f_tr0 = abs(tts)-((tan(phy))*abs(pn) + c_num)
	!------------------------------
	 itr_rm=1

	 !----------------------降伏関数の値による場合わけ--------------------
	 if(f_tr0<=0.0d0) then      
		  !print *, "stick"
		  stick_slip( active_nts(j)  )=0
     elseif(f_tr0>0.0d0)then

		 !--------------------plastic------------------------------!
		 !ss=1
		 
		 !allocate(n_tr(2))
		 
	      !do
		      
              !---繰り返し回数計測用変数の更新-------
			!  itr_rm=itr_rm+1
			  
			  !------デバッグ用--itr_rm=5で停止----
			 ! if(itr_rm==5)then
			 !      stop  'itr_rm=5'
			 ! endif

			  !write(1000,*)"slip"
			  !print *, "slip"
			  !------Return Mapping Calculation -----------------------------
			  !------降伏曲面の法線ベクトルnの計算----------------------
			  
			  if(tts>=0.0d0)then
				signm=1.0d0
			  elseif(tts<0.0d0)then
				signm=-1.0d0
			 else
				 stop "invalid tTs"
			  endif
			  stick_slip( active_nts(j)  )=1
			  tts=((tan(phy))*abs(pn)+ c_num)*signm
			  !gz0=gz-tts/ct/l
			 ! n_tr(:)=1.0d0/dsqrt((dot_product(tt_tr,tt_tr)))*tt_tr(:)
			  
			  !塑性指数Lamda,tt_tr,gsltの更新(Computational contact mechanics 
			  
			  !Lamda=1.0d0/ct*(dsqrt(dot_product(tt_tr,tt_tr))&
			  !  -(abs(pn)*tan(phy)+c) ) !pnは負、cは正

			  !gslt(:)=gslt(:)+Lamda*n_tr(:)
			  !tt_tr(:) =ct*( gt(:)-gslt(:)  )
			  !------debug
			   !write(1000,*)'RM itr=',ss
			  !-------      

			  !f_tr = dsqrt(dot_product(tt_tr,tt_tr))-((tan(phy))*abs(pn)+c)

			  !---------------------------------------------------------------
			  !収束判定
			  !   if( abs(f_tr)< tol_rmm*abs(f_tr0))then

				!	 tts=ct*dot_product((gt-gslt),avec)
					 
			!		 deallocate(n_tr) !  stop ' stop  return mapping'
			!		 exit
			 !    else
				     
             !        ss=ss+1
			!	     cycle
			 !    endif
	      !enddo
		  
	  else
	       stop  'something wrong about f_tr0'
	  endif
	 


    !諸量の更新
	 !gz0=gz-tts/ct/l
	 
	! nts_amo(active_nts(j),2:3)  =gt(1:2)
	! nts_amo(active_nts(j),4:5)=gslt(1:2)
	 
	 nts_amo(active_nts(j),12)=tts
	 nts_amo(active_nts(j),10) =signm
	 deallocate(x2s,x11,x12,evec,&
	 gt,gslt,tt_tr,avec,nvec,k_st,k_sl,&
	 ns,n0s,ts,t0s,ngz0,ts_sl,fvec_e)
	 
	 
	 
	  
 end subroutine update_friction

!==============================================================

 subroutine update_res_grad_c_i(j,nod_max,old_nod_coord,nts_elem_nod,active_nts&
              ,nts_amo, k_contact,uvec,duvec,fvec_contact,stick_slip,contact_mat_para,nts_mat)




	real(real64), allocatable ::x2s(:),x11(:),x12(:),evec(:),avec(:),nvec(:)&
	,k_st(:,:),ns(:),n0s(:),ts(:),ts_st(:),t0s(:),ngz0(:),fvec_e(:),nod_coord(:,:),&
	nvec_(:),tvec_(:),x1(:),x2(:),x3(:),x4(:),x5(:),x6(:),tvec(:),mvec(:),yi(:),Dns(:,:),&
	ym(:),ys(:),nvec__(:),ovec(:),mvec_(:),mvec__(:),Dns_1(:),Dns_2(:),Dns_3(:),domega_mat(:),&
	Dns_1_1(:),Ivec(:),dtmat(:,:),dmmat(:,:),dnmat__(:,:),dgzivec(:),dalpha(:),dHvec(:),nt(:),&
	Dnt(:,:),dT0vec(:),dtmat_(:,:),dselvec(:),dmmat_(:,:),dgzi_hat_vec(:),dganma_hat_vec(:),&
	dganmavec_(:),dnmat_(:,:),dgzivec_(:),dsjkvec(:),dlamdavec_(:),Svec(:),Ft(:),yL(:),tvec__(:),&
	ye(:),yj(:),yk(:),c_nod_coord(:,:)
	

	real(real64) ,intent(inout)::nts_amo(:,:),k_contact(:,:),fvec_contact(:)
	real(real64), intent(in) :: old_nod_coord(:,:),uvec(:),contact_mat_para(:,:),duvec(:)
    integer, intent(in) :: j, nod_max,nts_elem_nod(:,:),active_nts(:),nts_mat(:)
	integer, intent(inout) :: stick_slip(:)
    real(real64) c,phy,en,ct,gns,gz,l,pn,tts,gt,gz0,alpha,omega,gns_,gz_,sjk,delta
	real(real64) gzi_hat,delta_hat,ganma_,kappa,S0,ganma,gzi_,ganma_hat,lamda_,T0,dfdtn,HH,sel
	integer i, ii , k,beta,i_1,ii_1,node_ID
	 
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 allocate(x2s(2),x11(2),x12(2),evec(3),avec(3),nvec(3),k_st(8,8),&
	 ns(8),n0s(8),ts(8),t0s(8),ngz0(8),ts_st(8),fvec_e(8),tvec(2),mvec(2) )
	 allocate( nvec_(3),tvec_(3),x1(2),x2(2),x3(2),x4(2),x5(2),x6(2),yi(2) )
	 allocate(ym(2),ys(2),nvec__(2),ovec(2),mvec_(2),mvec__(2),Dns(8,8),Dns_1_1(8) )
	 allocate(Dns_1(8),domega_mat(8),Ivec(2) )
	allocate(dtmat(2,8),dmmat(2,8),dnmat__(2,8),dgzivec(8),dalpha(8),dHvec(8) )
	allocate(nod_coord(size(old_nod_coord,1),size(old_nod_coord,2)))
	allocate(nt(8),Dnt(8,8),dT0vec(8),dtmat_(2,8),dselvec(8),dmmat_(2,8),dgzi_hat_vec(8)  )
	allocate( dganma_hat_vec(8),dganmavec_(8),dnmat_(2,8),dgzivec_(8),dsjkvec(8),dlamdavec_(8)  )
	allocate(Svec(8),Ft(8),yL(1:2),tvec__(1:2) )
	allocate(ye(2),yj(2),yk(2),c_nod_coord(size(nod_coord,1),size(nod_coord,2)  ) )
	do i=1, size(nod_coord,1)
		nod_coord(i,1)=old_nod_coord(i,1)
		nod_coord(i,2)=old_nod_coord(i,2)
	enddo
	do i=1,size(nod_coord,1)
		c_nod_coord(i,1)=nod_coord(i,1)+uvec(2*i-1)
		c_nod_coord(i,2)=nod_coord(i,2)+uvec(2*i  )
	 enddo
	 nvec_(3)=0.0d0
	 tvec_(3)=0.0d0
	 
	 delta=1.0e-5
	 !-----材料パラメータの読み込み------
	 en=contact_mat_para(nts_mat( active_nts(j) ),2 )
	 ct=contact_mat_para(nts_mat( active_nts(j) ),1 )
	 c = contact_mat_para(nts_mat( active_nts(j) ),3 )
	 phy=contact_mat_para(nts_mat( active_nts(j) ),4 )
	 !--------------------------------
	  
	 tts=nts_amo(active_nts(j),12) 
	 !dfdtn=nts_amo(active_nts(j),10) 
	  if(tts>=0.0d0)then
		dfdtn=1.0d0
	  elseif(tts<0.0d0)then
		dfdtn=-1.0d0
	 else
		 stop "invalid tTs"
	  endif
	 !以下、初期座標＋変位により、位置ベクトルを更新し、諸量を更新
	 !gz更新
	 x1(1:2) = uvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		duvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		nod_coord(nts_elem_nod(active_nts(j),1),1:2)
	 x2(1:2) = uvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		duvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		nod_coord(nts_elem_nod(active_nts(j),2),1:2)
	 x3(1:2) = uvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		duvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		nod_coord(nts_elem_nod(active_nts(j),3),1:2)	 
	 x4(1:2) = uvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		duvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		nod_coord(nts_elem_nod(active_nts(j),4),1:2)
	x5(1:2) = uvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		duvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		nod_coord(nts_elem_nod(active_nts(j),5),1:2)
	x6(1:2) = uvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		duvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		nod_coord(nts_elem_nod(active_nts(j),6),1:2)
	 node_ID=active_nts(j)
	 
	 
	call get_beta_st_nts(node_ID,nts_elem_nod,c_nod_coord,beta)
	if(beta==1)then
		x2s(1:2) = x1(:)
		x11(1:2) = x2(:)
		x12(1:2) = x3(:)
		yi(1:2) = x4(:)
		yj(1:2) = x2(1:2)
		yk(1:2) = x3(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x3(1:2)
		
		
		
	else
		x2s(1:2) = x1(:)
		x11(1:2) = x4(:)
		x12(1:2) = x2(:)
		yi(1:2) = x3(:)
		yj(1:2) = x4(1:2)
		yk(1:2) = x2(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x4(1:2)
		
	endif
	
!-----------------------------------------------------------------------

	 nvec(3) = 0.0d0
	 
	 avec(3) = 0.0d0
	 
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	 
	 Ivec(1) = 1.0d0
	 Ivec(2) = 1.0d0
	 
	 nvec_(3) = 0.0d0
	 tvec_(3) = 0.0d0
	!----------------------------------
	 l = dot_product( yj(1:2)-yk(1:2), yj(1:2)-yk(1:2)) 
	 l=dsqrt(l)
	sjk=l
	 if(l==0.0d0)then
		print *, "l=0 at element No.",node_ID
		 stop 
	 endif
	
	avec(1:2) = ( yk(1:2)-yj(1:2)  )/l

	 nvec(:) = cross_product(evec,avec)
	 gz=1.0d0/l*dot_product(ys(1:2)-yj(1:2),avec(1:2) )
	 gns = dot_product((ys(:)-ym(:)),nvec(1:2))
	 
	 

	! alpha=4.0d0*gz*(1.0d0-gz)
	 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
	 !alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
	 alpha=1.0d0
	 !alpha=0.0d0
	 yL(:)=yi(:)+alpha*(ym(:)-yi(:))
	 sel=dsqrt(dot_product(ye-yL,ye-yL))
	 gz0=gz-tts/ct/sel

	 if(sel==0.0d0)then
			 stop  "error check_gn"
	endif
	tvec_(1:2)=(ye(:)-yL(:) )/sel
	nvec_(:)=cross_product(evec,tvec_)
	tvec(1:2)=avec(1:2)
	mvec(:)=gz*tvec(:)-gns/sjk*nvec(:)
	nvec__(1:2)=nvec_(1:2)*dble(beta) 
	 
	 !gnsの計算と更新-----------------------------------------------------
	 gns_ = dot_product((ys(:)-ym(:)),nvec__(1:2))	 
	 gz_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2) )
	 
	 !get f_contact(normal),K_contact(normal)
	 !compute common variables
	 gzi_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2) )
	 ganma_hat=1.0d0/sel*dot_product(ym-yi,nvec_(1:2) )
	 !HH=4.0d0*(1.0d0-2.0d0*gz)
	 !HH=-3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 HH=alpha*(delta*delta)*(4.0d0-8.0d0*gz)
	 HH=0.0d0
	 omega=1.0d0/sjk*HH*gz_*dot_product(ym-yi,nvec__(1:2) )
	 
	 gzi_hat=1.0d0/sel*dot_product(ym-yi,tvec_(1:2) )
	 delta_hat=dot_product(ym-yi,nvec_(1:2) )
	 ganma_=1.0d0/sel*dot_product(ys-ym,nvec_(1:2) )
	
	 ganma=gns/sjk
	 ovec(1:2)=gz*nvec(1:2)+ganma*tvec(1:2)
	 mvec_(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 mvec__(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 !kappa=-8.0d0
	 !kappa=-2.0d0*3.1415926535d0*3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 kappa=alpha*(delta)*(delta)*(delta)*(delta)*(4.0d0-8.0d0*gz) - 8.0d0*alpha*(delta*delta)
	 kappa=0.0d0
	 
	 !kappa=8.0d0
	 tvec__(1:2)=dble(beta)*tvec_(1:2)
	 S0=delta_hat*dble(beta)/sjk*( kappa*gzi_+HH*HH*(2.0d0*gzi_*gzi_hat-ganma_*ganma_hat)  )
	 
	 if(beta==1)then
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(5:6)=omega*(-mvec(1:2)  )
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=mvec(1:2)-tvec(1:2)
		Dns_1_1(5:6)=-mvec(:)
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(5:6)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,5:6)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk!!+-
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(5:6)=-1.0d0/sjk*mvec(1:2)
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(5:6)=-HH/sjk*mvec(1:2)
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(5:6)=-kappa/sjk*mvec(1:2)
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(5:6)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+(-alpha)*tvec_(1:2) !!+-
		dselvec(5:6)=dselvec(5:6)+tvec_(1:2)
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(5:6)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(5:6)=T0*(-mvec(1:2) )
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(5:6,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8)
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))
		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration
		do i = 1,4
			do ii = 1, 4
			
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i-1,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i-1,2*ii)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i,2*ii)
		
			enddo
		enddo
		
		do i=1,4
			fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 )+fvec_e(2*i-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i))+fvec_e(2*i)	
		enddo
	

	

		
	 elseif(beta==-1)then
		!normal part >>>
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(-mvec(1:2)  )
		ns(5:6)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=-mvec(:)
		Dns_1_1(5:6)=mvec(1:2)-tvec(1:2)!!+-
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(5:6)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,5:6)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk!!+-
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=-1.0d0/sjk*mvec(1:2)
		dgzivec(5:6)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=-HH/sjk*mvec(1:2)
		dalpha(5:6)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=-kappa/sjk*mvec(1:2)
		dHvec(5:6)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(5:6)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+tvec_(1:2)
		dselvec(5:6)=dselvec(5:6)+(-alpha)*tvec_(1:2) !!+-
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(5:6)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*(-mvec(1:2) )
		nt(5:6)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(5:6,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8)
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))
		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration

	
		do i = 1,4
			do ii = 1, 4
				if(i==3)then
					i_1=4
				elseif(i==4)then
					i_1=3
				else
					i_1=i
				endif
				
				if(ii==3)then
					ii_1=4
				elseif(ii==4)then
					ii_1=3
				else
					ii_1=ii
				endif
				
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1-1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1-1,2*ii_1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1,2*ii_1)
			
			enddo
		enddo
		
		do i=1,4
			if(i==3)then
				i_1=4
			elseif(i==4)then
				i_1=3
			else
				i_1=i
			endif
			
			
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 )+fvec_e(2*i_1-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1))+fvec_e(2*i_1)	
		enddo		
			
			
		else
		
			 stop  "error :: invalid beta"
		endif
		
			do k=1,size(fvec_contact)
				if(fvec_contact(k)>=0.0d0 .or. fvec_contact(k)<0.0d0 )then
					cycle
				else
					 stop  "NaN ct !!"
				endif
			enddo

	 !諸量の更新
	 nts_amo(active_nts(j),1)     =gz0 !trial gzi0 on current timestep
	 !nts_amo(active_nts(j),10)    =gz !converged gzi at last timestep
	 nts_amo(active_nts(j),2)     =dble(beta) !trial beta on current timestep
	 !nts_amo(active_nts(j),11)    =pn !inactive


	 
	 
	  
 end subroutine update_res_grad_c_i

!==============================================================
 subroutine update_res_grad_c(j,nod_max,old_nod_coord,nts_elem_nod,active_nts&
              ,nts_amo, k_contact,uvec,duvec,fvec_contact,stick_slip,contact_mat_para,nts_mat)
			  
	real(real64), allocatable ::x2s(:),x11(:),x12(:),evec(:),avec(:),nvec(:)&
	,k_st(:,:),ns(:),n0s(:),ts(:),ts_st(:),t0s(:),ngz0(:),fvec_e(:),nod_coord(:,:),&
	nvec_(:),tvec_(:),x1(:),x2(:),x3(:),x4(:),x5(:),x6(:),tvec(:),mvec(:),yi(:),Dns(:,:),&
	ym(:),ys(:),nvec__(:),ovec(:),mvec_(:),mvec__(:),Dns_1(:),Dns_2(:),Dns_3(:),domega_mat(:),&
	Dns_1_1(:),Ivec(:),dtmat(:,:),dmmat(:,:),dnmat__(:,:),dgzivec(:),dalpha(:),dHvec(:),nt(:),&
	Dnt(:,:),dT0vec(:),dtmat_(:,:),dselvec(:),dmmat_(:,:),dgzi_hat_vec(:),dganma_hat_vec(:),&
	dganmavec_(:),dnmat_(:,:),dgzivec_(:),dsjkvec(:),dlamdavec_(:),Svec(:),Ft(:),yL(:),tvec__(:),&
	ye(:),yj(:),yk(:),c_nod_coord(:,:)
	

	real(real64) ,intent(inout)::nts_amo(:,:),k_contact(:,:),fvec_contact(:)
	real(real64), intent(in) :: old_nod_coord(:,:),uvec(:),contact_mat_para(:,:),duvec(:)
    integer, intent(in) :: j, nod_max,nts_elem_nod(:,:),active_nts(:),nts_mat(:)
	integer, intent(inout) :: stick_slip(:)
    real(real64) c,phy,en,ct,gns,gz,l,pn,tts,gt,gz0,alpha,omega,gns_,gz_,sjk,delta
	real(real64) gzi_hat,delta_hat,ganma_,kappa,S0,ganma,gzi_,ganma_hat,lamda_,T0,dfdtn,HH,sel
	integer i, ii , k,beta,i_1,ii_1,node_ID
	 
	 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 allocate(x2s(2),x11(2),x12(2),evec(3),avec(3),nvec(3),k_st(8,8),&
	 ns(8),n0s(8),ts(8),t0s(8),ngz0(8),ts_st(8),fvec_e(8),tvec(2),mvec(2) )
	 allocate( nvec_(3),tvec_(3),x1(2),x2(2),x3(2),x4(2),x5(2),x6(2),yi(2) )
	 allocate(ym(2),ys(2),nvec__(2),ovec(2),mvec_(2),mvec__(2),Dns(8,8),Dns_1_1(8) )
	 allocate(Dns_1(8),domega_mat(8),Ivec(2) )
	allocate(dtmat(2,8),dmmat(2,8),dnmat__(2,8),dgzivec(8),dalpha(8),dHvec(8) )
	allocate(nod_coord(size(old_nod_coord,1),size(old_nod_coord,2)))
	allocate(nt(8),Dnt(8,8),dT0vec(8),dtmat_(2,8),dselvec(8),dmmat_(2,8),dgzi_hat_vec(8)  )
	allocate( dganma_hat_vec(8),dganmavec_(8),dnmat_(2,8),dgzivec_(8),dsjkvec(8),dlamdavec_(8)  )
	allocate(Svec(8),Ft(8),yL(2),tvec__(1:2) )
	allocate(ye(2),yj(2),yk(2),c_nod_coord(size(nod_coord,1),size(nod_coord,2)  ) )
	do i=1, size(nod_coord,1)
		nod_coord(i,1)=old_nod_coord(i,1)
		nod_coord(i,2)=old_nod_coord(i,2)
	enddo
	do i=1,size(nod_coord,1)
		c_nod_coord(i,1)=nod_coord(i,1)+uvec(2*i-1)
		c_nod_coord(i,2)=nod_coord(i,2)+uvec(2*i  )
	 enddo 
	 !-----材料パラメータの読み込み------
	 en=contact_mat_para(nts_mat( active_nts(j) ),2 )
	 ct=contact_mat_para(nts_mat( active_nts(j) ),1 )
	 c = contact_mat_para(nts_mat( active_nts(j) ),3 )
	 phy=contact_mat_para(nts_mat( active_nts(j) ),4 )
	 !--------------------------------
	  delta=1.0e-5
	 tts=nts_amo(active_nts(j),12) 
	 !dfdtn=nts_amo(active_nts(j),10) 
	 if(tts>=0.0d0)then
		dfdtn=1.0d0
	  elseif(tts<0.0d0)then
		dfdtn=-1.0d0
	 else
		 stop "invalid tTs"
	  endif
	 
	 
	 !以下、初期座標＋変位により、位置ベクトルを更新し、諸量を更新
	 !gz更新
	 x1(1:2) = uvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		duvec(2*nts_elem_nod(active_nts(j),1)-1:&
	    2*nts_elem_nod(active_nts(j),1))+&
		nod_coord(nts_elem_nod(active_nts(j),1),1:2)
	 x2(1:2) = uvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		duvec(2*nts_elem_nod(active_nts(j),2)-1:&
	    2*nts_elem_nod(active_nts(j),2))+&
		nod_coord(nts_elem_nod(active_nts(j),2),1:2)
	 x3(1:2) = uvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		duvec(2*nts_elem_nod(active_nts(j),3)-1:&
	    2*nts_elem_nod(active_nts(j),3))+&
		nod_coord(nts_elem_nod(active_nts(j),3),1:2)	 
	 x4(1:2) = uvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		duvec(2*nts_elem_nod(active_nts(j),4)-1:&
	    2*nts_elem_nod(active_nts(j),4))+&
		nod_coord(nts_elem_nod(active_nts(j),4),1:2)
	x5(1:2) = uvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		duvec(2*nts_elem_nod(active_nts(j),5)-1:&
	    2*nts_elem_nod(active_nts(j),5))+&
		nod_coord(nts_elem_nod(active_nts(j),5),1:2)
	x6(1:2) = uvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		duvec(2*nts_elem_nod(active_nts(j),6)-1:&
	    2*nts_elem_nod(active_nts(j),6))+&
		nod_coord(nts_elem_nod(active_nts(j),6),1:2)
	 node_ID=active_nts(j)
	 
	 
	call get_beta_st_nts(node_ID,nts_elem_nod,c_nod_coord,beta)
	if(beta==1)then
		x2s(1:2) = x1(:)
		x11(1:2) = x2(:)
		x12(1:2) = x3(:)
		yi(1:2) = x4(:)
		yj(1:2) = x2(1:2)
		yk(1:2) = x3(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x3(1:2)
		
		
		
	else
		x2s(1:2) = x1(:)
		x11(1:2) = x4(:)
		x12(1:2) = x2(:)
		yi(1:2) = x3(:)
		yj(1:2) = x4(1:2)
		yk(1:2) = x2(1:2)
		ys(1:2) = x1(1:2)
		ym(1:2) = x2(1:2)
		ye(1:2) = x4(1:2)
		
	endif
		 ! 0 duvecの格納,ξ,ｇN等諸量の格納
	 !-----------------------------------------------------------------------
	!-----------------------------------------------------------------------

	 nvec(3) = 0.0d0
	 
	 avec(3) = 0.0d0
	 
	 evec(1) = 0.0d0
	 evec(2) = 0.0d0
	 evec(3) = 1.0d0
	 
	 Ivec(1) = 1.0d0
	 Ivec(2) = 1.0d0
	 
	 nvec_(3) = 0.0d0
	 tvec_(3) = 0.0d0
	!----------------------------------
	 l = dot_product( yj(1:2)-yk(1:2), yj(1:2)-yk(1:2)) 
	 l=dsqrt(l)
	sjk=l
	 if(l==0.0d0)then
		print *, "l=0 at element No.",node_ID
		 stop 
	 endif
	
	avec(1:2) = ( yk(1:2)-yj(1:2)  )/l

	 nvec(:) = cross_product(evec,avec)
	 gz=1.0d0/l*dot_product(ys(1:2)-yj(1:2),avec(1:2) )
	 gns = dot_product((ys(:)-ym(:)),nvec(1:2))
	 
	 

	 !alpha=4.0d0*gz*(1.0d0-gz)
	 !alpha=0.50d0*(1.0d0-cos(2.0d0*3.1415926535d0*gz) )
	 !alpha=exp( -delta*delta*(2.0d0*gz-1.0d0)**2.0d0 )
	 alpha=1.0d0
	 !alpha=0.0d0
	 yL(:)=yi(:)+alpha*(ym(:)-yi(:))
	 sel=dsqrt(dot_product(ye-yL,ye-yL))
	 gz0=gz-tts/ct/sel

	 if(sel==0.0d0)then
			 stop  "error check_gn"
	endif
	tvec_(1:2)=(ye(:)-yL(:) )/sel
	nvec_(:)=cross_product(evec,tvec_)
	tvec(1:2)=avec(1:2)
	mvec(:)=gz*tvec(:)-gns/sjk*nvec(:)
	nvec__(1:2)=nvec_(1:2)*dble(beta) 
	 
	 !gnsの計算と更新-----------------------------------------------------
	 gns_ = dot_product((ys(:)-ym(:)),nvec__(1:2))	 
	 gz_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2) )
	 
	 !get f_contact(normal),K_contact(normal)
	 !compute common variables
	 gzi_=1.0d0/sel*dot_product(ys-ym,tvec_(1:2)  )
	 ganma_hat=1.0d0/sel*dot_product(ym-yi,nvec_(1:2) )
	 !HH=4.0d0*(1.0d0-2.0d0*gz)
	 !HH=-3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 HH=alpha*(delta*delta)*(4.0d0-8.0d0*gz)
	 HH=0.0d0
	 
	 omega=1.0d0/sjk*HH*gz_*dot_product(ym-yi,nvec__(1:2) )
	 
	 gzi_hat=1.0d0/sel*dot_product(ym-yi,tvec_(1:2) )
	 delta_hat=dot_product(ym-yi,nvec_(1:2) )
	 ganma_=1.0d0/sel*dot_product(ys-ym,nvec_(1:2) )
	
	 ganma=gns/sjk
	 ovec(1:2)=gz*nvec(1:2)+ganma*tvec(1:2)
	 mvec_(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 mvec__(1:2)=gzi_*tvec_(1:2)-ganma_*nvec_(1:2)
	 !kappa=-8.0d0
	 !kappa=-2.0d0*3.1415926535d0*3.1415926535d0*cos(2.0d0*3.1415926535d0*gz)
	 kappa=alpha*(delta)*(delta)*(delta)*(delta)*(4.0d0-8.0d0*gz) - 8.0d0*alpha*(delta*delta)
	 kappa=0.0d0
	 !kappa=8.0d0
	 tvec__(1:2)=dble(beta)*tvec_(1:2)
	 S0=delta_hat*dble(beta)/sjk*( kappa*gzi_+HH*HH*(2.0d0*gzi_*gzi_hat-ganma_*ganma_hat)  )
	 
	 if(beta==1)then
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(5:6)=omega*(-mvec(1:2)  )
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=mvec(1:2)-tvec(1:2)
		Dns_1_1(5:6)=-mvec(:)
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(5:6)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,5:6)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk!!+-
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(5:6)=-1.0d0/sjk*mvec(1:2)
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(5:6)=-HH/sjk*mvec(1:2)
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(5:6)=-kappa/sjk*mvec(1:2)
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(5:6)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,5:6)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+(-alpha)*tvec_(1:2) !!+-
		dselvec(5:6)=dselvec(5:6)+tvec_(1:2)
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(5:6)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(5:6)=T0*(-mvec(1:2) )
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(5:6,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8)
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))
		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration
		do i = 1,4
			do ii = 1, 4
			
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i-1,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i)-1,2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i-1,2*ii)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)-1) &
			+k_st(2*i,2*ii-1)
			k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			=k_contact(2*nts_elem_nod(active_nts(j),i),2*nts_elem_nod(active_nts(j),ii)) &
			+k_st(2*i,2*ii)
		
			enddo
		enddo
		
		do i=1,4
			fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i)-1 )+fvec_e(2*i-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i))+fvec_e(2*i)	
		enddo
	

	

		
	 elseif(beta==-1)then
		!normal part >>>
		!normal part >>>
		ns(1:2)=omega*(tvec(1:2)  )
		ns(3:4)=omega*(-mvec(1:2)  )
		ns(5:6)=omega*(mvec(1:2)-tvec(1:2))!!+-
		ns(7:8)=0.0d0
	 
		ns(1:2)=ns(1:2)+nvec__(1:2)
		ns(3:4)=ns(3:4)-(1.0d0-alpha*gz_)*nvec__(1:2) 
		ns(5:6)=ns(5:6)-gz_*nvec__(1:2)
		ns(7:8)=ns(7:8)+(1.0d0- alpha)*gz_*nvec__(1:2)
		
		Dns_1_1(1:2)=tvec(1:2)
		Dns_1_1(3:4)=-mvec(:)
		Dns_1_1(5:6)=mvec(1:2)-tvec(1:2)!!+-
		Dns_1_1(7:8)=0.0d0
		
		domega_mat(1:2)=1.0d0/sjk*S0*tvec(:)
		domega_mat(3:4)=1.0d0/sjk*(-S0*mvec(1:2)-omega*tvec(1:2))
		domega_mat(5:6)=1.0d0/sjk*(S0*(mvec(1:2)-tvec(1:2))+omega*tvec(1:2))!!+-
		domega_mat(7:8)=0.0d0
		
		domega_mat(1:2)=domega_mat(1:2)+HH/sjk*ganma_hat*tvec__(1:2)
		domega_mat(3:4)=domega_mat(3:4)+HH/sjk*( ganma_hat*(alpha*mvec__(1:2)-tvec__(1:2) )+gzi_*(1.0d0+alpha*gzi_hat)*nvec__(1:2))
		domega_mat(5:6)=domega_mat(5:6)+HH/sjk*(-ganma_hat*mvec__(1:2)-gzi_*ganma_hat*nvec__(1:2) ) 
		domega_mat(7:8)=domega_mat(7:8)+HH/sjk*(gzi_*(-1.0d0+(1.0d0-alpha )*gzi_hat)*nvec__(1:2)+ganma_hat*(1.0d0-alpha)*mvec__(1:2)  )
		
		dtmat(1:2,1:2)=0.0d0
		dtmat(1:2,3:4)=diadic(nvec(1:2),nvec(1:2) )/sjk
		dtmat(1:2,5:6)=-diadic(nvec(1:2),nvec(1:2) )/sjk!!+-
		dtmat(1:2,7:8)=0.0d0
		
		dmmat(1:2,1:2)=(diadic(tvec(1:2),tvec(1:2))-diadic(nvec(1:2),nvec(1:2) ))/sjk
		dmmat(1:2,3:4)=(-diadic(tvec(1:2),mvec(1:2) )&
			+diadic(nvec(1:2),ovec(1:2))+diadic(ovec(1:2),nvec(1:2) ) )/sjk
		dmmat(1:2,5:6)=(-diadic(tvec(1:2),tvec(1:2))+diadic(nvec(1:2),nvec(1:2) )+diadic(tvec(1:2),mvec(1:2) )&
			-diadic(nvec(1:2),ovec(1:2))-diadic(ovec(1:2),nvec(1:2) ) )/sjk!!+-
		dmmat(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec__(1:2),tvec(1:2) )
		dnmat__(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2))
		dnmat__(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec__(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat__(1:2,7:8)=0.0d0
		
		dnmat__(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat__(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec__(1:2),nvec_(1:2) ) 
		dnmat__(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec__(1:2),nvec_(1:2) )
		dnmat__(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec__(1:2),nvec_(1:2) )
		 
		dgzivec(1:2)=1.0d0/sjk*tvec(1:2)
		dgzivec(3:4)=-1.0d0/sjk*mvec(1:2)
		dgzivec(5:6)=1.0d0/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dgzivec(7:8)=0.0d0
		
		dalpha(1:2)=HH/sjk*tvec(1:2)
		dalpha(3:4)=-HH/sjk*mvec(1:2)
		dalpha(5:6)=HH/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dalpha(7:8)=0.0d0
		
		dHvec(1:2)=kappa/sjk*tvec(1:2)
		dHvec(3:4)=-kappa/sjk*mvec(1:2)
		dHvec(5:6)=kappa/sjk*( mvec(1:2)-tvec(1:2) )!!+-
		dHvec(7:8)=0.0d0
		
		dgzivec_(1:2)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*tvec(1:2)
		dgzivec_(3:4)=-HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*mvec(1:2)
		dgzivec_(5:6)=HH*(gzi_*gzi_hat-ganma_*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2) )!!+-
		dgzivec_(7:8)=0.0d0
		
		dgzivec_(1:2)=dgzivec_(1:2)+1.0d0/sel*tvec_(1:2)
		dgzivec_(3:4)=dgzivec_(3:4)+1.0d0/sel*(alpha*mvec_(1:2)-tvec_(1:2)) 
		dgzivec_(5:6)=dgzivec_(5:6)+1.0d0/sel*(-1.0d0)*mvec_(1:2)
		dgzivec_(7:8)=dgzivec_(7:8)+1.0d0/sel*(1.0d0-alpha)*mvec_(1:2)
		
		Dns(1:8,1:8)=diadic(Dns_1_1,domega_mat)
		
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+omega*dtmat(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+omega*(-dmmat(1:2,1:8) )
		Dns(5:6,1:8)=Dns(5:6,1:8)+omega*( dmmat(1:2,1:8)-dtmat(1:2,1:8) )!!+-
		Dns(7:8,1:8)=Dns(7:8,1:8)+0.0d0
		
		Dns(1:2,1:8)=Dns(1:2,1:8)+dnmat__(1:2,1:8)
		Dns(3:4,1:8)=Dns(3:4,1:8)+diadic(nvec__(1:2),alpha*dgzivec_(1:8)+gzi_*dalpha(1:8) )-(1.0d0-alpha*gzi_)*dnmat__(1:2,1:8) 
		Dns(5:6,1:8)=Dns(5:6,1:8)-diadic(nvec__(1:2),dgzivec_(1:8) )-gzi_*dnmat__(1:2,1:8)
		Dns(7:8,1:8)=Dns(7:8,1:8)+diadic(nvec__(1:2),(1.0d0-alpha)*dgzivec_(1:8)-gzi_*dalpha(1:8) )+(1.0d0-alpha)*gzi_*dnmat__(1:2,1:8)
		
		
		fvec_e(1:8)= en*gns_*ns(1:8)
		K_st(1:8,1:8)=en*(diadic(ns,ns)+gns_*Dns(1:8,1:8) )
		! note >> du(1),du(2),du(3),du(4)
		
		!tangential part>>>
		
	
		dnmat_(1:2,1:2)=HH*ganma_hat/sjk*diadic(tvec_(1:2),tvec(1:2) )
		dnmat_(1:2,3:4)=-HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2))
		dnmat_(1:2,5:6)=HH*ganma_hat/sjk*diadic(tvec_(1:2),mvec(1:2)-tvec(1:2) )!!+-
		dnmat_(1:2,7:8)=0.0d0
		
		dnmat_(1:2,1:2)=dnmat__(1:2,1:2)+0.0d0
		dnmat_(1:2,3:4)=dnmat__(1:2,3:4)+1.0d0/sel*alpha*diadic(tvec_(1:2),nvec_(1:2) ) 
		dnmat_(1:2,5:6)=dnmat__(1:2,5:6)-1.0d0/sel*diadic(tvec_(1:2),nvec_(1:2) )
		dnmat_(1:2,7:8)=dnmat__(1:2,7:8)+1.0d0/sel*(1.0d0-alpha)*diadic(tvec_(1:2),nvec_(1:2) )
		 
		
		dganmavec_(1:2)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(tvec(1:2))
		dganmavec_(3:4)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(-mvec(1:2))
		dganmavec_(5:6)=HH*(gzi_*ganma_hat+gzi_hat*ganma_)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganmavec_(7:8)=0.0d0
		
		dganmavec_(1:2)=dganmavec_(1:2)+1.0d0/sel*(nvec_(1:2))
		dganmavec_(3:4)=dganmavec_(3:4)+1.0d0/sel*(alpha*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2))-nvec_(1:2) ) 
		dganmavec_(5:6)=dganmavec_(5:6)+1.0d0/sel*(-(gzi_*nvec_(1:2)+ganma_*tvec_(1:2) ))
		dganmavec_(7:8)=dganmavec_(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_*nvec_(1:2)+ganma_*tvec_(1:2)))
		
		dganma_hat_vec(1:2)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(tvec(1:2))
		dganma_hat_vec(3:4)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(-mvec(1:2))
		dganma_hat_vec(5:6)=2.0d0*HH*gzi_hat*ganma_hat/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dganma_hat_vec(7:8)=0.0d0
		
		
		dganma_hat_vec(1:2)=dganma_hat_vec(1:2)+0.0d0
		dganma_hat_vec(3:4)=dganma_hat_vec(3:4)+1.0d0/sel*(alpha*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))+nvec_(1:2) ) 
		dganma_hat_vec(5:6)=dganma_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2) ))
		dganma_hat_vec(7:8)=dganma_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*nvec_(1:2)+ganma_hat*tvec_(1:2))-nvec_(1:2) )
		
		dgzi_hat_vec(1:2)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(tvec(1:2))
		dgzi_hat_vec(3:4)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(-mvec(1:2))
		dgzi_hat_vec(5:6)=HH*(gzi_hat*gzi_hat-ganma_hat*ganma_hat)/sjk*(mvec(1:2)-tvec(1:2))!!+-
		dgzi_hat_vec(7:8)=0.0d0
		
		dgzi_hat_vec(1:2)=dgzi_hat_vec(1:2)+0.0d0
		dgzi_hat_vec(3:4)=dgzi_hat_vec(3:4)+1.0d0/sel*((gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))*alpha+tvec_(1:2) )
		dgzi_hat_vec(5:6)=dgzi_hat_vec(5:6)+1.0d0/sel*(-(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2)) ) 
		dgzi_hat_vec(7:8)=dgzi_hat_vec(7:8)+1.0d0/sel*((1.0d0-alpha)*(gzi_hat*tvec_(1:2)-ganma_hat*nvec_(1:2))-tvec_(1:2) )
		
		
		
		
		dtmat_(1:2,1:2)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),tvec(1:2) ) )
		dtmat_(1:2,3:4)=HH*ganma_hat/sjk*(1.0d0)*(diadic( nvec_(1:2),mvec(1:2) ) )
		dtmat_(1:2,5:6)=HH*ganma_hat/sjk*(-1.0d0)*(diadic( nvec_(1:2),mvec(1:2)-tvec(1:2) ) )!!+-
		dtmat_(1:2,7:8)=0.0d0
	
		dtmat_(1:2,1:2)=dtmat_(1:2,1:2)+0.0d0
		dtmat_(1:2,3:4)=dtmat_(1:2,3:4)+1.0d0/sel*(-1.0d0)*alpha*diadic( nvec_(1:2), nvec_(1:2) ) 
		dtmat_(1:2,5:6)=dtmat_(1:2,5:6)+1.0d0/sel*(1.0d0)*diadic( nvec_(1:2), nvec_(1:2) )
		dtmat_(1:2,7:8)=dtmat_(1:2,7:8)+1.0d0/sel*(-1.0d0+alpha)*diadic( nvec_(1:2), nvec_(1:2) )
		
		
		
		
		dmmat_(1:2,1:8)=diadic(tvec_(1:2),dgzivec_(1:8) )
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+gzi_*dtmat_(1:2,1:8)
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+diadic( nvec_(1:2), dganmavec_(1:8))
		
		dmmat_(1:2,1:8)=dmmat_(1:2,1:8)+ganma_*dnmat_(1:2,1:8)
		
		dselvec(1:2)=sel*HH*gzi_hat/sjk*(-1.0d0)*tvec(1:2)
		dselvec(3:4)=sel*HH*gzi_hat/sjk*(-1.0d0)*(mvec(1:2)-tvec(1:2))
		dselvec(5:6)=sel*HH*gzi_hat/sjk*mvec(1:2)
		dselvec(7:8)=0.0d0
		
		dselvec(1:2)=dselvec(1:2)+0.0d0
		dselvec(3:4)=dselvec(3:4)+tvec_(1:2)
		dselvec(5:6)=dselvec(5:6)+(-alpha)*tvec_(1:2) !!+-
		dselvec(7:8)=dselvec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		dlamdavec_(1:8)=gzi_*dgzi_hat_vec(1:8)+gzi_hat*dgzivec_(1:8)&
			-ganma_hat*dganmavec_(1:8)-ganma_*dganma_hat_vec(1:8)
		
		!original part
		dsjkvec(1:2)=dble(beta)*0.0d0
		dsjkvec(3:4)=dble(beta)*(-1.0d0)*tvec(1:2)
		dsjkvec(5:6)=dble(beta)*tvec(1:2)
		dsjkvec(7:8)=dble(beta)*0.0d0
		
		lamda_=gzi_*gzi_hat-ganma_*ganma_hat
		T0=1.0d0/sjk*HH*lamda_
		
		dT0vec(1:8)=-HH*lamda_/sjk/sjk*dsjkvec(1:8)+HH/sjk*dlamdavec_(1:8)+lamda_/sjk*dHvec(1:8)
		
		Svec(1:2)=-sel*HH*gzi_hat/sjk*tvec(1:2)
		Svec(3:4)=-sel*HH*gzi_hat/sjk*(-mvec(1:2))
		Svec(5:6)=-sel*HH*gzi_hat/sjk*mvec(1:2)-tvec(1:2)!!+-
		Svec(7:8)=0.0d0
		
		Svec(1:2)=Svec(1:2)+0.0d0
		Svec(3:4)=Svec(3:4)+(-alpha)*tvec_(1:2)  
		Svec(5:6)=Svec(5:6)+tvec_(1:2)
		Svec(7:8)=Svec(7:8)-(1.0d0-alpha)*tvec_(1:2)
		
		nt(1:2)=T0*tvec(1:2)
		nt(3:4)=T0*(-mvec(1:2) )
		nt(5:6)=T0*( mvec(1:2)-tvec(1:2)     )!!+-
		nt(7:8)=0.0d0		
			
		nt(1:2)=nt(1:2)+1.0d0/sel*tvec_(1:2)
		nt(3:4)=nt(3:4)+1.0d0/sel*( alpha*mvec_(1:2)-tvec_(1:2)  ) 
		nt(5:6)=nt(5:6)+1.0d0/sel*(-mvec_(1:2))
		nt(7:8)=nt(7:8)+1.0d0/sel*(1.0d0-alpha )*mvec_(1:2)		

		
		Dnt(1:2,1:8)=diadic(tvec(1:2),dT0vec(1:8) )+T0*dtmat(1:2,1:8)
		Dnt(3:4,1:8)=-diadic(mvec(1:2),dT0vec(1:8) )-T0*dmmat(1:2,1:8)
		Dnt(5:6,1:8)=diadic(mvec(1:2)-tvec(1:2),dT0vec(1:8) )+T0*(dmmat(1:2,1:8)  -dtmat(1:2,1:8))!!+-
		Dnt(7:8,1:8)=0.0d0
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)-1.0d0/sel/sel*diadic(tvec_(1:2),dselvec(1:8) )
		Dnt(3:4,1:8)=Dnt(3:4,1:8)-1.0d0/sel/sel*diadic( alpha*mvec_(1:2)- tvec_(1:2),dselvec(1:8) ) !inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)-1.0d0/sel/sel*diadic(-mvec_(1:2),dselvec(1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)-1.0d0/sel/sel*diadic( (1.0d0-alpha)*mvec_(1:2),dselvec(1:8) )
		
		Dnt(1:2,1:8)=Dnt(1:2,1:8)+1.0d0/sel*dtmat_(1:2,1:8)
		Dnt(3:4,1:8)=Dnt(3:4,1:8)+1.0d0/sel*(diadic(mvec_(1:2),dalpha(1:8) )+alpha*dmmat_(1:2,1:8)-dtmat_(1:2,1:8))!inverse original
		Dnt(5:6,1:8)=Dnt(5:6,1:8)+1.0d0/sel*(-dmmat_(1:2,1:8) )
		Dnt(7:8,1:8)=Dnt(7:8,1:8)+1.0d0/sel*(-diadic(mvec_(1:2),dalpha(1:8) )+(1.0d0-alpha)*dmmat_(1:2,1:8))
		
		
		if(stick_slip( active_nts(j)  )==0  )then
			Ft(1:8)=dble(beta)*ct*sel*nt(1:8)
		elseif(stick_slip( active_nts(j)  )==1  )then
			Ft(1:8)=en*tan(phy)*ns(1:8)
		else
			 stop  "invalid stick_slip on contact.f95"
		endif
		fvec_e(1:8)= fvec_e(1:8)+dble(beta)*tts*sel*nt(1:8)
		K_st(1:8,1:8)=K_st(1:8,1:8)+dble(beta)*transpose( sel*diadic(Ft(1:8),nt(1:8))+tts*diadic(Svec(1:8),nt(1:8))+tts*sel*Dnt(1:8,1:8))

		fvec_e(:)=fvec_e(:)*l !integration
		K_st(:,:)=K_st(:,:)*l !integration	
		do i = 1,4
			do ii = 1, 4
				if(i==3)then
					i_1=4
				elseif(i==4)then
					i_1=3
				else
					i_1=i
				endif
				
				if(ii==3)then
					ii_1=4
				elseif(ii==4)then
					ii_1=3
				else
					ii_1=ii
				endif
				
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1-1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1)-1,2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1-1,2*ii_1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)-1) &
				+k_st(2*i_1,2*ii_1-1)
				k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				=k_contact(2*nts_elem_nod(active_nts(j),i_1),2*nts_elem_nod(active_nts(j),ii_1)) &
				+k_st(2*i_1,2*ii_1)
			
			enddo
		enddo
		
		do i=1,4
			if(i==3)then
				i_1=4
			elseif(i==4)then
				i_1=3
			else
				i_1=i
			endif
			
			
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 ) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1)-1 )+fvec_e(2*i_1-1)
			fvec_contact(2*nts_elem_nod(active_nts(j),i_1)) &
				=fvec_contact(2*nts_elem_nod(active_nts(j),i_1))+fvec_e(2*i_1)	
		enddo		
			
			
		else
		
			 stop  "error :: invalid beta"
		endif


	
	 !諸量の更新
	 !nts_amo(active_nts(j),1)     =gz !trial gzi0 on current timestep
	 !nts_amo(active_nts(j),10)    =gz !converged gzi at last timestep
	 !nts_amo(active_nts(j),11)    =pn !inactive

 end subroutine update_res_grad_c

!==============================================================
! 変位を与えた節点でRvec=0.0d0とする
!-----------------------------------

 subroutine disp_rvec(u_nod_x,u_nod_y,rvec)
       integer, intent(in) :: u_nod_x(:),u_nod_y(:)
	   real(real64), intent(inout) :: rvec(:)
	   integer i
	   
	   !x方向変位を設定した残差ベクトル成分を0.0d0
	    do i=1,size(u_nod_x,1)    
			rvec(2*u_nod_x(i)-1)=0.0d0
        enddo
		
		!y方向変位を設定した残差ベクトル成分を0.0d0
	    do i=1,size(u_nod_y,1)    
			rvec(2*u_nod_y(i))=0.0d0
        enddo

 end subroutine disp_rvec
!===============================================================
 subroutine get_beta_st_nts(nts_ID,nts_elem_nod,nod_coord,beta)
	integer,intent(in)::nts_ID,nts_elem_nod(:,:)
	integer,intent(out)::beta
	integer i,j,n
	real(real64),intent(in)::nod_coord(:,:)
	real(real64),allocatable::tvec_0(:),x1(:),x2(:),x3(:),a(:)
	real(real64) direction

	n=size(nod_coord,2)
	
	allocate(tvec_0(n),x1(n),x2(n),x3(n),a(n) )
	
	
	
	x1(:)=nod_coord(nts_elem_nod(nts_ID,2),:)
	x2(:)=nod_coord(nts_elem_nod(nts_ID,3),:)
	x3(:)=nod_coord(nts_elem_nod(nts_ID,4),:)
	a(:)=nod_coord(nts_elem_nod(nts_ID,1),:)-x1(:)
	
	tvec_0(:)=x2(:)-x3(:)
	tvec_0(:)=tvec_0(:)/dsqrt(dot_product(tvec_0,tvec_0))
	
	direction=dot_product(a,tvec_0)
	
	if(direction<=0.0d0)then
		beta=-1
	elseif(direction>0.0d0)then
		beta=1
	else
		!print *, dsqrt(dot_product(tvec_0,tvec_0)),a(1:2),size(a)
		 stop  "ERROR on get_beta_st_nts, contact.mod"
	endif
	
 end subroutine get_beta_st_nts
!===============================================================

subroutine nts_generat(con_max,elem_nod,nts_elem_nod,old_nod_coord,surface_nod,sur_nod_inf,uvec,step)
! 配列の宣言
  
  integer,intent(in)::elem_nod(:,:),surface_nod(:),sur_nod_inf(:,:),con_max,step
  integer,allocatable,intent(out)::nts_elem_nod(:,:)
  integer,allocatable:: mast_slav(:,:),mast_slav_es(:,:),&
  nts_elem_nod_es(:,:),master_nod(:),master_nod_es(:),slave_nod(:),&
  slave_nod_es(:)
  
  real(real64),intent(in)::old_nod_coord(:,:),uvec(:)
  real(real64), allocatable ::con_d_coord(:,:),grobal_grid(:,:),grobal_grid_es(:,:),nod_coord(:,:),zerovec(:)
  
  integer grobal_grid_max,m,s,m_nod,s_nod,&	
  sla_nod_max,i,j,k,l,o,p,q,nei_nod,nei_nod_1,nei_nod_2,&	
  nn,nts_elem_max,x2,x11,x12
  
  real(real64) gn,gn_tr,tol,tol_rm,ll,lx,ly,x,y,z,norm_rvec,norm_uvec,start,fin_time,nts_time,gzi
  
  
  allocate(nod_coord(size(old_nod_coord,1),size(old_nod_coord,2)),&
	zerovec(size(uvec)))

  do i=1, size(nod_coord,1)
	nod_coord(i,1)=old_nod_coord(i,1)+uvec(2*i-1)
	nod_coord(i,2)=old_nod_coord(i,2)+uvec(2*i  )
  enddo
  zerovec(:)=0.0d0

!===============================
!contact search
!=========================================================================================
!Grobal search
!----------------
  
  allocate(con_d_coord(con_max,4))
  ! 連続体ごと外接する長方形のx-min,x-max,y-min,y-maxの座標
  con_d_coord(1:con_max,1:4) = 0
  
      do i = 1, con_max   ! 連続体ループ
	   
	       do j = sur_nod_inf(i,1), sur_nod_inf(i,2) !該当連続体の開始節点～最終節点
	       !各連続体ごとに、最初の節点の値を初期のx-min,x-max,y-min,y-maxの座標とする。
  	         if(j == sur_nod_inf(i,1)) then
		          con_d_coord(i,1) = nod_coord( surface_nod(j),1)
			      con_d_coord(i,2) = nod_coord( surface_nod(j),1)
			      con_d_coord(i,3) = nod_coord( surface_nod(j),2)
			      con_d_coord(i,4) = nod_coord( surface_nod(j),2)
		      endif      
	
	
	          !連続体ごとに、接点の読み込み、最小/最大の更新
	          if(con_d_coord(i,1) > nod_coord( surface_nod(j) ,1)) then
		          con_d_coord(i,1) = nod_coord( surface_nod(j) ,1)
		      endif
		   
		      if(con_d_coord(i,2) < nod_coord( surface_nod(j) ,1)) then
		       con_d_coord(i,2) = nod_coord( surface_nod(j) ,1)
		      endif
		   
		      if(con_d_coord(i,3) > nod_coord( surface_nod(j) ,2)) then
		          con_d_coord(i,3) = nod_coord( surface_nod(j) ,2)
		      endif
		   
		      if(con_d_coord(i,4) < nod_coord( surface_nod(j) ,2)) then
		          con_d_coord(i,4) = nod_coord( surface_nod(j) ,2)
		      endif
		   
		   
	       enddo
      enddo

! この時点で、連続体ごとに外接長方形の領域が確定
!check

  grobal_grid_max = 0

  allocate(mast_slav(1,2))
   
   
  ! grobal search のループ
    do i = 1, con_max
     
	     do j = 1, con_max
	    
		    if (i >= j) then
			   cycle
		    endif
		      ! 矩形接触判定
			  
			   if (con_d_coord(i,2) < con_d_coord(j,1)) then
			      cycle
			   elseif (con_d_coord(j,2) < con_d_coord(i,1)) then
				  cycle
			   elseif (con_d_coord(i,4) < con_d_coord(j,3)) then
				   cycle
			   elseif (con_d_coord(j,4) < con_d_coord(i,3)) then
                    cycle
               else	
                   !接触あり
		        	!退避用mast_slav_esの作成							
                 
					
					if(grobal_grid_max==0)then
						mast_slav(1,1)= i
						mast_slav(1,2)= j
	
						grobal_grid_max = grobal_grid_max + 1
					else
						allocate(mast_slav_es((size(mast_slav,1)),2))
						do k = 1, grobal_grid_max
							do l = 1, 2
								mast_slav_es(k,l) = mast_slav(k,l)
							enddo
						enddo
						
						deallocate(mast_slav)
						allocate(mast_slav(grobal_grid_max+1,2))
						!データの再格納
						do k = 1, grobal_grid_max			
							do l = 1, 2		
								mast_slav(k,l) = mast_slav_es(k,l)	   
							enddo		   
						enddo			
						mast_slav(grobal_grid_max+1,1)= i
						mast_slav(grobal_grid_max+1,2)= j
							
						grobal_grid_max = grobal_grid_max + 1
						deallocate(mast_slav_es)
					endif
				endif
	        enddo
    enddo
 
	if(grobal_grid_max/=0)then
 
 
		!grobal_grid_maxのリセット
		grobal_grid_max=size(mast_slav,1)
		!接触ありのmaster-slaveに対して、接触領域の確定・保存
		allocate(grobal_grid(size(mast_slav,1),4))
		do i = 1, grobal_grid_max
			do j = 1,4  
				grobal_grid(i,j) = 0.0d0
			enddo
		enddo
		!以下、xに関して確定・保存
		do k = 1, grobal_grid_max
			i=mast_slav(k,1) 
			j=mast_slav(k,2) 
	   
			if(con_d_coord(i,1)+con_d_coord(i,2) <= &
				con_d_coord(j,1)+con_d_coord(j,2)) then
				
				! iのx方向辺の中心<=jのx方向辺の中心
				if(con_d_coord(i,2) >= con_d_coord(j,2)) then
					!(3)に決定
					grobal_grid(k,1) = con_d_coord(j,1) ! x-min			   
					grobal_grid(k,2) = con_d_coord(j,2) ! x-max
			   
				else
					if(con_d_coord(i,1) >= con_d_coord(j,1)) then
					!(2)に決定
					grobal_grid(k,1) = con_d_coord(i,1) ! x-min	
					grobal_grid(k,2) = con_d_coord(i,2) ! x-max
				  
					else
					!(1)に決定
					grobal_grid(k,1) = con_d_coord(j,1) ! x-min	
					grobal_grid(k,2) = con_d_coord(i,2) ! x-max
					endif
				endif
			else			 
				! iのx方向辺の中心>jのx方向辺の中心
				if(con_d_coord(j,2) >= con_d_coord(i,2)) then
					!(3)に決定
					grobal_grid(k,1) = con_d_coord(i,1) ! x-min			   
					grobal_grid(k,2) = con_d_coord(i,2) ! x-max			   	   
				else
					if(con_d_coord(j,1) >= con_d_coord(i,1)) then
					!(2)に決定
					grobal_grid(k,1) = con_d_coord(j,1) ! x-min	
					grobal_grid(k,2) = con_d_coord(j,2) ! x-max	    
					else
					!(1)に決定
					grobal_grid(k,1) = con_d_coord(i,1) ! x-min	
					grobal_grid(k,2) = con_d_coord(j,2) ! x-max			  
					endif
				endif		  	  
			endif
		enddo

		!以下、yに関して確定・保存
		do k = 1, grobal_grid_max ! 接触組み合わせごとにループ
			i=mast_slav(k,1)
			j=mast_slav(k,2)  
	   
			if ((con_d_coord(i,3)+con_d_coord(i,4))/2 <= &
				(con_d_coord(j,3)+con_d_coord(j,4))/2)then
				! iのx方向辺の中心<=jのx方向辺の中心
				if(con_d_coord(i,4) >= con_d_coord(j,4)) then
				!(3)に決定
				grobal_grid(k,3) = con_d_coord(j,3) ! y-min			   
				grobal_grid(k,4) = con_d_coord(j,4) ! y-max
				else
					if(con_d_coord(i,3) >= con_d_coord(j,3))then
					!(2)に決定
					grobal_grid(k,3) = con_d_coord(i,3) ! y-min	
					grobal_grid(k,4) = con_d_coord(i,4) ! y-max
					else
					!(1)に決定
					grobal_grid(k,3) = con_d_coord(j,3) ! y-min	
					grobal_grid(k,4) = con_d_coord(i,4) ! y-max
					endif
				endif
			else			 
				! iのx方向辺の中心>jのx方向辺の中心
				if(con_d_coord(j,4) >= con_d_coord(i,4))then
					!(3)に決定
					grobal_grid(k,3) = con_d_coord(i,3) ! y-min			   
					grobal_grid(k,4) = con_d_coord(i,4) ! y-max			    
				else
					if(con_d_coord(j,3) >= con_d_coord(i,3))then
						!(2)に決定
						grobal_grid(k,3) = con_d_coord(j,3) ! y-min	
						grobal_grid(k,4) = con_d_coord(j,4) ! y-max   
					else
						!(1)に決定
						grobal_grid(k,3) = con_d_coord(i,3) ! x-min	
						grobal_grid(k,4) = con_d_coord(j,4) ! x-max			  
					endif
				endif		  
			endif
		enddo
		! この時点で、連続体組み合わせごとの重複領域（grobal search grid）が確定
		write(*,*) "Grobal search was succeed!"	 
	
	
	
		write(20,*) 'grobal grid, xmin xmax ymin ymax'
		do k = 1,size(grobal_grid,1) 
			write(20,*)grobal_grid(k,1),&
			grobal_grid(k,2),&
			grobal_grid(k,3),&
			grobal_grid(k,4)		 
		enddo

		!====================================================================================
		! Local search
		!----------------------	  

		do i=1, grobal_grid_max !重複矩形ごとループ
			m = 0  !master,slave各nodの数を記録する変数のリセット
			s = 0
			allocate(master_nod(1)) !master-slaveごとに接点番号記録用配列の用意
			allocate(slave_nod(1))
			master_nod(:)=0
			slave_nod(:)=0
		
			do k = 1, 2 !master矩形,slave矩形
				write(20,*) 'master,slave',k
		   
				do j = sur_nod_inf(mast_slav(i,k),1), sur_nod_inf &
					(mast_slav(i,k),2) !m,sごとに、表面節点を1つずつ、重複矩形に入っているか吟味 jは吟味中の表面接点用No.
				
					if(grobal_grid(i,1) <= nod_coord(surface_nod(j),1) .and. & 
						nod_coord(surface_nod(j),1) <= grobal_grid(i,2) ) then
					
						if(grobal_grid(i,3) <= nod_coord(surface_nod(j),2) &
							.and. nod_coord(surface_nod(j),2) <= grobal_grid(i,4)) then

							if (k == 1) then  
								m = m + 1    !master,slaveごとに接点数記録
								!接点数の記録		
								
								if (m == 1) then

									master_nod(m) = surface_nod(j)
									
								elseif(m>=2) then
									!m>=2である。
									!master_nod配列の拡張
									allocate(master_nod_es(m-1))
									

									
									do l = 1,size(master_nod)  !_esへの接点番号の避難
										master_nod_es(l) = master_nod(l)
									enddo

									deallocate(master_nod)
									allocate(master_nod(m))   !_esから接点番号の再格納
									do l = 1,size(master_nod_es)
										master_nod(l) = master_nod_es(l)
									enddo 
									master_nod(m) = surface_nod(j)
									deallocate(master_nod_es) !避難用配列の解体
				

								else
									 stop "ERROR Local Search m<1"
								endif

								
							 elseif(k ==2) then
								s = s + 1 !master,slaveごとに接点数記録
									!接点数の記録						  
								if (s == 1) then

									slave_nod(s) = surface_nod(j)
									write(20,*)surface_nod(j)
								elseif(s>=2)then
									!s>=2である。
									!slave_nod配列の拡張
									
									allocate(slave_nod_es(s-1))
						  
									do l = 1,size(slave_nod)  !_esへの接点番号の避難
										slave_nod_es(l) = slave_nod(l)
									enddo
					
									deallocate(slave_nod)
									allocate(slave_nod(s))   !_esから接点番号の再格納
									do l = 1,size(slave_nod_es)
										slave_nod(l) = slave_nod_es(l)
									enddo
									slave_nod(s) = surface_nod(j)
									deallocate(slave_nod_es) !避難用配列の解体
									

								else
									 stop "ERROR Local Search m<2"
								endif

							else
								 stop 'L388 masterでもslaveでもないk/=1,2'
							endif

						else
							cycle !次節点へ
						endif 
					else
						cycle ! 次節点へ
					endif
				enddo
				 
			enddo

			!-------重複矩形の表面節点の出力					  
			write(20,*)'grobal_grid No.=',i
			write(20,*)'master_nod'

			do l=1,size(master_nod)
				write(20,*) master_nod(l)
			enddo
		
			write(20,*)'slave_nod',size(slave_nod)			
			do l=1,size(slave_nod)
				write(20,*) slave_nod(l)
			enddo			
			!----------------------

			!重複矩形内接点数を計上終了
			if( slave_nod( size(slave_nod,1) )==0 .or. master_nod(  size(master_nod,1) ) == 0) then !重複矩形内に接点なし

				if(grobal_grid_max==i)then
					print *, "No contact !"
					allocate(nts_elem_nod(1,3) ) !no contact >> nts_elem_nod==0
					nts_elem_nod(:,:)=0
					exit
				else
					cycle !次重複矩形へ
				endif
			endif
			

			!================================================================ 
			! 以下、NTS-elementの生成
			!------------------------------------
			! (1) nts_element節点番号記憶配列の確保

			if (i >= 2) then  !NTSへの書き込みが2回目以上で、NTS節点番号記憶用配列の拡張を要する場合
				allocate(nts_elem_nod_es(size(nts_elem_nod,1) ,3))
				nts_elem_nod_es(:,:)=0
				nts_elem_max=size(nts_elem_nod,1) 
				do l = 1, size(nts_elem_nod,1)
					do k =1, 3
						nts_elem_nod_es(l,k) = nts_elem_nod(l,k)
					enddo
				enddo

				deallocate(nts_elem_nod)
				allocate(nts_elem_nod(size(nts_elem_nod_es,1)+size(slave_nod,1),3))
				nts_elem_nod(:,:)=0
				! size=これまでに記録されたntsの数+今回のslave_nodの数
				do l = 1, size(nts_elem_nod_es,1)
					do k =1, 3
						nts_elem_nod(l,k) = nts_elem_nod_es(l,k)
					enddo
				enddo
				deallocate(nts_elem_nod_es)
			elseif(i==1)then
				nts_elem_max =0
				allocate(nts_elem_nod( size(slave_nod) ,3))
				nts_elem_nod(:,:)=0
			else
				 stop  "wrong i on module ntselem"
			endif

			!nts_elem_nodを拡張済み
			!-------------------------------------------------------------------------------------------
			!initial value
			nei_nod=0
			nei_nod_1=0
			do l = 1, size(slave_nod) !slave nod ごとにNTS作成

				!do k = 1,size(master_nod)!重複矩形を構成するmaster_nodを1つずつ検証
				do k = sur_nod_inf(mast_slav(i,1),1), sur_nod_inf(mast_slav(i,1),2)
					!表面節点用No.
					!現在のslave_nodとの距離を計算

					lx=(nod_coord(slave_nod(l),1)-nod_coord(surface_nod(k),1))**2
					ly=(nod_coord(slave_nod(l),2)-nod_coord(surface_nod(k),2))**2

					gn_tr = (lx+ly)**(1.0d0/2.0d0)

					if(k==1) then !初期値
						gn=gn_tr
					endif
				  
					!汝は最近傍なりや?
					If(gn_tr <= gn) then
						gn = gn_tr 
						nei_nod=surface_nod(k) !近傍節点番号の更新X1@表面節点用No.
					elseif(gn_tr >gn) then
						cycle
					else
						 stop  'something is wrong at detecting x_11'
					endif

				enddo

				!最近傍節点=nei_nod---------------------

				
				nts_elem_nod(nts_elem_max+l,1) = slave_nod(l)
				nts_elem_nod(nts_elem_max+l,2) = nei_nod

			enddo
			!次重複矩形へ、パラメータクリア
			m = 0
			s = 0
			deallocate(master_nod)
			deallocate(slave_nod)
		
		enddo
	elseif(grobal_grid_max==0)then
		print *, "No contact !"
		allocate(nts_elem_nod(1,3) ) !no contact >> nts_elem_nod==0
		nts_elem_nod(:,:)=0
	else
		 stop "Wrong value in grobal_grid"
	endif
	
	deallocate(nod_coord,zerovec)

 end subroutine nts_generat

!=====================================================================
 subroutine nts_material(sur_inf_mat,nts_elem_nod,nts_mat,contact_mat,surface_nod,step)
	integer,intent(in)::sur_inf_mat(:,:),nts_elem_nod(:,:),contact_mat(:,:),surface_nod(:),step
	integer,allocatable,intent(out)::nts_mat(:)
	integer i,j,s,m,ss,mm,n
	
	n=size(nts_elem_nod,1)

	allocate(nts_mat(n) )

	do i=1,n !nts要素ごとに繰り返し
		if(nts_elem_nod(1,1)+nts_elem_nod(1,2)+nts_elem_nod(1,3)==0 )then
			nts_mat(:)=0 !0を入れておく

			exit
		endif
!		if(step==136) stop "2"
		!表面節点No.を検索し、slave=s,master=mへ格納
		do j=1, size(surface_nod,1)
			if(surface_nod(j)==nts_elem_nod(i,1) )then
				s=j

			elseif(surface_nod(j)==nts_elem_nod(i,2) )then
				m=j

			else
				cycle
			endif
		enddo


		!master nodの周面材料No.を検索
		
		do j=1,size(sur_inf_mat,1)
			if(sur_inf_mat(j,1)<=m .and. sur_inf_mat(j,2)>=m )then
				mm=sur_inf_mat(j,3)

				exit
			else
				cycle
			endif
		enddo
		

		!slave  nodの周面材料No.を検索
		do j=1,size(sur_inf_mat,1)
			if(sur_inf_mat(j,1)<=s .and. sur_inf_mat(j,2)>=s )then
				ss=sur_inf_mat(j,3)

				exit
			else
				cycle
			endif
		enddo
		nts_mat(i)=contact_mat(ss,mm)	
	enddo
	
 end subroutine nts_material
!=====================================================================
 subroutine save_nts_element(nts_elem_nod,nts_amo,old_nts_elem_nod,old_nts_amo,surface_nod,sur_nod_inf,&
	stick_slip,old_stick_slip)
	real(real64),intent(in)::nts_amo(:,:)
	real(real64),allocatable,intent(inout)::old_nts_amo(:,:)
	real(real64) gzin
	integer,intent(in)::nts_elem_nod(:,:),surface_nod(:),sur_nod_inf(:,:),stick_slip(:)
	integer,allocatable,intent(inout)::old_nts_elem_nod(:,:),old_stick_slip(:)
	integer i,j,n,m1,m2,m3,shift,slave_node,old_master,master1,master2
	
	n=size(nts_elem_nod,1)
	m1=size(nts_elem_nod,2)
	m2=size(nts_amo,2)
	if( allocated(old_nts_amo) )deallocate(old_nts_amo)
	if( allocated(old_nts_elem_nod) )deallocate(old_nts_elem_nod)
	if( allocated(old_stick_slip) )deallocate(old_stick_slip)
	
	
	allocate( old_nts_elem_nod(n,m1),old_nts_amo(n,m2),old_stick_slip(n)  )
	
	old_nts_elem_nod(:,:)=nts_elem_nod(:,:)
	old_nts_amo(:,:)=nts_amo(:,:)
	old_stick_slip(:)=stick_slip(:)
	
	do i=1,n
		gzin=nts_amo(i,10) !converged gzi
		if(gzin>1.0d0)then
			shift=1
			slave_node=nts_elem_nod(i,1)
			old_master=nts_elem_nod(i,2)
			old_master=nts_elem_nod(i,3)
			call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
			
			old_nts_elem_nod(i,2)=master1
			old_nts_elem_nod(i,3)=master2
			
			gzin=0.0d0
			
		elseif(gzin<0.0d0)then
			shift=-1
			slave_node=nts_elem_nod(i,1)
			old_master=nts_elem_nod(i,2)
			old_master=nts_elem_nod(i,3)
			call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
			
			old_nts_elem_nod(i,2)=master1
			old_nts_elem_nod(i,3)=master2
			gzin=1.0d0
		else
			cycle
		endif
		old_nts_amo(i,:)=0.0d0
		old_nts_amo(i,1)=gzin
		old_nts_amo(i,12)=nts_amo(i,12)
	enddo
	
 end subroutine save_nts_element
!=====================================================================
 subroutine get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
	integer,intent(in)::surface_nod(:),sur_nod_inf(:,:),shift,old_master
	integer,intent(out)::master1,master2
	integer i,surface_nod_ID,domain_number,first_ID,last_ID
	
	if(shift==1)then
		!case of old_master2
		surface_nod_ID=0
		do i=1,size(surface_nod)
			if(surface_nod(i)==old_master )then
				surface_nod_ID=i
				exit
			else
				cycle
			endif
		enddo
		
		domain_number=0
		do i=1,size(sur_nod_inf)
			first_ID=sur_nod_inf(i,1)
			last_ID =sur_nod_inf(i,2)
			if( first_ID<=surface_nod_ID .and. surface_nod_ID<=last_ID)then
				domain_number=i
				exit
			else
				cycle
			endif
		enddo
		
		if(domain_number==0 .or. surface_nod_ID==0)then
			 stop "invalid slave node ID: sub. get_next_segment"
		endif
		
		first_ID=sur_nod_inf(domain_number,1)
		last_ID =sur_nod_inf(domain_number,2)
		
		if(surface_nod_ID==last_ID)then
			master1=surface_nod(last_ID)
			master2=surface_nod(first_ID)
		else
			master1=surface_nod(surface_nod_ID)
			master2=surface_nod(surface_nod_ID+1)
		endif
		
	elseif(shift==-1)then
		surface_nod_ID=0
		do i=1,size(surface_nod)
			if(surface_nod(i)==old_master )then
				surface_nod_ID=i
				exit
			else
				cycle
			endif
		enddo
		
		domain_number=0
		do i=1,size(sur_nod_inf)
			first_ID=sur_nod_inf(i,1)
			last_ID =sur_nod_inf(i,2)
			if( first_ID<=surface_nod_ID .and. surface_nod_ID<=last_ID)then
				domain_number=i
				exit
			else
				cycle
			endif
		enddo
		
		if(domain_number==0 .or. surface_nod_ID==0)then
			 stop "invalid slave node ID: sub. get_next_segment"
		endif
		
		first_ID=sur_nod_inf(domain_number,1)
		last_ID =sur_nod_inf(domain_number,2)
		
		if(surface_nod_ID==first_ID)then
			master1=surface_nod(last_ID)
			master2=surface_nod(first_ID)
		else
			master1=surface_nod(surface_nod_ID-1)
			master2=surface_nod(surface_nod_ID)
		endif	
	else
		 stop "invalid shifting parameter : sub.get_next_segment"
	endif
	
	
 end subroutine get_next_segment
!=====================================================================
 subroutine load_nts_element(nts_elem_nod,nts_amo,old_nts_elem_nod,old_nts_amo,stick_slip,old_stick_slip)
	real(real64),intent(inout)::nts_amo(:,:)
	real(real64),intent(in)::old_nts_amo(:,:)
	integer,intent(inout)::nts_elem_nod(:,:),stick_slip(:)
	integer,intent(in)::old_nts_elem_nod(:,:),old_stick_slip(:)
	
	integer i,j,n
	
	do i=1,size(nts_elem_nod,1)
		n=0
		do j=1,size(old_nts_elem_nod,1)
			if(old_nts_elem_nod(j,1)==nts_elem_nod(i,1) )then
				n=j
				exit
			else
				cycle
			endif
		enddo
		
		if(n==0)then
			cycle
		else
			!nts_elem_nod(i,2)=old_nts_elem_nod(n,2)
			!nts_elem_nod(i,3)=old_nts_elem_nod(n,3)
			nts_amo(i,:)=old_nts_amo(i,:)
			!stick_slip(i)=old_stick_slip(n)
		endif
		
	enddo
 end subroutine load_nts_element
!=====================================================================
 subroutine get_stabilized_nts(nts_elem_nod,surface_nod,sur_nod_inf)
	integer,allocatable,intent(inout)::nts_elem_nod(:,:)
	integer,allocatable::nts_elem_nod_new(:,:)
	integer,intent(in)::surface_nod(:),sur_nod_inf(:,:)
	integer i,j,k,n,node_num,old_master,master1,master2,shift,cs,cm
	
	if(nts_elem_nod(1,1)+nts_elem_nod(1,2)+nts_elem_nod(1,3)==0 )then
		return
	endif
	!expand nts_lem_nod from 3 to 6
	n=size(nts_elem_nod,1)
	allocate(nts_elem_nod_new(n,6) )
	
	!input node#1 and node #2
	do i=1,n
		nts_elem_nod_new(i,1:2)=nts_elem_nod(i,1:2)
		
		!get node#3
		old_master=nts_elem_nod_new(i,2)
		shift=1
		call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
		nts_elem_nod_new(i,3)=master2
		
		!get node#4
		old_master=nts_elem_nod_new(i,2)
		shift=-1
		call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
		nts_elem_nod_new(i,4)=master1
		
		!get node#5
		old_master=nts_elem_nod_new(i,3)
		shift=1
		call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
		nts_elem_nod_new(i,5)=master2
		
		!get node#6
		old_master=nts_elem_nod_new(i,4)
		shift=-1
		call get_next_segment(surface_nod,sur_nod_inf,shift,old_master,master1,master2)
		nts_elem_nod_new(i,6)=master1
	enddo
	
	deallocate(nts_elem_nod)
	allocate(nts_elem_nod(n,6))
	do i=1,n
		nts_elem_nod(i,1:6)=nts_elem_nod_new(i,1:6)
	enddo
	
 end subroutine get_stabilized_nts
!=====================================================================


! #########################################
subroutine setPenaltyParaCM(obj,para)
	class(ContactMechanics_),intent(inout)::obj
	real(real64),intent(in)		::	para

	obj%PenaltyPara = para

end subroutine
! #########################################
  

! #########################################
subroutine updateContactStressCM(obj)
	class(ContactMechanics_),intent(inout)::obj
	type(MPI_)::mpidata
	
	

	if(.not. allocated(obj%FEMIface%NTS_ElemNod) )then
		call obj%FEMIface%GetFEMIface()
	endif
	! check NTS
	!call showArray(obj%FEMIface%Mesh1%NodCoord,IndexArray=obj%FEMIface%NTS_ElemNod(:,1:1)&
	!	,Name="checkNTSmesh1.txt" )
	!call showArray(obj%FEMIface%Mesh2%NodCoord,IndexArray=obj%FEMIface%NTS_ElemNod(:,2: )&
	!	,Name="checkNTSmesh2.txt" )
	!call showArray(obj%FEMIface%FEMDomains(1)%FEMDomainp%Mesh%NodCoord,&
	!	IndexArray=obj%FEMIface%NTS_ElemNod(:,1:1),Name="checkNTSdomain2.txt" )
	!call showArray(obj%FEMIface%FEMDomains(2)%FEMDomainp%Mesh%NodCoord,&
	!	IndexArray=obj%FEMIface%NTS_ElemNod(:,2: ),Name="checkNTSdomain2.txt" )
	!call showArray(obj%FEMIface%Mesh1%NodCoord, Name="checkNTSmesh1.txt" )
	!call showArray(obj%FEMIface%Mesh2%NodCoord, Name="checkNTSmesh2.txt" )
	!call showArray(obj%FEMIface%Mesh2%NodCoord, Name="checkNTSmesh2.txt" )
	!call showArray(obj%FEMIface%Mesh1%ElemNod,Name="checkNTSmesh1.txt" )
	!call showArray(obj%FEMIface%Mesh2%ElemNod,Name="checkNTSmesh2.txt" )
	!call showArray(obj%FEMIface%NTS_ElemNod,Name="checkNTSmesh3.txt" ) !wrong pointer
	!call showArray(obj%FEMIface%NTS_ElemNod,Name="checkNTSmesh4.txt" ) !wrong pointer
	
	
	
	call obj%getGap()
	
	call obj%getForce()
	
	call obj%exportForceAsTraction()



end subroutine
! #########################################


! #########################################
subroutine getGapCM(obj)
	class(ContactMechanics_),intent(inout)::obj
	real(real64),allocatable :: gap(:),avec(:),avec1(:),avec2(:),nvec(:),evec(:),xs1(:),xm1(:),xm2(:),xm3(:),xm4(:)
	real(real64),allocatable :: xm5(:),xm6(:),xm7(:),xm8(:),mid(:)
	real(real64) :: val
	integer :: i,j,k,n,NumOfNTSelem,dim_num
	type(MPI_)::mpidata

	if(.not. allocated(obj%FEMIface%NTS_ElemNod) )then
		print *, "Error :: ContactMechanics_ >> updateContactStressCM >> not (.not. allocated(obj%NTS_ElemNod) )"
		return	
	endif

	

	NumOfNTSelem=size(obj%FEMIface%NTS_ElemNod,1)

	
	dim_num=size(obj%FEMIface%FEMDomains(1)%FEMDomainp%Mesh%NodCoord,2 ) 
	
	

	allocate(gap(dim_num) )
	allocate(avec(3) )
	allocate(avec1(3) )
	allocate(avec2(3) )
	allocate(nvec(3) )
	allocate(evec(3) )
	allocate(xs1(3))
	allocate(xm1(3))
	allocate(xm2(3))
	allocate(xm3(3))
	allocate(xm4(3))
	allocate(xm5(3))
	allocate(xm6(3))
	allocate(xm7(3))
	allocate(xm8(3))
	allocate(mid(3))

	! initial :: inactive
	gap=0.0d0
	avec(:)=0.0d0
	avec1(:)=0.0d0
	avec2(:)=0.0d0
	nvec(:)=0.0d0
	evec(:)=0.0d0
	evec(3)=1.0d0
	xs1(:)=0.0d0
	xm1(:)=0.0d0
	xm2(:)=0.0d0
	xm3(:)=0.0d0
	xm4(:)=0.0d0
	xm5(:)=0.0d0
	xm6(:)=0.0d0
	xm7(:)=0.0d0
	xm8(:)=0.0d0
	mid(:)=0.0d0


	

	if(.not.allocated(obj%NTSGap))then
		allocate( obj%NTSGap(NumOfNTSElem,dim_num) )
		obj%NTSGap(:,:)=0.0d0
	elseif( size(obj%NTSGap,1)/=NumOfNTSElem )then
		deallocate(obj%NTSGap)
		allocate( obj%NTSGap(NumOfNTSElem,dim_num) )
		obj%NTSGap(:,:)=0.0d0
	else
		obj%NTSGap(:,:)=0.0d0
	endif


	if(.not.allocated(obj%NTSGzi))then
		allocate( obj%NTSGzi(NumOfNTSElem,dim_num) )
		obj%NTSGzi(:,:)=0.0d0
	elseif( size(obj%NTSGzi,1)/=NumOfNTSElem )then
		deallocate(obj%NTSGzi)
		allocate( obj%NTSGzi(NumOfNTSElem,dim_num) )
		obj%NTSGzi(:,:)=0.0d0
	else
		obj%NTSGzi(:,:)=0.0d0
	endif
	

	if(dim_num==2)then
		! 2-D NTS
		do i=1,NumOfNTSElem
			print *, "CmClass getGap not validated"
			xs1(	1:2)=obj%FEMIface%NTS_NodCoord(i,1:2)
			xm1(1:2)=obj%FEMIface%NTS_NodCoord(i,3:4)
			xm2(1:2)=obj%FEMIface%NTS_NodCoord(i,5:6)
			avec(1:2)=xm2(1:2)-xm1(1:2)
			nvec(1:3)=cross_product(evec,avec)
			val=norm(nvec)
			if(val==0.0d0)then
				print *, "norm = ",val
				stop "ERROR CMClass >> getGap"
			endif
			nvec(:)=1.0d0/val*nvec(:)
			obj%NTSGap(i,1:2)=dot_product( xs1(1:2)-xm1(1:2),nvec(1:2)  )
			print *, "gap=",dot_product(obj%NTSGap(i,1:2),nvec(1:2) )
		enddo
	elseif(dim_num==3)then
		! 3-D NTS
	
		do i=1,NumOfNTSElem
			
			xs1(1:3)=obj%FEMIface%NTS_NodCoord(i, 1:	3)
			xm1(1:3)=obj%FEMIface%NTS_NodCoord(i, 4:	6)
			xm2(1:3)=obj%FEMIface%NTS_NodCoord(i, 7:	9)
			xm3(1:3)=obj%FEMIface%NTS_NodCoord(i,10:	12)
			xm4(1:3)=obj%FEMIface%NTS_NodCoord(i,13:	15)
			
			mid(:)=0.250d0*xm1(:)+0.250d0*xm2(:)+0.250d0*xm3(:)+0.250d0*xm4(:)
			avec1(1:3)=xm1(1:3)-mid(1:3)
			avec2(1:3)=xm2(1:3)-mid(1:3)
			nvec(1:3)=cross_product(avec1,avec2)
			val=norm(nvec)
			if(val==0.0d0)then
				print *, "norm = ",val
				stop "ERROR CMClass >> getGap"
			endif
			nvec(:)=1.0d0/val*nvec(:)
			obj%NTSGap(i,1:3)=dot_product( xs1(1:3)-mid(1:3),nvec(1:3)  )
			

			!print *, dot_product(obj%NTSGap(i,1:3),nvec)
			!write(1010,*) " " 
			!write(1010,*) xs1(1:3)
			!write(1010,*) mid(1:3)
			!write(1010,*) " " 
			!write(1010,*) xm1(1:3)
			!write(1010,*) xm2(1:3)
			!write(1010,*) xm3(1:3)
			!write(1010,*) xm4(1:3)
			!write(1010,*) xm1(1:3)
			!write(1020,*) mid(1:3),xs1(1:3)-mid(1:3) 
			!write(1030,*) mid(1:3),obj%NTSGap(i,1:3) 
			!print *, "gap=",dot_product(obj%NTSGap(i,1:3),nvec(1:3) )
		enddo
	else
		print *, "Dimension of coord = ",dim_num
		stop "getGapCM >> invalid dimension"
	endif
	

end subroutine
! #########################################


! #########################################
subroutine getForceCM(obj)
	class(ContactMechanics_),intent(inout)::obj
	real(real64),allocatable :: gap(:),avec(:),avec1(:),avec2(:),nvec(:),evec(:),xs1(:),xm1(:),xm2(:),xm3(:),xm4(:)
	real(real64),allocatable :: xm5(:),xm6(:),xm7(:),xm8(:),mid(:)
	real(real64) :: val,area
	integer :: i,j,k,n,m,NumOfNTSelem,dim_num

	real(real64) :: gzi,gzi1,gzi2

	if(.not. allocated(obj%FEMIface%NTS_ElemNod) )then
		print *, "Error :: ContactMechanics_ >> updateContactStressCM >> not (.not. allocated(obj%NTS_ElemNod) )"
		return	
	endif


	NumOfNTSelem=size(obj%FEMIface%NTS_ElemNod,1)

	dim_num=size(obj%FEMIface%FEMDomains(1)%FEMDomainp%Mesh%NodCoord,2 ) 

	

	allocate(gap(dim_num) )
	allocate(avec(3) )
	allocate(avec1(3) )
	allocate(avec2(3) )
	allocate(nvec(3) )
	allocate(evec(3) )
	allocate(xs1(3))
	allocate(xm1(3))
	allocate(xm2(3))
	allocate(xm3(3))
	allocate(xm4(3))
	allocate(xm5(3))
	allocate(xm6(3))
	allocate(xm7(3))
	allocate(xm8(3))
	allocate(mid(3))

	! initial :: inactive
	gap=0.0d0
	avec(:)=0.0d0
	avec1(:)=0.0d0
	avec2(:)=0.0d0
	nvec(:)=0.0d0
	evec(:)=0.0d0
	evec(3)=1.0d0
	xs1(:)=0.0d0
	xm1(:)=0.0d0
	xm2(:)=0.0d0
	xm3(:)=0.0d0
	xm4(:)=0.0d0
	xm5(:)=0.0d0
	xm6(:)=0.0d0
	xm7(:)=0.0d0
	xm8(:)=0.0d0
	mid(:)=0.0d0

	n=size(obj%FEMDomain1%Mesh%NodCoord,1)
	m=size(obj%FEMDomain2%Mesh%NodCoord,1)
	dim_num=size(obj%FEMDomain2%Mesh%NodCoord,2)
	if(.not.allocated(obj%Domain1Force) )then
		allocate(obj%Domain1Force(n,dim_num) )
		obj%Domain1Force(:,:)=0.0d0
	endif
	if(.not.allocated(obj%Domain2Force) )then
		allocate(obj%Domain2Force(m,dim_num) )
		obj%Domain2Force(:,:)=0.0d0
	endif

	gzi=0.0d0
	gzi1=0.0d0
	gzi2=0.0d0
	if(dim_num==2)then
		! import gzi at here
		! 2-D NTS
		do i=1,NumOfNTSElem
			print *, "CmClass getGap not validated"
			xs1(	1:2)=obj%FEMIface%NTS_NodCoord(i,1:2)
			xm1(1:2)=obj%FEMIface%NTS_NodCoord(i,3:4)
			xm2(1:2)=obj%FEMIface%NTS_NodCoord(i,5:6)
			avec(1:2)=xm2(1:2)-xm1(1:2)
			nvec(1:3)=cross_product(evec,avec)
			val=norm(nvec)
			if(val==0.0d0)then
				print *, "norm = ",val
				stop "ERROR CMClass >> getGap"
			endif
			nvec(:)=1.0d0/val*nvec(:)

		enddo
	elseif(dim_num==3)then
		! import gzi at here

		do i=1,NumOfNTSElem
			
			xs1(1:3)=obj%FEMIface%NTS_NodCoord(i, 1:	3)
			xm1(1:3)=obj%FEMIface%NTS_NodCoord(i, 4:	6)
			xm2(1:3)=obj%FEMIface%NTS_NodCoord(i, 7:	9)
			xm3(1:3)=obj%FEMIface%NTS_NodCoord(i,10:	12)
			xm4(1:3)=obj%FEMIface%NTS_NodCoord(i,13:	15)
			
			mid(:)=0.250d0*xm1(:)+0.250d0*xm2(:)+0.250d0*xm3(:)+0.250d0*xm4(:)
			avec1(1:3)=xm1(1:3)-mid(1:3)
			avec2(1:3)=xm2(1:3)-mid(1:3)
			nvec(1:3)=cross_product(avec1,avec2)
			val=norm(nvec)
			if(val==0.0d0)then
				print *, "norm = ",val
				stop "ERROR CMClass >> getGap"
			endif
			nvec(:)=1.0d0/val*nvec(:)
			obj%NTSGap(i,1:3)=dot_product( xs1(1:3)-mid(1:3),nvec(1:3)  )
			
			! Area
			area=1.0d0

			! compute ShapeFunc(:)
			! get contact force from penaltypara*gap*ShapeFunc(:)
			do j=1,size(obj%FEMIface%NTS_ElemNod,1)
				obj%Domain1Force(obj%FEMIface%NTS_ElemNod(j,1),1:3 )=&
				obj%Domain1Force(obj%FEMIface%NTS_ElemNod(j,1),1:3 )+&
				obj%penaltypara*obj%NTSGap(i,1:3)*area
			
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,2),1:3 )=&
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,2),1:3 )+&
				obj%penaltypara*obj%NTSGap(i,1:3)*area/4.0d0*(-1.0d0)
			
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,3),1:3 )=&
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,3),1:3 )+&
				obj%penaltypara*obj%NTSGap(i,1:3)*area/4.0d0*(-1.0d0)
			
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,4),1:3 )=&
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,4),1:3 )+&
				obj%penaltypara*obj%NTSGap(i,1:3)*area/4.0d0*(-1.0d0)
			
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,5),1:3 )=&
				obj%Domain2Force(obj%FEMIface%NTS_ElemNod(j,5),1:3 )+&
				obj%penaltypara*obj%NTSGap(i,1:3)*area/4.0d0*(-1.0d0)
			enddo


		enddo


	else
		print *, "Dimension of coord = ",dim_num
		stop "getForceCM >> invalid dimension"
	endif




end subroutine
! #########################################

! #########################################
subroutine exportForceAsTractionCM(obj)
	class(ContactMechanics_),intent(inout)::obj
	type(mpi_)::mpidata
	integer :: nodeid,i,j,k
	real(real64) :: bcval

	
	
	do i=1,size(obj%FEMIface%NTS_ElemNod,1)
		
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		! Really??
		print *, "slave node id : ",obj%FEMIface%NTS_ElemNod(i,1),"master node id : ",obj%FEMIface%NTS_ElemNod(i,2:)
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		do j=1,size(obj%FEMIface%NTS_ElemNod,2)

			do k=1,size(obj%Domain1Force,2)
				if(j==1)then
					
					!!!!!!!! debug !!!!!!!!!!!!!!!

					! which is the correct node_id?
					nodeid=obj%FEMIface%Mesh1%GlobalNodID(obj%FEMIface%NTS_ElemNod(i,j))
					!nodeid=obj%FEMIface%GloNodPoint1(obj%FEMIface%NTS_ElemNod(i,j))

					! obj%FEMIface%NTS_ElemNod is node pointer to local nodes, obj%FEMIface%Mesh%NodCoord
					!nodeid=obj%FEMIface%NTS_ElemNod(i,j)
					
					bcval = obj%Domain1Force(obj%FEMIface%NTS_ElemNod(i,j),k)
					!bcval = 0.0d0
					!bcval=zeroif(obj%NTSGap(i,k),positive=.true.)/10000.0d0
					if(k/=1)then
						bcval=0.0d0
					endif

					
					call obj%FEMDomain1%AddNBC(NodID=nodeid,DimID=k,Val=bcval,FastMode=.false.)
				else
					
					!!!!!!!! debug !!!!!!!!!!!!!!!
					nodeid=obj%FEMIface%Mesh2%GlobalNodID(obj%FEMIface%NTS_ElemNod(i,j))
					!nodeid=obj%FEMIface%GloNodPoint2(obj%FEMIface%NTS_ElemNod(i,j))
					!nodeid=obj%FEMIface%NTS_ElemNod(i,j)
					
					bcval = obj%Domain2Force(obj%FEMIface%NTS_ElemNod(i,j),k)

					!bcval = 0.0d0
					!bcval=zeroif(obj%NTSGap(i,k),positive=.true.)/10000.0d0

					if(k/=1)then
						bcval=0.0d0
					endif

					call obj%FEMDomain2%AddNBC(NodID=nodeid,DimID=k,Val=bcval,FastMode=.false.)
				endif
			enddo
		enddo
	enddo		
	
    !call showArray(obj%FEMDomain1%Mesh%NodCoord,IndexArray=obj%FEMIface%GloNodPoint1,Name="obj%GloNodPoint1.txt" )
    !call showArray(obj%FEMDomain2%Mesh%NodCoord,IndexArray=obj%FEMIface%GloNodPoint2,Name="obj%GloNodPoint2.txt" )
	
	call obj%FEMIface%GmshPlotMesh(Name="debugNTS",withNeumannBC=.true.,withDirichletBC=.true.)

	!call mpidata%end()
	!stop "debug"	
end subroutine
! #########################################


! #########################################################
subroutine updateTimestepContact(obj,timestep)
    class(ContactMechanics_),intent(inout)::obj
    integer,optional,intent(in)::timestep
    
    call obj%FEMIFace%updateTimeStep(timestep=timestep)

end subroutine
! #########################################################


end module 