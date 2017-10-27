      Module MQC_Files
!
!     **********************************************************************
!     **********************************************************************
!     **                                                                  **
!     **               The Merced Quantum Chemistry Package               **
!     **                            (MQCPack)                             **
!     **                       Development Version                        **
!     **                            Based On:                             **
!     **                     Development Version 0.1                      **
!     **                                                                  **
!     **                                                                  **
!     ** Written By:                                                      **
!     **    Lee M. Thompson, Xianghai Sheng, and Hrant P. Hratchian       **
!     **                                                                  **
!     **                                                                  **
!     **                      Version 1.0 Completed                       **
!     **                           May 1, 2017                            **
!     **                                                                  **
!     **                                                                  **
!     ** Modules beloning to MQCPack:                                     **
!     **    1. MQC_General                                                **
!     **    2. MQC_DataStructures                                         **
!     **    3. MQC_Algebra                                                **
!     **    4. MQC_Files                                                  **
!     **    5. MQC_Molecule                                               **
!     **    6. MQC_EST                                                    **
!     **    7. MQC_Gaussian                                               **
!     **                                                                  **
!     **********************************************************************
!     **********************************************************************
!
      use MQC_General
!
!
!     Derived Types, Objects, and Classes.
!
      Implicit None
!
!     Abstract MQC_FileInfo Type...
      Type,Abstract::MQC_FileInfo
        Character(Len=256)::filename=' '
        Logical::CurrentlyOpen=.false.
        Integer::UnitNumber=0
      Contains
        Procedure,Pass::IsOpen=>MQC_File_IsOpen
!hph        Procedure(MQC_Open_File),Pass,Deferred::OpenFile
!hph        Procedure(MQC_Close_File),Pass,Deferred::CloseFile
      End Type MQC_FileInfo

!hph+
!      Abstract Interface
!        Subroutine MQC_Open_File(FileInfo,FileName,UnitNumber,OK)
!          Import MQC_FileInfo
!          Class(MQC_FileInfo),Intent(InOut)::FileInfo
!          Character(Len=*),Intent(In)::FileName
!          Integer,Intent(In)::UnitNumber
!          Logical,Intent(Out)::OK
!        End Subroutine MQC_Open_File
!      End Interface
!      Abstract Interface
!        Subroutine MQC_Close_File(FileInfo)
!          Import MQC_FileInfo
!          Class(MQC_FileInfo),Intent(InOut)::FileInfo
!        End Subroutine MQC_Close_File
!      End Interface
!hph-

!
!     MQC_Text_FileInfo Type...
      Type,Extends(MQC_FileInfo)::MQC_Text_FileInfo
        Character(Len=512)::buffer=' ',buffer_caps=' '
        Logical::buffer_loaded=.False.
        Integer::buffer_cursor=0
        Logical::Inside_Quotes=.False.
      Contains
        Procedure,Pass::OpenFile => MQC_Open_Text_File
        Procedure,Pass::CloseFile => MQC_Close_Text_File
        Procedure,Pass::Rewind => MQC_Rewind_Text_File
        Procedure,Pass::LoadBuffer => MQC_Files_Load_Buffer
        Procedure,Pass::GetBuffer => MQC_Files_Text_File_Get_Buffer
        Procedure,Pass::GetNextString => MQC_Files_Text_File_Read_String
        Procedure,Pass::WriteLine => MQC_Files_Text_File_Write_Line
      End Type MQC_Text_FileInfo
!
!     Module Variables/Constants.
      Integer,Parameter::NDelimiters_Default=3
      Character(Len=1),Dimension(NDelimiters_Default),Parameter::  &
        Delimit_Default=(/ ' ',',',';' /)
!
!
!     Subroutines and Functions.
!
      CONTAINS

!hph+        
!!
!!
!!     PROCEDURE Char_Change_Case
!      Subroutine Char_Change_Case(ToUpper,Char)
!!
!!     This subroutine changes the case of all of the letters in Char.  If
!!     ToUpper is sent as .TRUE., then all lower-case letters are made
!!     upper-case.  If ToUpper is sent as .FALSE., then all upper-case
!!     letters are made lower-case.
!!
!      implicit none
!!     Dummy Variables
!      character(len=*),intent(inout)::Char
!      logical,intent(in)::ToUpper
!!     Local Variables
!      integer::N
!!
!!     Do the work...
!!
!      if(ToUpper) then
!        do N = 1,Len(Trim(Char))
!          if(LGE(Char(N:N),'a').and.LLE(Char(N:N),'z')) &
!            Char(N:N) = achar(iachar(Char(N:N))-32)
!        enddo
!      else
!        do N = 1,Len(Trim(Char))
!          if(LGE(Char(N:N),'A').and.LLE(Char(N:N),'Z')) &
!            Char(N:N) = achar(iachar(Char(N:N))+32)
!        enddo
!      endif
!!
!      Return
!      End
!hph-
      
