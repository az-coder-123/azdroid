// Minimal dependency-free test harness, so the core builds and runs with any
// C++17 compiler (clang on macOS/Linux, MSVC on Windows) without googletest.
#ifndef SCRCPY_CORE_TEST_HARNESS_H_
#define SCRCPY_CORE_TEST_HARNESS_H_

#include <cstdio>
#include <functional>
#include <string>
#include <vector>

namespace scrcpy_core_test {

struct TestCase {
  const char* name;
  std::function<void()> body;
};

inline std::vector<TestCase>& Registry() {
  static std::vector<TestCase> tests;
  return tests;
}

inline int& FailureCount() {
  static int failures = 0;
  return failures;
}

struct Registrar {
  Registrar(const char* name, std::function<void()> body) {
    Registry().push_back({name, std::move(body)});
  }
};

inline void ReportFailure(const char* file, int line, const std::string& what) {
  std::printf("  FAILED %s:%d: %s\n", file, line, what.c_str());
  ++FailureCount();
}

}  // namespace scrcpy_core_test

#define SCRCPY_TEST(name)                                              \
  static void name();                                                  \
  static const ::scrcpy_core_test::Registrar name##_registrar(#name, name); \
  static void name()

#define EXPECT_TRUE(cond)                                                \
  do {                                                                   \
    if (!(cond)) {                                                       \
      ::scrcpy_core_test::ReportFailure(__FILE__, __LINE__, #cond);      \
    }                                                                    \
  } while (0)

#define EXPECT_EQ(actual, expected)                                      \
  do {                                                                   \
    if (!((actual) == (expected))) {                                     \
      ::scrcpy_core_test::ReportFailure(__FILE__, __LINE__,              \
                                        #actual " == " #expected);       \
    }                                                                    \
  } while (0)

#endif  // SCRCPY_CORE_TEST_HARNESS_H_
