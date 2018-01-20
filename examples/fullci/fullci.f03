      program fullCI
!
!     This program perfoms a full CI calculation.
!
!     L. M. Thompson, 2016
!
      use mqc_gaussian
!
!     Variable Declarations...
!
      implicit none
      character(len=:),allocatable::fileName
      type(mqc_gaussian_unformatted_matrix_file)::fileInfo 
      integer::iOut=6,iPrint=2
      logical::UHF
      type(mqc_pscf_wavefunction)::wavefunction
      type(mqc_molecule_data)::moleculeInfo
      type(mqc_twoERIs)::eris,mo_ERIs
      type(mqc_scalar)::Vnn
      type(mqc_determinant)::determinants
      type(mqc_scf_integral)::mo_core_ham
      type(mqc_matrix)::CI_Hamiltonian
      type(mqc_vector)::final_energy
!
      Write(IOut,*)
      Write(IOut,*) 'Full Configuration Interaction Energy Calculator'
      Write(IOut,*)
      Write(IOut,*) 'L. M. Thompson 2017'
      Write(IOut,*)
!
!     Get the user-defined filename from the command line and then call the
!     routine that reads the Gaussian matrix file.
!
      call mqc_get_command_argument(1,fileName)
      call fileInfo%load(filename)
      call fileInfo%getESTObj('wavefunction',wavefunction)
      call wavefunction%print(iOut,'all')
      call fileInfo%getMolData(moleculeInfo)
      call fileInfo%get2ERIs('regular',eris)
      call eris%print(iOut,'AO 2ERIs')
!
      if(wavefunction%wf_type.eq.'U') then
        UHF = .true.
        write(iOut,*) 'found UHF wavefunction'
      elseIf(wavefunction%wf_type.eq.'R') then
        UHF = .False.
        write(iOut,*) 'found RHF wavefunction'
      else
        call mqc_error_A('Unsupported wavefunction type in fullci',iOut, &
          'Wavefunction%wf_type',wavefunction%wf_type)
      endIf 
!
      if (wavefunction%wf_complex) call mqc_error('Complex wavefunctions unsupported in fullci')
!
!     Compute the nuclear-nuclear repulsion energy.
!
      Vnn = mqc_get_nuclear_repulsion(iOut,moleculeInfo)
!
!     Generate Slater Determinants       
!
      call gen_det_str(iOut,iPrint,wavefunction%nBasis,wavefunction%nAlpha, &
        Wavefunction%nBeta,determinants)
!
!     Transform one and two-electron integrals to MO basis
!
      if(iPrint.eq.1) write(iOut,*) 'Transforming MO integrals'
      mo_core_ham = matmul(transpose(wavefunction%MO_Coefficients),matmul(wavefunction%core_Hamiltonian, &
          Wavefunction%MO_Coefficients))
      if(IPrint.ge.2) call mo_core_ham%print(iOut,'MO Basis Core Hamiltonian') 
      call twoERI_trans(iOut,iPrint,wavefunction%MO_Coefficients,ERIs,mo_ERIs,UHF)
!
!     Generate Hamiltonian Matrix
!
      call mqc_build_ci_hamiltonian(iOut,iPrint,wavefunction%nBasis,determinants, &
        mo_core_ham,mo_ERIs,UHF,CI_Hamiltonian)
!
!     Diagonalize Hamiltonian
!
      if(iPrint.eq.1) write(iOut,*) 'Diagonalizing CI Hamiltonian'
      call CI_Hamiltonian%diag(wavefunction%pscf_energies,wavefunction%pscf_amplitudes)
      if(iPrint.ge.1) then 
        call wavefunction%pscf_amplitudes%print(iOut,'CI Eigenvectors')
        call wavefunction%pscf_energies%print(iOut,'CI Eigenvalues')
      endIf
!
      final_energy = Vnn + wavefunction%pscf_energies
      call final_energy%print(iOut,'Final Energy') 
!
 999  End Program FullCI     
