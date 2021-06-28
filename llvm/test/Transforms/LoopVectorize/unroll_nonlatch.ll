; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt %s -S -loop-vectorize -force-vector-interleave=2 | FileCheck %s

; Demonstrate a case where we unroll a loop, but don't vectorize it.
; This currently reveals a miscompile.  The original loop runs stores in
; the latch block on iterations 0 to 1022, and exits when %indvars.iv = 1023.
; Currently, the unrolled loop produced by the vectorizer runs the iteration
; where %indvar.iv = 1023 in the vector.body loop before exiting.  This results
; in an out of bounds access..

define void @test(double* %data) {
; CHECK-LABEL: @test(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 false, label [[SCALAR_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[INDUCTION:%.*]] = add i64 [[INDEX]], 0
; CHECK-NEXT:    [[INDUCTION1:%.*]] = add i64 [[INDEX]], 1
; CHECK-NEXT:    [[TMP0:%.*]] = shl nuw nsw i64 [[INDUCTION]], 1
; CHECK-NEXT:    [[TMP1:%.*]] = shl nuw nsw i64 [[INDUCTION1]], 1
; CHECK-NEXT:    [[TMP2:%.*]] = or i64 [[TMP0]], 1
; CHECK-NEXT:    [[TMP3:%.*]] = or i64 [[TMP1]], 1
; CHECK-NEXT:    [[TMP4:%.*]] = getelementptr inbounds double, double* [[DATA:%.*]], i64 [[TMP2]]
; CHECK-NEXT:    [[TMP5:%.*]] = getelementptr inbounds double, double* [[DATA]], i64 [[TMP3]]
; CHECK-NEXT:    [[TMP6:%.*]] = load double, double* [[TMP4]], align 8
; CHECK-NEXT:    [[TMP7:%.*]] = load double, double* [[TMP5]], align 8
; CHECK-NEXT:    [[TMP8:%.*]] = fneg double [[TMP6]]
; CHECK-NEXT:    [[TMP9:%.*]] = fneg double [[TMP7]]
; CHECK-NEXT:    store double [[TMP8]], double* [[TMP4]], align 8
; CHECK-NEXT:    store double [[TMP9]], double* [[TMP5]], align 8
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 2
; CHECK-NEXT:    [[TMP10:%.*]] = icmp eq i64 [[INDEX_NEXT]], 1024
; CHECK-NEXT:    br i1 [[TMP10]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 1024, 1024
; CHECK-NEXT:    br i1 [[CMP_N]], label [[FOR_END:%.*]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ 1024, [[MIDDLE_BLOCK]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[INDVARS_IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[SCALAR_PH]] ], [ [[INDVARS_IV_NEXT:%.*]], [[FOR_LATCH:%.*]] ]
; CHECK-NEXT:    [[INDVARS_IV_NEXT]] = add nuw nsw i64 [[INDVARS_IV]], 1
; CHECK-NEXT:    [[EXITCOND_NOT:%.*]] = icmp eq i64 [[INDVARS_IV_NEXT]], 1024
; CHECK-NEXT:    br i1 [[EXITCOND_NOT]], label [[FOR_END]], label [[FOR_LATCH]]
; CHECK:       for.latch:
; CHECK-NEXT:    [[T15:%.*]] = shl nuw nsw i64 [[INDVARS_IV]], 1
; CHECK-NEXT:    [[T16:%.*]] = or i64 [[T15]], 1
; CHECK-NEXT:    [[ARRAYIDX:%.*]] = getelementptr inbounds double, double* [[DATA]], i64 [[T16]]
; CHECK-NEXT:    [[T17:%.*]] = load double, double* [[ARRAYIDX]], align 8
; CHECK-NEXT:    [[FNEG:%.*]] = fneg double [[T17]]
; CHECK-NEXT:    store double [[FNEG]], double* [[ARRAYIDX]], align 8
; CHECK-NEXT:    br label [[FOR_BODY]], !llvm.loop [[LOOP2:![0-9]+]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %for.body

for.body:
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.latch ]
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, 1024
  br i1 %exitcond.not, label %for.end, label %for.latch

for.latch:
  %t15 = shl nuw nsw i64 %indvars.iv, 1
  %t16 = or i64 %t15, 1
  %arrayidx = getelementptr inbounds double, double* %data, i64 %t16
  %t17 = load double, double* %arrayidx, align 8
  %fneg = fneg double %t17
  store double %fneg, double* %arrayidx, align 8
  br label %for.body

for.end:
  ret void
}