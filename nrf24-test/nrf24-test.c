#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h> 
#include <unistd.h>
#include "nrf24-test.h"

int main()
{
	int fd = open("/dev/nrf24d", O_RDWR);
	printf("fd: %i \n", fd);
	int ioc = ioctl(fd, 5, 3);
	close(fd);
}