!
!
!PROCEDURE MQC_IsOpen_File
      Function MQC_File_IsOpen(FileInfo)
!
!     This Logical Function returns whether or not the file in object
!     FileInfo is open (TRUE) or closed (FALSE).
!
!
!     Variable Declarations.
!
      Implicit None
      Class(MQC_FileInfo),Intent(In)::FileInfo
      Logical::MQC_File_IsOpen
!
!
!     Do the work...
      MQC_File_IsOpen = FileInfo%CurrentlyOpen
!
      Return
      End Function MQC_File_IsOpen


!
!PROCEDURE MQC_Open_Text_File
      Subroutine MQC_Open_Text_File(FileInfo,FileName,UnitNumber, &
        OK,fileAction)
!
!     This Routine is used to connect a file and to initialize the reading
!     buffer used by other procedures in this module.
!
!
!     Variable Declarations.
!
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Character(Len=*),Intent(In)::FileName
      Integer,Intent(In)::UnitNumber
      Logical,Intent(Out),Optional::OK
      Character(Len=*),Intent(In),Optional::fileAction
!
      Integer::IError
      Logical::EOF,Temp_Logical
      Character(Len=64)::my_fileAction
!
!
!     Start by initializing dummy argument OK to False.
!
      if(PRESENT(OK)) OK = .False.
!
!     Fill my_fileAction.
!
      if(.not.PRESENT(fileAction)) then
        my_fileAction = 'READOLD'
      else
        call String_Change_Case(fileAction,'u',my_fileAction)
      endIf
!
!     Open the file and initialize the reading buffer.
!
      select case(TRIM(my_fileAction))
      case('READ','READOLD')
        Open(Unit=UnitNumber,File=TRIM(FileName),Action='Read',  &
          Status='old',Position='Rewind',IOStat=IError)
      case('WRITE','WRITENEW')
        Open(Unit=UnitNumber,File=TRIM(FileName),Action='Write',  &
          Status='unknown',IOStat=IError)
      case('WRITEAPPEND')
        Open(Unit=UnitNumber,File=TRIM(FileName),Action='Write',  &
          Status='old',Position='Append',IOStat=IError)
      case default
        call MQC_Error('Unkown file action.')
      endSelect
      If(IError.ne.0) Return
      FileInfo%filename = TRIM(FileName)
      FileInfo%CurrentlyOpen = .True.
      FileInfo%UnitNumber = UnitNumber
      FileInfo%buffer = ' '
      FileInfo%buffer_caps = ' '
      FileInfo%buffer_loaded = .False.
      If(MQC_Files_Load_Buffer(FileInfo,EOF)) Return
      if(PRESENT(OK)) OK = .True.
!
      Return
      End Subroutine MQC_Open_Text_File


!
!PROCEDURE MQC_Close_Text_File
      Subroutine MQC_Close_Text_File(FileInfo)
!
!     This Routine is used to close a text file previously opened.
!
!
!     Variable Declarations.
!
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
!
      Integer::IError
!
!
!     Close the file and then initialize FileInfo%CurrentlyOpen and
!     FileInfo%buffer_loaded.
!
      Close(Unit=FileInfo%UnitNumber)
      FileInfo%CurrentlyOpen = .False.
      FileInfo%UnitNumber = 0
      FileInfo%buffer = ' '
      FileInfo%buffer_caps = ' '
      FileInfo%buffer_loaded = .False.
!
      Return
      End Subroutine MQC_Close_Text_File


!
!PROCEDURE MQC_Rewind_Text_File
      Subroutine MQC_Rewind_Text_File(FileInfo,OK)
!
!     This Routine is used to REWIND a text file previously opened.
!
!
!     Variable Declarations.
!
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Logical,Intent(Out)::OK
!
      Integer::IError
!
!
!     Rewind the file.
!
      Rewind(Unit=FileInfo%UnitNumber,IOStat=IError)
      OK = IError.eq.0
!
      Return
      End Subroutine MQC_Rewind_Text_File


!
!PROCEDURE MQC_Files_Text_File_Get_Buffer
      Subroutine MQC_Files_Text_File_Get_Buffer(FileInfo,Char_Out,Caps)
