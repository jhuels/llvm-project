// RUN: %clang_cc1 -S -fno-strict-float-cast-overflow %s -emit-llvm -o - | FileCheck %s --check-prefix=NOSTRICT

// When compiling with non-standard semantics, use intrinsics to inhibit the optimizer.

// NOSTRICT-LABEL: main
// NOSTRICT: call i32 @llvm.fptosi.sat.i32.f64
// NOSTRICT: call i32 @llvm.fptoui.sat.i32.f64
// NOSTRICT: attributes #0 = {{.*}}"strict-float-cast-overflow"="false"{{.*}}

// The workaround attribute is not applied by default.

// RUN: %clang_cc1 -S %s -emit-llvm -o - | FileCheck %s --check-prefix=STRICT
// STRICT-LABEL: main
// STRICT: = fptosi
// STRICT: = fptoui
// STRICT-NOT: strict-float-cast-overflow


int main() {
  double d = 1e20;
  return (int)d != 1e20 && (unsigned)d != 1e20;
}
