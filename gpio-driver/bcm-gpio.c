#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/gpio.h>
#include <asm/io.h>
#include <linux/interrupt.h>
#include <linux/mutex.h>
//#include <mach/platform.h>

/* Per device structure */
struct bcm_gpio_dev {
	char data[3];
	struct cdev cdev;
	char name[10];
	int busy;
	struct mutex lock;   
} * bcm_gpio_devp;

int irq_counter;

static ssize_t bcm_gpio_read(struct file*, char*, size_t, loff_t*);
static ssize_t bcm_gpio_write(struct file *, const char __user *, size_t, loff_t *);
static int bcm_gpio_open(struct inode *, struct file *);
static int bcm_gpio_release(struct inode *, struct file *);

static struct file_operations bcm_gpio_fops = {
	.owner = THIS_MODULE,	/* Owner */
	.read = bcm_gpio_read,
	.write = bcm_gpio_write,
	.open = bcm_gpio_open,
	.release = bcm_gpio_release
};

static dev_t bcm_gpio_device_number;
struct class* bcm_gpio_class;

#define DEVICE_NAME "bcm-gpio-device"

static irqreturn_t gpio_irq_handler(int irq, void* dev_id)
{
	irq_counter++;
	printk(KERN_INFO "GPIO 12 irq handled: %i \n", irq_counter);
	return IRQ_HANDLED;
}

static int __init bcm_gpio_mod_init(void)
{
	int irq_line;

	// allocate chrdev region

	if (alloc_chrdev_region(&bcm_gpio_device_number, 0, 1, DEVICE_NAME))
	{
		printk(KERN_INFO "Cannot allocate region for bcm gpio device");
		return -1;
	}

	// populate sysfs entries 
	bcm_gpio_class = class_create(THIS_MODULE, DEVICE_NAME);
	
	// allocate memory for device structure
	bcm_gpio_devp = kmalloc(sizeof(struct bcm_gpio_dev), GFP_KERNEL);	
;
	if (!bcm_gpio_devp)
	{
		printk(KERN_INFO "Bad kmalloc\n");
		return -1;
	}
	mutex_init(&bcm_gpio_devp->lock);

	if (mutex_lock_interruptible(&bcm_gpio_devp->lock))	
	{
		printk(KERN_INFO "gpio init interrupted \n");
		return -1;
	}
	
	// connect fops with cdev
	cdev_init(&bcm_gpio_devp->cdev, &bcm_gpio_fops);
	bcm_gpio_devp->cdev.owner = THIS_MODULE;
	
	// connect minor major number to cdev
 	if (cdev_add(&bcm_gpio_devp->cdev, bcm_gpio_device_number, 1)) {
		printk(KERN_INFO "cdev add failed\n");
		mutex_unlock(&bcm_gpio_devp->lock);
		return -1;
	}
	
	// send uevent to udev
	device_create(bcm_gpio_class, NULL, bcm_gpio_device_number, NULL, "bcmgpiod");
	
	// setup output pins	
	bcm_gpio_devp->busy=0;
	bcm_gpio_devp->data[0]='0';
	bcm_gpio_devp->data[1]='0';
	bcm_gpio_devp->data[2]='0';

	// set GPIO 12 to input

	if (gpio_direction_input(12)!=0)
	{
		printk(KERN_INFO "Cannot set GPIO 12 to input \n");
		mutex_unlock(&bcm_gpio_devp->lock);
		return -1;
	}

	if (gpio_direction_output(16,1)!=0 ||
		gpio_direction_output(20,1)!=0 ||
		gpio_direction_output(21,1)!=0)
	{
		printk(KERN_INFO "Cannot set GPIO 16 20 21 to output \n");
		mutex_unlock(&bcm_gpio_devp->lock);
		return -1;
	}

	// request irq for GPIO 12

	irq_line = gpio_to_irq(12);
	printk(KERN_INFO "IRQ line for GPIO 12 is %i \n", irq_line);
	
	if (request_irq(irq_line, gpio_irq_handler, IRQF_TRIGGER_FALLING, "Interrupt GPIO 12", NULL)<0)
	{
		printk(KERN_INFO "Cannot get IRQ for GPIO12 \n");
		mutex_unlock(&bcm_gpio_devp->lock);
		return -1;
	}
	
	irq_counter = 0;
	printk(KERN_INFO "bcm gpio device initialized\n");

	mutex_unlock(&bcm_gpio_devp->lock);

	return 0;
}