!
!     This subroutine returns the current string in the buffer associated
!     with the file defined by object FileInfo. This string is returned in
!     OUTPUT dummy argument Char_Out.
!
!     Input dummy argument Caps is OPTIONAL. If Caps is TRUE, the
!     all-capitalized form of the buffer is returned in Char_Out.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(In)::FileInfo
      Character(*),Intent(Out)::Char_Out
      Logical,Optional,Intent(In)::Caps
!
      Logical::My_Caps
!
!
!     Do the work.
!
      If(Present(Caps)) then
        My_Caps = Caps
      else
        My_Caps = .False.
      endIf
      Char_Out = ' '
      If(My_Caps) then
        Char_Out = TRIM(FileInfo%buffer_caps)
      else
        Char_Out = TRIM(FileInfo%buffer)
      endIf
!
      Return
      End Subroutine MQC_Files_Text_File_Get_Buffer


!
!PROCEDURE MQC_Files_Text_File_Read_Int
      Subroutine MQC_Files_Text_File_Read_Int(FileInfo,Int_Out,EOF,OK)
!
!     This subroutine reads the next value from a text file. It is expected
!     that this next value should be an integer, which is returned in dummy
!     argument Int_Out. Dummy argument OK is set to TRUE if the reading
!     process was handled without error; otherwise, OK will be returned as
!     FALSE.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Integer,Intent(Out)::Int_Out
      Logical,Intent(Out)::EOF,OK
!
      Real::Temp_Real
      Character(Len=1)::Temp_Char,Type_Out
      Logical::Found
!
!
!     Get the next value in the file buffer and ensure it is an integer.
!
      Int_Out = 0
      Call MQC_Files_Text_File_Read_Next(FileInfo,NDelimiters_Default,  &
        Delimit_Default,.True.,Int_Out,Temp_Real,Temp_Char,Type_Out,  &
        Found,EOF,OK)
      If(.not.EOF) OK = OK.and.Found.and.Type_Out.eq.'I'
!
      Return
      End Subroutine MQC_Files_Text_File_Read_Int


!
!PROCEDURE MQC_Files_Text_File_Read_Int_Vec
      Subroutine MQC_Files_Text_File_Read_Int_Vec(FileInfo,IntVec_Out, &
        EOF,OK,N)
!
!     This subroutine reads the next N values from a text file. It is
!     expected that this next value should be an array of integers, which
!     is returned in dummy argument IntVec_Out. Dummy argument OK is set to
!     TRUE if the reading process was handled without error; otherwise, OK
!     will be returned as FALSE.
!
!     Dummy argument N is optional and gives the number of values to read.
!     If N is not sent, the length of IntVec_Out is used instead. If N is
!     greater than the length of IntVec_Out, the length of IntVec_Out is
!     used.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Integer,Dimension(:),Intent(Out)::IntVec_Out
      Logical,Intent(Out)::EOF,OK
      Integer,OPTIONAL::N
!
      Integer::i,NN,Temp_Int
      Real::Temp_Real
      Character(Len=1)::Temp_Char,Type_Out
      Logical::Found
!
!
!     Figure out the number of elements we need to read from the file. The
!     length used below is put into variable NN.
!
      NN = Size(IntVec_Out)
      If(Present(N)) then
        If(N.lt.NN) NN = N
      endIf
!
!     Get the next value in the file buffer and ensure it is an integer.
!
      Do i = 1,NN
        Temp_Int = 0
        Call MQC_Files_Text_File_Read_Next(FileInfo,  &
          NDelimiters_Default,Delimit_Default,.True.,Temp_Int,  &
          Temp_Real,Temp_Char,Type_Out,Found,EOF,OK)
        If(.not.EOF) OK = OK.and.Found.and.Type_Out.eq.'I'
        IntVec_Out(i) = Temp_Int
      EndDo
!
      Return
      End Subroutine MQC_Files_Text_File_Read_Int_Vec


!
!PROCEDURE MQC_Files_Text_File_Read_Real
      Subroutine MQC_Files_Text_File_Read_Real(FileInfo,Real_Out,EOF,OK)
!
!     This subroutine reads the next value from a text file. It is expected
!     that this next value should be a real value, which is returned in
!     dummy argument Real_Out. Dummy argument OK is set to TRUE if the
!     reading process was handled without error; otherwise, OK will be
!     returned as FALSE.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Real,Intent(Out)::Real_Out
      Logical,Intent(Out)::EOF,OK
!
      Integer::Temp_Int
      Character(Len=1)::Temp_Char,Type_Out
      Logical::Found
!
!
!     Get the next value in the file buffer and ensure it is a real.
!
      Real_Out = 0.0
      Call MQC_Files_Text_File_Read_Next(FileInfo,NDelimiters_Default,  &
        Delimit_Default,.True.,Temp_Int,Real_Out,Temp_Char,Type_Out,  &
        Found,EOF,OK)
      If(.not.EOF) OK = OK.and.Found.and.Type_Out.eq.'R'
