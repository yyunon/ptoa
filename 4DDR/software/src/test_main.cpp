// Copyright 2021 Delft University of Technology
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include "lib.h"

// Entry point for simulation.
extern "C" void test_main(uint32_t *exit_code) {
  const char *env = getenv("FLETCHER_AWS_ARGV");
  size_t envl = env ? strlen(env) : 0;
  size_t argv_data_sz = 17 + envl + 2;
  char *argv_data = (char*)malloc(argv_data_sz);
  memset(argv_data, 0, argv_data_sz);
  strcpy(argv_data, "fletcher_aws_sim"); // 16 chars + \0
  int argc = 1;
  if (env && env[0]) {
    strcpy(argv_data + 17, env);
    argc = 2;
    for (char *c = argv_data + 17; c < argv_data + argv_data_sz - 2; c++) {
      if (*c == ':' || c == '\0') {
        argc++;
        *c = '\0';
      }
    }
  }
  char **argv = (char**)malloc(sizeof(char*) * (argc + 1));
  size_t argi = 0;
  argv[argi++] = argv_data;
  for (size_t i = 0; argi < argc; i++) {
    if (argv_data[i] == '\0') {
      argv[argi++] = argv_data + i + 1;
    }
  }
  argv[argi] = 0;
  int retval = host_main(argc, argv, true);
  if (exit_code) *exit_code = (uint32_t)retval;
  free(argv_data);
  free(argv);
}
