#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#define BASE_MEM 0x3F200000
int main() 
{
	volatile unsigned* map;
	int fd = -1;
	fd = open("/dev/mem", O_RDWR);

	if (fd==-1)
	{
		printf("Error opening /dev/mem: %x \n", errno);
		return -1;
	}
	printf("Mapping 4096 bytes at physical %x \n", BASE_MEM);
	//map = (unsigned*)malloc(4096);
	map = (unsigned*)mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED,fd, BASE_MEM);	
	printf("Mapped to virtual %x \n", map);
	
	*(map)= *(map+2) & ~(7 << 6);
	//usleep(1);	
	*(map)= *(map+2) | 1 << 6;
	//usleep(1);
	
	*(map+7)=1 << 22;
	sleep(1);
	*(map+10)=1 << 22;
	sleep(1);

	*(map+7)=1 << 22;
	sleep(1);
	*(map+10)=1 << 22;
	sleep(1);

}