!
      Return
      End Subroutine MQC_Files_Text_File_Read_Real


!
!PROCEDURE MQC_Files_Text_File_Read_Real_Vec
      Subroutine MQC_Files_Text_File_Read_Real_Vec(FileInfo,RealVec_Out, &
        EOF,OK,N)
!
!     This subroutine reads the next N values from a text file. It is
!     expected that this next value should be an array of reals, which is
!     returned in dummy argument RealVec_Out. Dummy argument OK is set to
!     TRUE if the reading process was handled without error; otherwise, OK
!     will be returned as FALSE.
!
!     Dummy argument N is optional and gives the number of values to read.
!     If N is not sent, the length of RealVec_Out is used instead. If N is
!     greater than the length of RealVec_Out, the length of RealVec_Out is
!     used.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Real,Dimension(:),Intent(Out)::RealVec_Out
      Logical,Intent(Out)::EOF,OK
      Integer,OPTIONAL::N
!
      Integer::i,NN,Temp_Int
      Real::Temp_Real
      Character(Len=1)::Temp_Char,Type_Out
      Logical::Found
!
!
!     Figure out the number of elements we need to read from the file. The
!     length used below is put into variable NN.
!
      NN = Size(RealVec_Out)
      If(Present(N)) then
        If(N.lt.NN) NN = N
      endIf
!
!     Get the next value in the file buffer and ensure it is an real.
!
      Do i = 1,NN
        Temp_Real = 0.0
        Call MQC_Files_Text_File_Read_Next(FileInfo,  &
          NDelimiters_Default,Delimit_Default,.True.,Temp_Int,  &
          Temp_Real,Temp_Char,Type_Out,Found,EOF,OK)
        If(.not.EOF) OK = OK.and.Found.and.Type_Out.eq.'R'
        RealVec_Out(i) = Temp_Real
      EndDo
!
      Return
      End Subroutine MQC_Files_Text_File_Read_Real_Vec


!
!PROCEDURE MQC_Files_Text_File_Read_String
      Subroutine MQC_Files_Text_File_Read_String(FileInfo,String_Out,  &
        EOF,OK)
!
!     This subroutine reads the next value from a text file. It is expected
!     that this next value should be a character (string) value, which is
!     returned in dummy argument String_Out. Dummy argument OK is set to
!     TRUE if the reading process was handled without error; otherwise, OK
!     will be returned as FALSE.
!
!
!     Variable Declarations.
      Implicit None
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      Character(Len=*),Intent(Out)::String_Out
      Logical,Intent(Out)::EOF,OK
!
      Integer::Temp_Int
      Real::Temp_Real
      Logical::Found
!
!
!     Get the next value in the file buffer and ensure it is a
!     character/string.
!
      String_Out = ' '
      Call MQC_Files_Next_String(FileInfo,NDelimiters_Default,Delimit_Default,  &
        .True.,FileInfo%buffer_cursor,String_Out,Found,EOF,OK)
      If(.not.EOF) OK = OK.and.Found
!
      Return
      End Subroutine MQC_Files_Text_File_Read_String


!
!PROCEDURE MQC_Files_Text_File_Read_Next
      Subroutine MQC_Files_Text_File_Read_Next(FileInfo,NDelimiters,Delimit,  &
        Group_Double_Quotes,Int_Out,Real_Out,Char_Out,Type_Out,Found,  &
        EOF,OK,Cursor_Position)
!
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      integer::i,NDelimiters,ICurStart
      character(len=*),dimension(NDelimiters),intent(in)::Delimit
      logical,intent(in)::Group_Double_Quotes
      Integer,Intent(Out)::Int_Out
      Real,Intent(Out)::Real_Out
      Character(Len=*),Intent(Out)::Char_Out
      Character(Len=1),Intent(Out)::Type_Out
      Logical,Intent(Out)::Found,EOF,OK
      Integer,Optional::Cursor_Position
!
      Character(Len=512)::String
      Logical::Fail
!
!     Initialize the function value and ICurStart.
!
      If(Present(Cursor_Position)) then
        ICurStart = Cursor_Position
      else
        ICurStart = FileInfo%buffer_cursor
      endIf
!
!     Get the next string from the text file and then determine if it is an
!     integer, real, or character.
!
      Call MQC_Files_Next_String(FileInfo,NDelimiters,Delimit,  &
        Group_Double_Quotes,ICurStart,String,Found,EOF,OK)
      Call MQC_Files_Char_Type(String,Type_Out,Fail)
      OK = .not.Fail
      If(.not.OK) Return
