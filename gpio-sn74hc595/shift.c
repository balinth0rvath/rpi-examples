#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#define GPIO_BASE 0x3F200000
#define PULSE_CLOCK 27
#define LATCH 18
#define SERIAL 17

struct gpio_mem_t
{
	unsigned* map;
	int fd;
};

void set_gpio_on(int, struct gpio_mem_t*);
void set_gpio_off(int, struct gpio_mem_t*);

void pulse_clock(int interval,struct gpio_mem_t* gpio_mem)
{
	set_gpio_on(PULSE_CLOCK, gpio_mem);	
	usleep(interval);
	set_gpio_off(PULSE_CLOCK, gpio_mem);
	usleep(interval);
}

void set_latch(int interval,struct gpio_mem_t* gpio_mem)
{
	
	set_gpio_on(LATCH, gpio_mem);	
	usleep(interval);
	set_gpio_off(LATCH, gpio_mem);
	usleep(interval);
}

void send_sequence(int number,struct gpio_mem_t* gpio_mem, int interval)
{
	for(int i=0;i<8;i++)
	{
		if (number & 0x80)
		{
			set_gpio_on(SERIAL, gpio_mem);
		}
		else
		{
			set_gpio_off(SERIAL, gpio_mem);
		}
		number = number << 1;
		pulse_clock(interval, gpio_mem);
	}
	set_latch(interval, gpio_mem);
}

void set_gpio_output(int gpio, struct gpio_mem_t* gpio_mem)
{
	int gpio_high = (gpio - gpio % 10) / 10;
	int gpio_low = gpio % 10;
	int shift = (gpio_low ) * 3;
	*(gpio_mem->map + gpio_high ) = *(gpio_mem->map + gpio_high ) & ~( 7 << shift);
	*(gpio_mem->map + gpio_high ) = *(gpio_mem->map + gpio_high ) | ( 1 << shift);
}

void set_gpio_on(int gpio, struct gpio_mem_t* gpio_mem)
{
	*(gpio_mem->map + 7) = *(gpio_mem->map + 7) | ( 1 << gpio );
}

void set_gpio_off(int gpio, struct gpio_mem_t* gpio_mem)
{
	*(gpio_mem->map + 10) = *(gpio_mem->map + 10) | (1 << gpio );
}
void run(struct gpio_mem_t* gpio_mem,int interval)
{
	int i=0;
	while(1)
	{
		for(i=0;i<8;i++) 
		{
			send_sequence(1<<i, gpio_mem, interval);	
		}
		for(i=6;i;i--) 
		{
			send_sequence(1<<i, gpio_mem, interval);	
		}
	}
}
int main() 
{
	printf("start...\n");
	struct gpio_mem_t gpio_mem;
	gpio_mem.map = 0;
	gpio_mem.fd = -1;
	gpio_mem.fd = open("/dev/mem", O_RDWR);

	if (gpio_mem.fd==-1)
		printf("Error opening /dev/mem: %i \n", errno);

	gpio_mem.map = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED,gpio_mem.fd, GPIO_BASE);	
	printf("base mem %i \n", gpio_mem.map);
	set_gpio_output(LATCH, &gpio_mem);
	set_gpio_output(SERIAL, &gpio_mem);
	set_gpio_output(PULSE_CLOCK, &gpio_mem);
	set_gpio_off(LATCH, &gpio_mem);
	set_gpio_off(PULSE_CLOCK, &gpio_mem);
 	run(&gpio_mem, 590);
/*
	int interval = 100000;
	int pin = 22;
	set_gpio_output(pin, &gpio_mem);
	set_gpio_on(pin, &gpio_mem);
	usleep(interval);	
	set_gpio_off(pin, &gpio_mem);
	usleep(interval);	
	set_gpio_on(pin, &gpio_mem);
	usleep(interval);	
	set_gpio_off(pin, &gpio_mem);
	usleep(interval);	
*/
}
