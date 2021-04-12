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

#include "ptoa.h"
#include <fletcher/api.h>

#include "fletcher_aws_sim.h"

#include "lib.h"
#include "ptoa.h"
#define MAX_STRBUF_SIZE 256
#define NAME_SUFFIX_LENGTH 7 // 000.rb (3 numbers, 3 chars, and a terminator)

int host_main(int argc, char **argv, bool simulating) {

  printf("\n\tPTOA AWS runtime\n\n");
  // Check number of arguments.
  // TODO: CLI
  const char *hw_input_file_path =
      "/home/yyunon/Datasets/extendedprice.parquet";
  const char *reference_parquet_file_path =
      "/home/yyunon/Datasets/extendedprice.parquet";
  uint32_t num_val = 1;

  uint64_t file_size;
  uint8_t *file_data;

  int nKernels = (uint32_t)std::strtoul(argv[2], nullptr, 10);
  int nOutputRegisters = (uint32_t)std::strtoul(argv[3], nullptr, 10);

  std::vector<std::shared_ptr<arrow::RecordBatch>> batches;
  std::shared_ptr<arrow::RecordBatch> number_batch;
  int nameLen = strnlen(argv[1], MAX_STRBUF_SIZE);
  if (nameLen <= 0) {
    std::cerr << "Something is wrong with the recordbatch basename."
              << std::endl;
    return -1;
  }
  char *nameBuf = (char *)malloc(nameLen + NAME_SUFFIX_LENGTH);
  strncpy(nameBuf, argv[1], nameLen + NAME_SUFFIX_LENGTH);
  nameBuf[nameLen + NAME_SUFFIX_LENGTH] = '\0'; // terminate the string

  // Attempt to read the RecordBatches from the supplied argument.
  for (int i = 0; i < nKernels; i++) {
    snprintf(nameBuf + nameLen, MAX_STRBUF_SIZE, "%03d.rb", i);
    fletcher::ReadRecordBatchesFromFile(nameBuf, &batches);
  }
  // Open parquet file
  std::ifstream parquet_file;
  parquet_file.open(hw_input_file_path, std::ifstream::binary);

  if (!parquet_file.is_open()) {
    std::cerr << "Error opening Parquet file" << std::endl;
    return 1;
  }
  // Get filesize
  parquet_file.seekg(0, parquet_file.end);
  file_size = parquet_file.tellg();
  parquet_file.seekg(0, parquet_file.beg);

  // Read file data
  file_data = (uint8_t *)std::malloc(file_size);
  parquet_file.read((char *)file_data, file_size);
  unsigned int checksum = 0;
  for (int i = 0; i < file_size; i++) {
    checksum += file_data[i];
  }
  printf("Parquet file checksum 0x%lu\n", checksum);

  auto arrow_rb_fpga = ptoa::prepareRecordBatch(num_val);
  auto result_array =
      std::dynamic_pointer_cast<arrow::Int64Array>(arrow_rb_fpga->column(0));
  auto result_buffer_raw_data = result_array->values()->mutable_data();
  auto result_buffer_size = result_array->values()->size();

  // Create platform and context
  fletcher::Status status;
  std::shared_ptr<fletcher::Platform> platform;
  std::shared_ptr<fletcher::Context> context;

  // Create a Fletcher platform object, attempting to autodetect the platform.
  status = fletcher::Platform::Make(simulating ? "aws_sim" : "aws", &platform);

  if (!status.ok()) {
    std::cerr << "Could not create Fletcher platform."
              << "\n";
    return -1;
  }

  // Initialize the platform.
  if (simulating) {
    InitOptions options = {1}; // do not initialize DDR for the 1DDR version
    platform->init_data = &options;
  }

  status = platform->Init();

  if (!status.ok()) {
    std::cerr << "Could not initialize Fletcher platform."
              << "\n";
    return -1;
  }

  // Create a context for our application on the platform.
  status = fletcher::Context::Make(&context, platform);

  if (!status.ok()) {
    std::cerr << "Could not create Fletcher context."
              << "\n";
    return -1;
  }

  // Queue the recordbatch to our context.
  status = context->QueueRecordBatch(arrow_rb_fpga);

  if (!status.ok()) {
    std::cerr << "Could not queue RecordBatch "
              << " to the context."
              << "\n";
    return -1;
  }

  // "Enable" the context, potentially copying the recordbatch to the device.
  // This depends on your platform. AWS EC2 F1 requires a copy, but OpenPOWER
  // SNAP doesn't.
  context->Enable();

  if (!status.ok()) {
    std::cerr << "Could not enable the context."
              << "\n";
    return -1;
  }
  // Malloc device

  da_t device_parquet_address;
  platform->DeviceMalloc(&device_parquet_address, file_size);

  ptoa::setPtoaArguments(platform, num_val, file_size, device_parquet_address);

  // Make sure all buffer memory is allocated
  memset(result_buffer_raw_data, 0, result_buffer_size);
  platform->CopyHostToDevice(file_data, device_parquet_address, file_size);
  // Create a kernel based on the context.
  fletcher::Kernel kernel(context);

  // Start the kernel.
  status = kernel.Start();

  if (!status.ok()) {
    std::cerr << "Could not start the kernel."
              << "\n";
    return -1;
  }

  // Wait for the kernel to finish.
  status = kernel.WaitForFinish();

  if (!status.ok()) {
    std::cerr << "Something went wrong waiting for the kernel to finish."
              << "\n";
    return -1;
  }
  platform->CopyDeviceToHost(context->device_buffer(0).device_address,
                             result_buffer_raw_data, sizeof(int64_t) * num_val);

  size_t total_arrow_size = sizeof(int64_t) * num_val;
  auto correct_array = std::dynamic_pointer_cast<arrow::Int64Array>(
      ptoa::readArray(std::string(reference_parquet_file_path))->chunk(0));
  if (result_array->Equals(correct_array)) {
    std::cout << "Test passed!" << std::endl;
  } else {
    // sometimes, Equals() thinks it failed but checking the arrays does not
    // show errors std::cout << "Test Failed!" << std::endl;
    int error_count = 0;
    for (int i = 0; i < result_array->length(); i++) {
      if (result_array->Value(i) != correct_array->Value(i)) {
        error_count++;
      }
      if (i < 20) {
        std::cout << result_array->Value(i) << " " << correct_array->Value(i)
                  << std::endl;
      }
    }

    if (result_array->length() != num_val) {
      error_count++;
    }

    if (error_count == 0) {
      std::cout << "Test passed!" << std::endl;
    } else {
      std::cout << "Test failed. Found " << error_count
                << " errors in the output Arrow array" << std::endl;
    }
  }

  std::free(file_data);

  return 0;
}