!
!     Using Type_Out, fill the output arguments.
!
      Select Case(Type_Out)
      Case('I')
        Read(String,*) Int_Out
      Case('R')
        Read(String,*) Real_Out
      Case('C')
        Char_Out = Trim(AdjustL(String))
      Case Default
        Fail = .True.
        Return
      End Select
!
      Return
      End Subroutine MQC_Files_Text_File_Read_Next


!
!PROCEDURE MQC_Files_Next_String
      Subroutine MQC_Files_Next_String(FileInfo,NDelimiters,  &
        Delimit,Group_Double_Quotes,Cursor_Position,String,  &
        Found,EOF,OK)
!
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      integer::i,NDelimiters,ICurStart,ICurEnd
      integer,optional::Cursor_Position
      character(len=*),dimension(NDelimiters),intent(in)::Delimit
      logical,intent(in)::Group_Double_Quotes
      Character(Len=*),Intent(InOut)::String
      Logical,Optional,Intent(Out)::Found,EOF,OK
      Logical::MyFound,MyEOF,MyOK
!
!     Initialize the function value and ICurStart.
!
      If(Present(Cursor_Position)) then
        ICurStart = Cursor_Position
      else
        ICurStart = FileInfo%buffer_cursor
      endIf
!
!     Make sure ICurStart is at a non-delimiter character, then find
!     ICurEnd.
!
      MyFound = .False.
      MyOK = .True.
      MyEOF = .False.
      i = 0
      Do While(.not.MyFound.and.MyOK.and..not.MyEOF.and.i.le.1)
        i = i+1
        If(MQC_Files_Delimiter_Test(FileInfo,NDelimiters,  &
          Delimit,Group_Double_Quotes,Cursor_Position=ICurStart))  &
          ICurStart = MQC_Files_Next_NonDelimiter(FileInfo,NDelimiters,  &
          Delimit,Group_Double_Quotes,ICurStart)
        ICurEnd = MQC_Files_Next_Delimiter(FileInfo,NDelimiters,  &
          Delimit,Group_Double_Quotes,Cursor_Position=ICurStart)
        FileInfo%buffer_cursor = ICurEnd
        ICurEnd = ICurEnd - 1
        MyFound = (ICurStart.gt.0).and.(ICurEnd.gt.0)
        If(.not.MyFound) then
          MyOK = .not.MQC_Files_Load_Buffer(FileInfo,MyEOF)
          ICurStart = 1
        endIf
      EndDo
!
!     Take care of String.
!
      String = ''
      If(MyFound) String = FileInfo%buffer(ICurStart:ICurEnd)
!
!     If requested by the calling program unit, return Cursor_Start,
!     Cursor_End, and Found.
!
      If(Present(Found)) Found = MyFound
      If(Present(EOF)) EOF = MyEOF
      If(Present(OK)) OK = MyOK
!
      Return
      End Subroutine MQC_Files_Next_String


!
!PROCEDURE MQC_Files_Char_Type
      Subroutine MQC_Files_Char_Type(Char_Temp,Type_Char_In,fail)
!
!     This routine takes a character variable in (Char_In) and then
!     determines whether this character variable is storing a real number,
!     integer number, or character string.  The result of this test is
!     returned in Char_In, which is a character variable.  If Char_In
!     contains a real number, Type_Char_In returns 'R'; if Char_In contains
!     an integer number, Type_Char_In returns 'I'; and if Char_In contains
!     a character string, Type_Char_In returns 'C'.
!
!
!     Variable Declarations
      implicit none
!
!     Dummy Variables
!
      character(len=*),intent(in)::Char_Temp
      character(len=1),intent(out)::Type_Char_In
      logical,intent(out)::fail
!
!     Local Variables
!
      integer::i,Int_Temp,Len_Char_In
      integer::Num_Decimal,Num_Digits,Num_Exp,Num_NonDigits
      character(len=LEN(Char_Temp))::Char_In
!
!     Char_In       - This is the left-justified version of Char_Temp.
!     Char_Temp     - This is the character variable sent to this routine.
!     fail          - This is a logical failure flag variable.
!     i             - This is a counter variable.
!     Int_Temp      - This is a temparaty integer variable.
!     Len_Char_In   - This is the length of Char_In.
!     Num_Decimal   - This is the number of decimal points/periods present
!                     in Char_In.
!     Num_Digits    - This is the number of digits (including any '+' or
!                     '-' in position 1) present in Char_In.
!     Num_Exp       - This is the number of exponential symbols ('E' or
!                     'D') in a string that is thus far determined to be a
!                     real number.
!     Num_NonDigits - This is the number of non-digits, excluding '+' at
!                     the start, '-' at the start, or '.' anywhere in
!                     Char_In.
!     Type_Char_In  - This is the character variable that is returned from
!                     this routine.  Type_Char_In flags for the data type
!                     of Char_In (for real number Type_Char_In = 'R'; for
!                     integer number Type_Char_In = 'I'; for character
!                     Type_Char_In = 'C').
!
!
!     Initialize fail.
!
      fail = .False.
