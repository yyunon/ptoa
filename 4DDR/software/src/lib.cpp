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

#include <memory>
#include <iostream>

#include <arrow/api.h>
#include <fletcher/api.h>

#include "lib.h"

#define MAX_STRBUF_SIZE 256
#define NAME_SUFFIX_LENGTH 7 // 000.rb (3 numbers, 3 chars, and a terminator)

int host_main(int argc, char **argv, bool simulating) {

  printf("\n\texample Fletcher AWS runtime\n\n");
  // Check number of arguments.
  if (argc != 4) {
    std::cerr << "Incorrect number of arguments. Usage: \n\texample <recordbatch_basename> "
      << "<nkernels> <nOutputRegisters> [sim]\n"
      << "The recordbatch_basename will be appended with the number 000 - nKernels, "
      << "so if you have 15 kernels you should have recordbatch_basename000.rb up to "
      << "recordbatch_basename015.rb in your working directory." 
      << "nKernels \tThe number of kernels in your hardware design"
      << "nOutputRegisters \tThe number of output (result) registers in your hardware design"
      << std::endl;
    return -1;
  }

  int nKernels = (uint32_t) std::strtoul(argv[2], nullptr, 10);
  int nOutputRegisters= (uint32_t) std::strtoul(argv[3], nullptr, 10);

  std::vector<std::shared_ptr<arrow::RecordBatch>> batches;
  std::shared_ptr<arrow::RecordBatch> number_batch;
  int nameLen = strnlen(argv[1], MAX_STRBUF_SIZE);
  if (nameLen <= 0) {
    std::cerr << "Something is wrong with the recordbatch basename." << std::endl;
    return -1;
  }
  char *nameBuf = (char*)malloc(nameLen + NAME_SUFFIX_LENGTH);
  strncpy(nameBuf, argv[1], nameLen + NAME_SUFFIX_LENGTH);
  nameBuf[nameLen + NAME_SUFFIX_LENGTH] = '\0';//terminate the string

  // Attempt to read the RecordBatches from the supplied argument.
  for (int i = 0; i < nKernels; i++) {
    snprintf(nameBuf + nameLen, MAX_STRBUF_SIZE, "%03d.rb", i);
    fletcher::ReadRecordBatchesFromFile(nameBuf, &batches);
  }

  // RecordBatch should contain exactly one batch.
  if (batches.size() != (uint32_t)nKernels) {
    std::cerr
      << "Your set of files does not contain enough Arrow RecordBatches (" << batches.size()
      << ") for the specified number of kernels (" << nKernels << ")." << std::endl;
    return -1;
  }

  fletcher::Status status;
  std::shared_ptr<fletcher::Platform> platform;
  std::shared_ptr<fletcher::Context> context;

  // Create a Fletcher platform object, attempting to autodetect the platform.
  status = fletcher::Platform::Make(simulating ? "aws_sim" : "aws", &platform);

  if (!status.ok()) {
    std::cerr << "Could not create Fletcher platform." << std::endl;
    return -1;
  }

  // Initialize the platform.
  status = platform->Init();

  if (!status.ok()) {
    std::cerr << "Could not initialize Fletcher platform." << std::endl;
    return -1;
  }

  // Create a context for our application on the platform.
  status = fletcher::Context::Make(&context, platform);

  if (!status.ok()) {
    std::cerr << "Could not create Fletcher context." << std::endl;
    return -1;
  }

  // Queue the recordbatch to our context.
  for (int i = 0; i < nKernels; i++) {
	  status = context->QueueRecordBatch(batches[i]);

	  if (!status.ok()) {
		std::cerr << "Could not queue RecordBatch " << i << " to the context." << std::endl;
		return -1;
	  }
  }

  // "Enable" the context, potentially copying the recordbatch to the device. This depends on your platform.
  // AWS EC2 F1 requires a copy, but OpenPOWER SNAP doesn't.
  context->Enable();

  if (!status.ok()) {
    std::cerr << "Could not enable the context." << std::endl;
    return -1;
  }

  // Create a kernel based on the context.
  fletcher::Kernel kernel(context);

  // Start the kernel.
  status = kernel.Start();

  if (!status.ok()) {
    std::cerr << "Could not start the kernel." << std::endl;
    return -1;
  }

  // Wait for the kernel to finish.
  status = kernel.PollUntilDone();

  if (!status.ok()) {
    std::cerr << "Something went wrong waiting for the kernel to finish." << std::endl;
    return -1;
  }

  // Obtain the return value.
  uint32_t return_value_0;
  uint32_t return_value_1;
  status = kernel.GetReturn(&return_value_0, &return_value_1);

  if (!status.ok()) {
    std::cerr << "Could not obtain the return value." << std::endl;
    return -1;
  }

  // Print the return value.
  std::cout << "Return value: " << *reinterpret_cast<int32_t*>(&return_value_0) << std::endl;

  std::cout << "Output registers: \n" << std::endl;
  for (int i = 0; i < nOutputRegisters; i++) {
    uint64_t value;
    uint64_t offset = FLETCHER_REG_SCHEMA + 2 * context->num_recordbatches() + 2 * context->num_buffers() + i;
    platform->ReadMMIO64(offset, &value);
    value &= 0xffffffff; //the count registers are 32 bits wide, not 64
    std::cout << "Output register " << i << ": " << value  << std::endl;
  }

  return 0;
}