static void __exit bcm_gpio_mod_exit(void)
{
	// release irq line       
	int irq_line;
	irq_line = gpio_to_irq(12);
	free_irq(irq_line, NULL);

	// remove cdev
	cdev_del(&bcm_gpio_devp->cdev);

	// release major number
	unregister_chrdev_region(bcm_gpio_device_number, 1);

	// destroy device
	device_destroy(bcm_gpio_class, bcm_gpio_device_number);

	// destroy cmos class
	class_destroy(bcm_gpio_class);
	printk(KERN_INFO "bcm gpio exit done\n");

	kfree(bcm_gpio_devp);

	return;
}

static ssize_t bcm_gpio_read(struct file *file, char* buf, size_t count, loff_t * offset)
{
	struct bcm_gpio_dev* bcm_gpio_devp;
	printk(KERN_INFO "bcm gpio read started \n");
	bcm_gpio_devp=file->private_data;
	
	if (mutex_lock_interruptible(&bcm_gpio_devp->lock))	
	{
		printk(KERN_INFO "gpio init interrupted \n");
		return -1;
	} 

	bcm_gpio_devp->data[0] = gpio_get_value(16)+48;
	bcm_gpio_devp->data[1] = gpio_get_value(20)+48;
	bcm_gpio_devp->data[2] = gpio_get_value(21)+48;

	if (copy_to_user(buf, (void*)bcm_gpio_devp->data, 3)!=0)
	{
		return -EIO;
	}
	printk(KERN_INFO "bcm gpio count=%i\n",count);
	if (bcm_gpio_devp->busy) {
		bcm_gpio_devp->busy=0;
		return 0;
	} else
	{
		bcm_gpio_devp->busy=1;
		return 3;
	}	
	mutex_unlock(&bcm_gpio_devp->lock);
	return 3;
}

static ssize_t bcm_gpio_write(struct file * filep, const char __user * userp, size_t size, loff_t * offset)
{
	int i;
	char kbuf[3];
	if (copy_from_user(kbuf, userp, 3)!=0)
		return -EFAULT;
		
	if (mutex_lock_interruptible(&bcm_gpio_devp->lock))	
	{
		printk(KERN_INFO "gpio init interrupted \n");
		return -1;
	} 

	bcm_gpio_devp=filep->private_data;
	for (i=0; i<3; i++)
		bcm_gpio_devp->data[i] = kbuf[i];

	printk(KERN_INFO "kbuf[0] %i \n", kbuf[0]);	
	gpio_set_value(16,(int)(kbuf[0]-48));
	gpio_set_value(20,(int)(kbuf[1]-48));
	gpio_set_value(21,(int)(kbuf[2]-48));

	mutex_unlock(&bcm_gpio_devp->lock);
	return 0;
}

static int bcm_gpio_open(struct inode * node, struct file * file)
{
	struct bcm_gpio_dev *bcm_gpio_devp;
	bcm_gpio_devp = container_of(node->i_cdev, struct bcm_gpio_dev, cdev);
	file->private_data = bcm_gpio_devp;
	printk(KERN_INFO "bcm gpio open done\n");

	return 0;
}

static int bcm_gpio_release(struct inode * node, struct file * file)
{
	printk(KERN_INFO "bcm gpio release done\n");
	return 0;
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("bhorvath");
MODULE_DESCRIPTION("bcm gpio cdev module");

module_init(bcm_gpio_mod_init);
module_exit(bcm_gpio_mod_exit);
 