!
!     Initialize some local variables and make Char_In left justified.
!
      Len_Char_In = Len_Trim(Char_Temp)
      Type_Char_In = ' '
      Num_Decimal = 0
      Num_Digits = 0
      Num_Exp = 0
      Num_NonDigits = 0
      Char_In = ADJUSTL(Char_Temp)
!
!     Check each character position in Char_In to see if it is a decimal
!     point, digit, or non-digit.  Special care is taken with the first
!     position (after making Char_In left justified), to make sure that
!     '.', '+', or '-' do not make a real or integer number treated as a
!     character type.
!
      Select Case(IAChar(Char_In(1:1)))
      case(IAChar('0'):IAChar('9'))
        Num_Digits = Num_Digits+1
      case(IAChar('+'))
        Num_Digits = Num_Digits+1
      case(IAChar('-'))
        Num_Digits = Num_Digits+1
      case(IAChar('.'))
        Num_Decimal = Num_Decimal+1
      case default
        Num_NonDigits = Num_NonDigits+1
      end select 
!
      do i = 2,Len_Char_In
        Select Case(IAChar(Char_In(i:i)))
        case(IAChar('0'):IAChar('9'))
          Num_Digits = Num_Digits+1
        case(IAChar('.'))
          Num_Decimal = Num_Decimal+1
        case(IAChar('E'))
          if(Num_Decimal.gt.0) then
            Num_Exp = Num_Exp+1
          else
            Num_NonDigits = Num_NonDigits+1
          endif
        case(IAChar('D'))
          if(Num_Decimal.gt.0) then
            Num_Exp = Num_Exp+1
          else
            Num_NonDigits = Num_NonDigits+1
          endif
        case(IAChar('+'))
          if(Num_Exp.eq.1) then
            Num_Digits = Num_Digits+1
          else
            Num_NonDigits = Num_NonDigits+1
          endif
        case(IAChar('-'))
          if(Num_Exp.eq.1) then
            Num_Digits = Num_Digits+1
          else
            Num_NonDigits = Num_NonDigits+1
          endif
        case default
          Num_NonDigits = Num_NonDigits+1
        end select
      enddo
!
      if(Num_NonDigits.gt.0 .or. Num_Decimal.gt.1) then
        Type_Char_In = 'C'
      elseif(Num_Decimal.eq.1) then
        Type_Char_In = 'R'
      elseif(Num_Decimal.eq.0) then
        Type_Char_In = 'I'
      else
        fail = .true.
        Return
      endif
!
      Return
      End Subroutine MQC_Files_Char_Type


!
!PROCEDURE MQC_Files_Load_Buffer
      Logical Function MQC_Files_Load_Buffer(FileInfo,EOF)
!
!     This routine is used to load a text file buffer for the file
!     described by input dummy argument/object FileInfo. If there is an
!     error loading the FF Buffer, then MQC_Files_Load_Buffer returns
!     .TRUE. as its result.  Otherwise, .FALSE. is returned.
!
!
!     Variable Declarations
!
!     Dummy variables
!
      Class(MQC_Text_FileInfo),intent(InOut)::FileInfo
      logical,intent(out),optional::EOF
!
!     Local variables
!
      integer::ierror
!
!
!     Start by setting the function value to .FALSE. and ensuring that
!     FileInfo has been connected to a file.
!
      MQC_Files_Load_Buffer = .False.
      If(Present(EOF)) EOF = .False.
      If(FileInfo%UnitNumber.le.0) then
        MQC_Files_Load_Buffer = .True.
        FileInfo%buffer = ' '
        FileInfo%buffer_caps = ' '
        FileInfo%buffer_loaded = .False.
        Return
      EndIf
!
!     Ensure that buffer_loaded is set and then reset the buffer cursor and
!     then fill the buffer.
!
      FileInfo%buffer_loaded = .True.
      FileInfo%buffer_cursor = 1
      Read(Unit=FileInfo%UnitNumber,fmt='(A)',iostat=ierror)  &
        FileInfo%buffer
      FileInfo%buffer_caps = FileInfo%buffer
