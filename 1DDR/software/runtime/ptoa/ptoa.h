/* Holds the helper functions of ptoa .*/
#pragma once

#include <fstream>
#include <iostream>
#include <memory>
// Apache Arrow
#include <arrow/api.h>
#include <arrow/io/api.h>
#include <fletcher/api.h>
#include <parquet/arrow/reader.h>
#include <parquet/arrow/writer.h>

#define REG_BASE 10
#define PRIM_WIDTH 64

namespace ptoa {

std::shared_ptr<arrow::RecordBatch> prepareRecordBatch(uint32_t num_val);
void setPtoaArguments(std::shared_ptr<fletcher::Platform> platform,
                      uint32_t num_val, uint64_t max_size,
                      da_t device_parquet_address);

void checkMMIO(std::shared_ptr<fletcher::Platform> platform, uint32_t num_val);

// Use standard Arrow library functions to read Arrow array from Parquet file
// Only works for Parquet version 1 style files.
std::shared_ptr<arrow::ChunkedArray> readArray(std::string hw_input_file_path);

} // namespace ptoa