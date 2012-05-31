#include <assert.h>
#include <stdbool.h>
#include <string.h>
#include "dump_stats.h"

static void test_dump_stats_header_records()
{
  char *input_line = "@PG\tID:bwa\tPN:bwa\tVN:0.5.9-r16\n";
  int pointer_input_line_skip_type = 4;
  char csv[10000]; // the csv results will be here
  int pointer_csv;
  char *expected_output = "PG,ID,bwa,\nPG,PN,bwa,\nPG,VN,0.5.9-r16,\n";

  header_records("PG",
                 input_line,
                 pointer_input_line_skip_type,
                 csv,
                 &pointer_csv);

  /*
  printf("INPUT:\n%s\n", input_line);
  printf("OUTPUT:\n%s\n", csv);
  printf("EXPECTED:\n%s\n", expected_output);
  */
  assert(strcmp(csv, expected_output) == 0 &&
         "test_dump_stats_header_records()");
}

int main(void) {
  test_dump_stats_header_records();
  printf("\nTEST PASSED.\n");
  return 0;
}