!hph      Call Char_Change_Case(.True.,FileInfo%buffer_caps)
      call String_Change_Case(FileInfo%buffer_caps,'U')
      If((ierror.ne.0).or.(Len(Trim(FileInfo%buffer)).eq.0)) then
        If(Present(EOF)) then
          EOF = (ierror.lt.0).or.(Len(Trim(FileInfo%buffer)).eq.0)
          If(ierror.gt.0) MQC_Files_Load_Buffer = .True.
        else
          MQC_Files_Load_Buffer = .True.
        endIf
        FileInfo%buffer = ' '
        FileInfo%buffer_caps = ' '
      endIf
!
      Return
      End


!
!PROCEDURE MQC_Files_Delimiter_Test
      Logical Function MQC_Files_Delimiter_Test(FileInfo,NDelimiters,  &
        Delimit,Group_Double_Quotes,Which_Delimiter,Cursor_Position)
!
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      integer::i,NDelimiters,ICur
      integer,optional::Which_Delimiter,Cursor_Position
      character(len=*),dimension(NDelimiters),intent(in)::Delimit
      logical,intent(in)::Group_Double_Quotes
!
!     Initialize the function value, Which_Delimiter, and ICur.
!
      MQC_Files_Delimiter_Test = .False.
      If(Present(Which_Delimiter)) Which_Delimiter = 0
      If(Present(Cursor_Position)) then
        ICur = Cursor_Position
      else
        ICur = FileInfo%buffer_cursor
      endIf
!
!     If Group_Double_Quotes is .TRUE., check if we have hit a set of
!     quotes or if we are still inside of a set of quotes.  If so, always
!     return .FALSE.
!
      If(Group_Double_Quotes) then
        If(IAChar(FileInfo%buffer(ICur:ICur)).eq.34)  &
          FileInfo%Inside_Quotes = .not.FileInfo%Inside_Quotes
        If(FileInfo%Inside_Quotes) Return
      endIf
!
!     Check to see if we have moved beyond the end of the buffer or hit a
!     delimiter.
!
      If(ICur.gt.Len(Trim(FileInfo%buffer))) then
        MQC_Files_Delimiter_Test = .True.
        Return
      endIf
      Do i = 1,NDelimiters
        If(FileInfo%buffer(ICur:ICur).eq.Delimit(i)) then
          MQC_Files_Delimiter_Test = .True.
          If(Present(Which_Delimiter)) Which_Delimiter = i
          Return
        endIf
      EndDo
!
      Return
      End Function MQC_Files_Delimiter_Test


!
!PROCEDURE MQC_Files_Next_Delimiter
      Integer Function MQC_Files_Next_Delimiter(FileInfo,NDelimiters,  &
        Delimit,Group_Double_Quotes,Which_Delimiter,Cursor_Position)
!
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      integer::i,NDelimiters,ICur
      integer,optional::Which_Delimiter,Cursor_Position
      character(len=*),dimension(NDelimiters),intent(in)::Delimit
      logical,intent(in)::Group_Double_Quotes
      Logical::Done
!
!     Initialize the function value, Which_Delimiter, and ICur.
!
      If(Present(Which_Delimiter)) Which_Delimiter = 0
      If(Present(Cursor_Position)) then
        ICur = Cursor_Position
      else
        ICur = FileInfo%buffer_cursor
      endIf
!
!     March through the buffer undtil we find the next delimiter.
!
      Done = .False.
      Do While(.not.Done.and.ICur.le.Len(Trim(FileInfo%buffer)))
        ICur = ICur + 1
        Done = MQC_Files_Delimiter_Test(FileInfo,NDelimiters,  &
          Delimit,Group_Double_Quotes,Which_Delimiter,ICur)
      EndDo
      MQC_Files_Next_Delimiter = ICur
!
      Return
      End Function MQC_Files_Next_Delimiter


!
!PROCEDURE MQC_Files_Next_NonDelimiter
      Integer Function MQC_Files_Next_NonDelimiter(FileInfo,NDelimiters,  &
        Delimit,Group_Double_Quotes,Cursor_Position)
!
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      integer::i,NDelimiters,ICur
      integer,optional::Cursor_Position
      character(len=*),dimension(NDelimiters),intent(in)::Delimit
      logical,intent(in)::Group_Double_Quotes
      Logical::Done
!
!     Initialize the function value and ICur.
!
      If(Present(Cursor_Position)) then
        ICur = Cursor_Position
      else
        ICur = FileInfo%buffer_cursor
      endIf
