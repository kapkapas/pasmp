program rootandchildren;
{$ifdef fpc}
 {$mode delphi}
{$endif}
{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  PasMP in '..\..\src\PasMP.pas';

const N=32;

var FakeAtomicOperationMutex:TPasMPMutex;
    Sum:longint;

procedure RootJobFunction(const Job:PPasMPJob;const ThreadIndex:longint);
begin
 // Dunmy empty job function
end;

procedure ChildJobFunction(const Job:PPasMPJob;const ThreadIndex:longint);
begin
 FakeAtomicOperationMutex.Acquire;
 try
  writeln(InterlockedIncrement(Sum),' from thread #',ThreadIndex);
 finally
  FakeAtomicOperationMutex.Release;
 end;
 Sleep(100); // simulate some workload
end;

var RootJob,ChildJob:PPasMPJob;
    i:longint;
begin

 TPasMP.CreateGlobalInstance;

 Sum:=0;

 FakeAtomicOperationMutex:=TPasMPMutex.Create;
 try
  RootJob:=GlobalPasMP.Acquire(RootJobFunction);
  for i:=1 to N do begin
   GlobalPasMP.Run(GlobalPasMP.Acquire(ChildJobFunction,nil,RootJob));
  end;
  GlobalPasMP.Run(RootJob);
  GlobalPasMP.Wait(RootJob);
  GlobalPasMP.Reset; // <= Release all aquired jobs and do the resized pool memory allocator garbage collector if needed
 finally
  FakeAtomicOperationMutex.Free;
 end;

 writeln(Sum,' should be ',N);

 readln;

end.
