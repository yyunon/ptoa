#include "ptoa.h"

namespace ptoa {

std::shared_ptr<arrow::RecordBatch> prepareRecordBatch(uint32_t num_val) {
  std::shared_ptr<arrow::Buffer> values;

  arrow::Result<std::shared_ptr<arrow::Buffer>> bufResult =
      arrow::AllocateBuffer(sizeof(int64_t) * num_val);
  if (bufResult.ok()) {
    values = bufResult.ValueOrDie();
  } else {
    throw std::runtime_error("Could not allocate values buffer.");
  }

  auto array =
      std::make_shared<arrow::Int64Array>(arrow::int64(), num_val, values);

  //  This function no longer exists, not sure if passing meta data is necessary
  //  auto schema_meta = metaMode(fletcher::Mode::WRITE);
  std::shared_ptr<arrow::Schema> schema = arrow::schema(
      {arrow::field("int", arrow::int64(), false)}); //, schema_meta);

  auto rb = arrow::RecordBatch::Make(schema, num_val, {array});

  return rb;
}

void setPtoaArguments(std::shared_ptr<fletcher::Platform> platform,
                      uint32_t num_val, uint64_t max_size,
                      da_t device_parquet_address) {
  dau_t mmio64_writer;

  platform->WriteMMIO(REG_BASE + 0, num_val);

  mmio64_writer.full = device_parquet_address;
  platform->WriteMMIO(REG_BASE + 1, mmio64_writer.lo);
  platform->WriteMMIO(REG_BASE + 2, mmio64_writer.hi);

  mmio64_writer.full = max_size;
  platform->WriteMMIO(REG_BASE + 3, mmio64_writer.lo);
  platform->WriteMMIO(REG_BASE + 4, mmio64_writer.hi);

  return;
}

void checkMMIO(std::shared_ptr<fletcher::Platform> platform, uint32_t num_val) {
  uint32_t value32;

  platform->ReadMMIO(REG_BASE + 0, &value32);

  std::cout << "MMIO num_val=" << value32 << ", should be " << num_val
            << std::endl;

  for (int i = 0; i < 15; i++) {
    platform->ReadMMIO(i, &value32);
  }
}
// Use standard Arrow library functions to read Arrow array from Parquet file
// Only works for Parquet version 1 style files.
std::shared_ptr<arrow::ChunkedArray> readArray(std::string hw_input_file_path) {
  std::shared_ptr<arrow::io::ReadableFile> infile;
  arrow::Result<std::shared_ptr<arrow::io::ReadableFile>> result =
      arrow::io::ReadableFile::Open(hw_input_file_path);
  if (result.ok()) {
    infile = result.ValueOrDie();
  } else {
    printf("Error opening Parquet file: code %d, error message: %s\n",
           (int)result.status().code(), result.status().message().c_str());
    exit(-1);
  }

  std::unique_ptr<parquet::arrow::FileReader> reader;
  parquet::arrow::OpenFile(infile, arrow::default_memory_pool(), &reader);

  std::shared_ptr<arrow::ChunkedArray> array;
  reader->ReadColumn(0, &array);

  return array;
}

} // namespace ptoa