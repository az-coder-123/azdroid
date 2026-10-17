#include <cstdio>

#include "test_harness.h"

int main() {
  int failed_tests = 0;
  for (const auto& test : scrcpy_core_test::Registry()) {
    const int before = scrcpy_core_test::FailureCount();
    test.body();
    const bool passed = scrcpy_core_test::FailureCount() == before;
    std::printf("[%s] %s\n", passed ? " OK " : "FAIL", test.name);
    if (!passed) ++failed_tests;
  }
  std::printf("%zu tests, %d failed\n", scrcpy_core_test::Registry().size(),
              failed_tests);
  return failed_tests == 0 ? 0 : 1;
}
