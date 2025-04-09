#include "access.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <sys/ioctl.h>

void print_usage(const char *program_name)
{
	printf("Usage: %s <dev_file_name> <read|write> <register> [<write_value>]\n",
	       program_name);
}
int main(int argc, char **argv)
{
	if (argc < 4) {
		print_usage(argv[0]);
		return EXIT_FAILURE;
	}

	const char *file_name = argv[1];
	const char *op = argv[2];
	const int reg = atoi(argv[3]);
	const bool is_write = strcmp(op, "write") == 0;
	if (is_write && argc < 5) {
		print_usage(argv[0]);
		return EXIT_FAILURE;
	}

	FILE *fp = fopen(file_name, "r+");
	if (!fp) {
		printf("Couldn't open %s (%s)\n", file_name, strerror(errno));
		return EXIT_FAILURE;
	}

	int err = ioctl(fileno(fp), IOCTL_ACCESS_SELECT_REGISTER, reg);
	if (err) {
		printf("Failed to select the register %d\n", reg);
		return EXIT_FAILURE;
	}

	if (is_write) {
		const uint32_t value = atoi(argv[4]);
		printf("W: %#x = %#x\n", reg, value);
		return fwrite(&value, sizeof(value), 1, fp) == sizeof(value) ?
			       EXIT_SUCCESS :
			       EXIT_FAILURE;
	}
	uint32_t value = 0;

	ssize_t bytes_read = fread(&value, 1, sizeof(value), fp);

	if (bytes_read != sizeof(value)) {
		printf("Failed to read register %zu\n", bytes_read);
		return EXIT_FAILURE;
	}

	printf("R: %#x = %#x\n", reg, value);

	return EXIT_SUCCESS;
}