!
!     March through the buffer undtil we find the next delimiter.
!
      Done = .False.
      Do While(.not.Done.and.ICur.lt.Len(Trim(FileInfo%buffer)))
        ICur = ICur + 1
        Done = .not.MQC_Files_Delimiter_Test(FileInfo,NDelimiters,  &
          Delimit,Group_Double_Quotes,Cursor_Position=ICur)
      EndDo
      If(Done) then
        MQC_Files_Next_NonDelimiter = ICur
      else
        MQC_Files_Next_NonDelimiter = 0
      endIf
!
      Return
      End Function MQC_Files_Next_NonDelimiter


!
!PROCEDURE MQC_Files_FF_Search
      Subroutine MQC_Files_FF_Search(fail,FileInfo,Search_String,  &
        CaseSensitive,Move_FF_Pointer,EOF)
!
!     This routine is used to search for a line in a file that contains the
!     string given by Search_String. If the line is NOT found, then fail is
!     returned as TRUE. If this routine fails for any other reason, fail is
!     also returned as TRUE. If all goes well, fail is returned as FALSE.
!
!     The argument input dummy argument FileInfo is the MCQ_Text_FileInfo
!     object with information for the file being searched.
!
!     If the INPUT dummy arcument CaseSensitive is TRUE, the search is
!     carried out in a case-sensitive fashion. If CaseSensitive is FALSE,
!     the search is carried out in a case-insensitive fashion.
!
!     The argument Move_FF_Pointer is OPTIONAL. If Move_FF_Pointer is TRUE,
!     then the FF_Buffer pointer is moved to the character immediately
!     following the end of the string in Search_String. Otherwise, the
!     pointed is left at the start of the FF buffer. If Move_FF_Buffer is
!     NOT sent, the it is taken to be FALSE. by default.
!
!     The argument EOF is OPTIONAL. If the end of file is reached then EOF
!     will be returned as TRUE. If the end of file is reached, but EOF is
!     NOT send then fail will be returned as TRUE.
!
!
!     Variable Declarations
!
!     Required Arguments
      implicit none
      Class(MQC_Text_FileInfo),Intent(InOut)::FileInfo
      character(LEN=*),intent(in)::Search_String
      logical,intent(out)::fail
      logical,intent(in)::CaseSensitive
!
!     OPTIONAL Arguments
      logical,OPTIONAL,intent(in)::Move_FF_Pointer
      logical,OPTIONAL,intent(out)::EOF
!
!     Local Arguments
      integer::IPointer,IUnit_Local
      logical::EOF_Local,Move_FF_Pointer_Local
      character(LEN=512)::Temp_Search_String
!
!
!     Begin by initializing fail.  Also, fill IUnit_Local and
!     Move_FF_Pointer_Local.
!
      fail = .False.
      if(Present(Move_FF_Pointer)) then
        Move_FF_Pointer_Local = Move_FF_Pointer
      else
        Move_FF_Pointer_Local = .False.
      endif
!
!     Now, run through the file - line by line - until we find the value in
!     Search_String.
!
      Do
        fail = MQC_Files_Load_Buffer(FileInfo,EOF_Local)
        If(fail .or. EOF_Local) then
          If(EOF_Local .and. Present(EOF)) then
            EOF = .True.
            Return
          elseIf(Present(EOF)) then
            EOF = .False.
            fail = .True.
          else
            fail = .True.
          endIf
          Return
        endIf
        If(CaseSensitive) then
          IPointer = Index(TRIM(FileInfo%buffer),TRIM(Search_String))
        else
          Temp_Search_String = Search_String
!hph          Call Char_Change_Case(.True.,Temp_Search_String)
          call String_Change_Case(Temp_Search_String,'U')
          IPointer = Index(TRIM(FileInfo%buffer_caps),TRIM(Temp_Search_String))
        endIf
        If(IPointer.ne.0) exit
      endDo
!
!     If requested, move the FF buffer pointer to the position after the
!     end of the search string.
!
      If(Move_FF_Pointer_Local.and..not.fail)  &
        FileInfo%buffer_cursor = IPointer + LEN_TRIM(Search_String)
!
      Return
      End Subroutine MQC_Files_FF_Search


!
!PROCEDURE MQC_Files_Test_File_Write_Line
      Subroutine MQC_Files_Text_File_Write_Line(FileInfo,Line)
!
!     This routine is used to write a line to a text file.
!
!
!     Variable Declarations
!
!     Dummy variables
!
      Class(MQC_Text_FileInfo),intent(InOut)::FileInfo
      Character(Len=*),intent(in)::Line
!
!     Write out the line.
!
      write(*,*)' Hrant - Unit number is ',FileInfo%UnitNumber
      write(*,*)' Hrant - Trying to write line: ',TRIM(line)
      write(FileInfo%UnitNumber,'(A)') TRIM(Line)
!
      Return
      End


      End Module MQC_Files
