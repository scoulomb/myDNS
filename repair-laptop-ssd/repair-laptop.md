# Repair HP Laptop

## Issue 

My HP laptop stop working.
Laptop was turned on and displayed a screen error.
Making a fresh install results in an error.
Some days before the issue the hard drive wa making noise.
In start-up diagnostic tool, short DST test was failing sporadically.

## Change or repair

On Darty market place there is some affordable Dell laptop for 300-400 euros.
However there would not be a big performance gap.
Laptop was born in 2013 (according to diagnostic tool `esc`, `F1`, system information)

My needs is a web browser, and some programming tool like Minikube, Python,
Thus  decided to repair the laptop and replace the HDD by SSD.


## Prerequisites

I bought for ~35 euros (ten times cheaper than a new laptop)
- [An opening tool](https://www.amazon.fr/gp/product/B00NCFIVH4/ref=ppx_yo_dt_b_asin_title_o01_s02?ie=UTF8&psc=1)
- [Crucial SSD Interne BX500](120 Go, 3D NAND, SATA, 2,5 pouces) (https://www.amazon.fr/gp/product/B07G3L3DRK/ref=ppx_yo_dt_b_asin_title_o01_s01?ie=UTF8&psc=1)

## Replacing the Hard drive

### Sources

I followed [ifixit tutorial](https://www.ifixit.com/Guide/HP+Pavilion+Sleekbook+15-b142dx+Hard+Drive+Replacement/37449#)
It is not mentioned but we should removed all the screws !!

This video on [youtube](https://www.youtube.com/watch?v=wsGItvoqMvE&t=674s) is also excellent.

### Steps

![Step 1](./pictures/montage1.jpg)

![Step 2](./pictures/montage2.jpg)

![Step 3](./pictures/montage3.jpg)

![Step 4](./pictures/montage4.jpg)

![Step 5](./pictures/montage5.jpg)

![Step 6](./pictures/montage6.jpg)

## Make a Ubuntu bootable USB stick

- [Downlaod ubuntu 20.04 LTS](https://ubuntu.com/download/desktop)
- Make USB drive using Rufus as described [here](https://ubuntu.com/tutorials/tutorial-create-a-usb-stick-on-windows?_ga=2.247769986.484999874.1590064086-738814981.1584441798#10-installation-complete)

## Setup OS on the laptop with the new hard drive


Here was my biggest issue.
`ESC`, `F9` for boot device options was selected but ignored.
It is going to a `grub` bash like.
I can not access the BIOS.

### Some hints

I did not find any documentation with a clear solution.
Here is what helped me:
- [Ubuntu doc](https://help.ubuntu.com/community/BootFromUSB)

````buildoutcfg
grub> root (hd1,0)   # second hard drive usually is the USB drive if you have only one internal drive
grub> find /[tab]
 Possible files are: ldlinux.sys mydoc myfile mystick syslinux.cfg  # Bingo, that's the USB stick
chainloader +1
boot
````

On my setup this was not working and probably because I am in `EFI` mode.
I realized that root is not working on my setup and I should use `set root='(hd1,gpt1)` based on this SO [question](https://unix.stackexchange.com/questions/474312/error-hd1-gpt2-not-found).


- [Manjaro Linux Forum](https://forum.manjaro.org/t/detecting-efi-files-and-booting-them-from-grub/38083)

````buildoutcfg
insmod fat
insmod chain
search -f /efi/manjaro/grubx64.efi --set=root
chainloader /efi/manjaro/grubx64.efi
boot
````

Combining the 2 leads to this solution proposal.

 
### Solution

#### Magic grub command

![Step 1](./pictures/setup1.jpg)

````shell script
# Show all the drive
grub> ls

# Unplug live USB to detect which drive is the Live USB
grub> ls

# This will cause a reading sector error on the drive which is the live USB
# Now we know the live USB is (hd0)
# PLug the USB key
# Doing ls (hd0) leads to unknow file system
# ls (hd0,msdos1)/ show live USB content

grub > set root=(hd0,msdos1) # This is not optional otherwise error

grub > chainloader (hd0,msdos1)/efi/boot/BOOTx64.efi
grub > boot
````

Tips: if you have q qwery keybaord use it :)

#### Nexts

This will start diagnostic and setup screen. As shown in the video [here](https://photos.google.com/photo/AF1QipNO36jxwfN2lD1MG8AxkP4I0t34ntT8IFYinkKf).
(all medias are copied locally except this video, order is respected)

![Step 2](./pictures/setup2.jpg)

I format all my drive because of the mess by using partition table

![Step 3](./pictures/setup3.jpg)

You may have to restart a new setup and repeat command above again

![Step 4](./pictures/setup4.jpg)

After that, it starts diagnostic (as in the video, it is a second time) and we reach setup screen

![Step 5](./pictures/setup5.jpg)

And we setup Ubuntu on the SSD (we can see a 120 gb drive along with a 32gb which was initially used by HP for Windows restore partition)

![Step 6](./pictures/setup6.jpg)


At every startup note HP logo is now present,
 