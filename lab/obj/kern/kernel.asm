
obj/kern/kernel:     формат файла elf32-i386


Дизассемблирование раздела .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 e0 96 11 f0    	mov    $0xf01196e0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 b6 3c 00 00       	call   f0103d1f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 37 05 00 00       	call   f01005a5 <cons_init>

	cprintf("\n6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 54 ce fe ff    	lea    -0x131ac(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 9c 30 00 00       	call   f010311e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 1d 13 00 00       	call   f01013a4 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 5e 08 00 00       	call   f01008f2 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	56                   	push   %esi
f010009d:	53                   	push   %ebx
f010009e:	e8 ac 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a3:	81 c3 69 72 01 00    	add    $0x17269,%ebx
	va_list ap;

	if (panicstr)
f01000a9:	83 bb 54 1d 00 00 00 	cmpl   $0x0,0x1d54(%ebx)
f01000b0:	74 0f                	je     f01000c1 <_panic+0x28>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000b2:	83 ec 0c             	sub    $0xc,%esp
f01000b5:	6a 00                	push   $0x0
f01000b7:	e8 36 08 00 00       	call   f01008f2 <monitor>
f01000bc:	83 c4 10             	add    $0x10,%esp
f01000bf:	eb f1                	jmp    f01000b2 <_panic+0x19>
	panicstr = fmt;
f01000c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01000c4:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	asm volatile("cli; cld");
f01000ca:	fa                   	cli    
f01000cb:	fc                   	cld    
	va_start(ap, fmt);
f01000cc:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000cf:	83 ec 04             	sub    $0x4,%esp
f01000d2:	ff 75 0c             	push   0xc(%ebp)
f01000d5:	ff 75 08             	push   0x8(%ebp)
f01000d8:	8d 83 70 ce fe ff    	lea    -0x13190(%ebx),%eax
f01000de:	50                   	push   %eax
f01000df:	e8 3a 30 00 00       	call   f010311e <cprintf>
	vcprintf(fmt, ap);
f01000e4:	83 c4 08             	add    $0x8,%esp
f01000e7:	56                   	push   %esi
f01000e8:	ff 75 10             	push   0x10(%ebp)
f01000eb:	e8 f7 2f 00 00       	call   f01030e7 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 01 d6 fe ff    	lea    -0x129ff(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 20 30 00 00       	call   f010311e <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb af                	jmp    f01000b2 <_panic+0x19>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	push   0xc(%ebp)
f010011c:	ff 75 08             	push   0x8(%ebp)
f010011f:	8d 83 88 ce fe ff    	lea    -0x13178(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 f3 2f 00 00       	call   f010311e <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	push   0x10(%ebp)
f0100132:	e8 b0 2f 00 00       	call   f01030e7 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 01 d6 fe ff    	lea    -0x129ff(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 d9 2f 00 00       	call   f010311e <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100153:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100158:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100159:	a8 01                	test   $0x1,%al
f010015b:	74 0a                	je     f0100167 <serial_proc_data+0x14>
f010015d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c0             	movzbl %al,%eax
f0100166:	c3                   	ret    
		return -1;
f0100167:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010016c:	c3                   	ret    

f010016d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016d:	55                   	push   %ebp
f010016e:	89 e5                	mov    %esp,%ebp
f0100170:	57                   	push   %edi
f0100171:	56                   	push   %esi
f0100172:	53                   	push   %ebx
f0100173:	83 ec 1c             	sub    $0x1c,%esp
f0100176:	e8 6a 05 00 00       	call   f01006e5 <__x86.get_pc_thunk.si>
f010017b:	81 c6 91 71 01 00    	add    $0x17191,%esi
f0100181:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f0100183:	8d 1d 94 1d 00 00    	lea    0x1d94,%ebx
f0100189:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f010018c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010018f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f0100192:	eb 25                	jmp    f01001b9 <cons_intr+0x4c>
		cons.buf[cons.wpos++] = c;
f0100194:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f010019b:	8d 51 01             	lea    0x1(%ecx),%edx
f010019e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01001a1:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01001af:	0f 44 d0             	cmove  %eax,%edx
f01001b2:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
	while ((c = (*proc)()) != -1) {
f01001b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001bc:	ff d0                	call   *%eax
f01001be:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c1:	74 06                	je     f01001c9 <cons_intr+0x5c>
		if (c == 0)
f01001c3:	85 c0                	test   %eax,%eax
f01001c5:	75 cd                	jne    f0100194 <cons_intr+0x27>
f01001c7:	eb f0                	jmp    f01001b9 <cons_intr+0x4c>
	}
}
f01001c9:	83 c4 1c             	add    $0x1c,%esp
f01001cc:	5b                   	pop    %ebx
f01001cd:	5e                   	pop    %esi
f01001ce:	5f                   	pop    %edi
f01001cf:	5d                   	pop    %ebp
f01001d0:	c3                   	ret    

f01001d1 <kbd_proc_data>:
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	56                   	push   %esi
f01001d5:	53                   	push   %ebx
f01001d6:	e8 74 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001db:	81 c3 31 71 01 00    	add    $0x17131,%ebx
f01001e1:	ba 64 00 00 00       	mov    $0x64,%edx
f01001e6:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001e7:	a8 01                	test   $0x1,%al
f01001e9:	0f 84 f7 00 00 00    	je     f01002e6 <kbd_proc_data+0x115>
	if (stat & KBS_TERR)
f01001ef:	a8 20                	test   $0x20,%al
f01001f1:	0f 85 f6 00 00 00    	jne    f01002ed <kbd_proc_data+0x11c>
f01001f7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001fc:	ec                   	in     (%dx),%al
f01001fd:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001ff:	3c e0                	cmp    $0xe0,%al
f0100201:	74 64                	je     f0100267 <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f0100203:	84 c0                	test   %al,%al
f0100205:	78 75                	js     f010027c <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f0100207:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f010020d:	f6 c1 40             	test   $0x40,%cl
f0100210:	74 0e                	je     f0100220 <kbd_proc_data+0x4f>
		data |= 0x80;
f0100212:	83 c8 80             	or     $0xffffff80,%eax
f0100215:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100217:	83 e1 bf             	and    $0xffffffbf,%ecx
f010021a:	89 8b 74 1d 00 00    	mov    %ecx,0x1d74(%ebx)
	shift |= shiftcode[data];
f0100220:	0f b6 d2             	movzbl %dl,%edx
f0100223:	0f b6 84 13 d4 cf fe 	movzbl -0x1302c(%ebx,%edx,1),%eax
f010022a:	ff 
f010022b:	0b 83 74 1d 00 00    	or     0x1d74(%ebx),%eax
	shift ^= togglecode[data];
f0100231:	0f b6 8c 13 d4 ce fe 	movzbl -0x1312c(%ebx,%edx,1),%ecx
f0100238:	ff 
f0100239:	31 c8                	xor    %ecx,%eax
f010023b:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100241:	89 c1                	mov    %eax,%ecx
f0100243:	83 e1 03             	and    $0x3,%ecx
f0100246:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f010024d:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100251:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100254:	a8 08                	test   $0x8,%al
f0100256:	74 61                	je     f01002b9 <kbd_proc_data+0xe8>
		if ('a' <= c && c <= 'z')
f0100258:	89 f2                	mov    %esi,%edx
f010025a:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f010025d:	83 f9 19             	cmp    $0x19,%ecx
f0100260:	77 4b                	ja     f01002ad <kbd_proc_data+0xdc>
			c += 'A' - 'a';
f0100262:	83 ee 20             	sub    $0x20,%esi
f0100265:	eb 0c                	jmp    f0100273 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f0100267:	83 8b 74 1d 00 00 40 	orl    $0x40,0x1d74(%ebx)
		return 0;
f010026e:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100273:	89 f0                	mov    %esi,%eax
f0100275:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100278:	5b                   	pop    %ebx
f0100279:	5e                   	pop    %esi
f010027a:	5d                   	pop    %ebp
f010027b:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010027c:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f0100282:	83 e0 7f             	and    $0x7f,%eax
f0100285:	f6 c1 40             	test   $0x40,%cl
f0100288:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010028b:	0f b6 d2             	movzbl %dl,%edx
f010028e:	0f b6 84 13 d4 cf fe 	movzbl -0x1302c(%ebx,%edx,1),%eax
f0100295:	ff 
f0100296:	83 c8 40             	or     $0x40,%eax
f0100299:	0f b6 c0             	movzbl %al,%eax
f010029c:	f7 d0                	not    %eax
f010029e:	21 c8                	and    %ecx,%eax
f01002a0:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
		return 0;
f01002a6:	be 00 00 00 00       	mov    $0x0,%esi
f01002ab:	eb c6                	jmp    f0100273 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f01002ad:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002b0:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002b3:	83 fa 1a             	cmp    $0x1a,%edx
f01002b6:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b9:	f7 d0                	not    %eax
f01002bb:	a8 06                	test   $0x6,%al
f01002bd:	75 b4                	jne    f0100273 <kbd_proc_data+0xa2>
f01002bf:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002c5:	75 ac                	jne    f0100273 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f01002c7:	83 ec 0c             	sub    $0xc,%esp
f01002ca:	8d 83 a2 ce fe ff    	lea    -0x1315e(%ebx),%eax
f01002d0:	50                   	push   %eax
f01002d1:	e8 48 2e 00 00       	call   f010311e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d6:	b8 03 00 00 00       	mov    $0x3,%eax
f01002db:	ba 92 00 00 00       	mov    $0x92,%edx
f01002e0:	ee                   	out    %al,(%dx)
}
f01002e1:	83 c4 10             	add    $0x10,%esp
f01002e4:	eb 8d                	jmp    f0100273 <kbd_proc_data+0xa2>
		return -1;
f01002e6:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002eb:	eb 86                	jmp    f0100273 <kbd_proc_data+0xa2>
		return -1;
f01002ed:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002f2:	e9 7c ff ff ff       	jmp    f0100273 <kbd_proc_data+0xa2>

f01002f7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f7:	55                   	push   %ebp
f01002f8:	89 e5                	mov    %esp,%ebp
f01002fa:	57                   	push   %edi
f01002fb:	56                   	push   %esi
f01002fc:	53                   	push   %ebx
f01002fd:	83 ec 1c             	sub    $0x1c,%esp
f0100300:	e8 4a fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100305:	81 c3 07 70 01 00    	add    $0x17007,%ebx
f010030b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010030e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100313:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100318:	b9 84 00 00 00       	mov    $0x84,%ecx
f010031d:	89 fa                	mov    %edi,%edx
f010031f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100320:	a8 20                	test   $0x20,%al
f0100322:	75 13                	jne    f0100337 <cons_putc+0x40>
f0100324:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032a:	7f 0b                	jg     f0100337 <cons_putc+0x40>
f010032c:	89 ca                	mov    %ecx,%edx
f010032e:	ec                   	in     (%dx),%al
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
	     i++)
f0100332:	83 c6 01             	add    $0x1,%esi
f0100335:	eb e6                	jmp    f010031d <cons_putc+0x26>
	outb(COM1 + COM_TX, c);
f0100337:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010033b:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100343:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100344:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100349:	bf 79 03 00 00       	mov    $0x379,%edi
f010034e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100353:	89 fa                	mov    %edi,%edx
f0100355:	ec                   	in     (%dx),%al
f0100356:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010035c:	7f 0f                	jg     f010036d <cons_putc+0x76>
f010035e:	84 c0                	test   %al,%al
f0100360:	78 0b                	js     f010036d <cons_putc+0x76>
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ec                   	in     (%dx),%al
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	83 c6 01             	add    $0x1,%esi
f010036b:	eb e6                	jmp    f0100353 <cons_putc+0x5c>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100372:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100376:	ee                   	out    %al,(%dx)
f0100377:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010037c:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100381:	ee                   	out    %al,(%dx)
f0100382:	b8 08 00 00 00       	mov    $0x8,%eax
f0100387:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f0100388:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010038b:	89 f8                	mov    %edi,%eax
f010038d:	80 cc 07             	or     $0x7,%ah
f0100390:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100396:	0f 45 c7             	cmovne %edi,%eax
f0100399:	89 c7                	mov    %eax,%edi
f010039b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f010039e:	0f b6 c0             	movzbl %al,%eax
f01003a1:	89 f9                	mov    %edi,%ecx
f01003a3:	80 f9 0a             	cmp    $0xa,%cl
f01003a6:	0f 84 e4 00 00 00    	je     f0100490 <cons_putc+0x199>
f01003ac:	83 f8 0a             	cmp    $0xa,%eax
f01003af:	7f 46                	jg     f01003f7 <cons_putc+0x100>
f01003b1:	83 f8 08             	cmp    $0x8,%eax
f01003b4:	0f 84 a8 00 00 00    	je     f0100462 <cons_putc+0x16b>
f01003ba:	83 f8 09             	cmp    $0x9,%eax
f01003bd:	0f 85 da 00 00 00    	jne    f010049d <cons_putc+0x1a6>
		cons_putc(' ');
f01003c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c8:	e8 2a ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d2:	e8 20 ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dc:	e8 16 ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e6:	e8 0c ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003eb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f0:	e8 02 ff ff ff       	call   f01002f7 <cons_putc>
		break;
f01003f5:	eb 26                	jmp    f010041d <cons_putc+0x126>
	switch (c & 0xff) {
f01003f7:	83 f8 0d             	cmp    $0xd,%eax
f01003fa:	0f 85 9d 00 00 00    	jne    f010049d <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100400:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f0100407:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010040d:	c1 e8 16             	shr    $0x16,%eax
f0100410:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100413:	c1 e0 04             	shl    $0x4,%eax
f0100416:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010041d:	66 81 bb 9c 1f 00 00 	cmpw   $0x7cf,0x1f9c(%ebx)
f0100424:	cf 07 
f0100426:	0f 87 98 00 00 00    	ja     f01004c4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f010042c:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f0100432:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100437:	89 ca                	mov    %ecx,%edx
f0100439:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010043a:	0f b7 9b 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%ebx
f0100441:	8d 71 01             	lea    0x1(%ecx),%esi
f0100444:	89 d8                	mov    %ebx,%eax
f0100446:	66 c1 e8 08          	shr    $0x8,%ax
f010044a:	89 f2                	mov    %esi,%edx
f010044c:	ee                   	out    %al,(%dx)
f010044d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100452:	89 ca                	mov    %ecx,%edx
f0100454:	ee                   	out    %al,(%dx)
f0100455:	89 d8                	mov    %ebx,%eax
f0100457:	89 f2                	mov    %esi,%edx
f0100459:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010045a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010045d:	5b                   	pop    %ebx
f010045e:	5e                   	pop    %esi
f010045f:	5f                   	pop    %edi
f0100460:	5d                   	pop    %ebp
f0100461:	c3                   	ret    
		if (crt_pos > 0) {
f0100462:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f0100469:	66 85 c0             	test   %ax,%ax
f010046c:	74 be                	je     f010042c <cons_putc+0x135>
			crt_pos--;
f010046e:	83 e8 01             	sub    $0x1,%eax
f0100471:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100478:	0f b7 c0             	movzwl %ax,%eax
f010047b:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f010047f:	b2 00                	mov    $0x0,%dl
f0100481:	83 ca 20             	or     $0x20,%edx
f0100484:	8b 8b a0 1f 00 00    	mov    0x1fa0(%ebx),%ecx
f010048a:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010048e:	eb 8d                	jmp    f010041d <cons_putc+0x126>
		crt_pos += CRT_COLS;
f0100490:	66 83 83 9c 1f 00 00 	addw   $0x50,0x1f9c(%ebx)
f0100497:	50 
f0100498:	e9 63 ff ff ff       	jmp    f0100400 <cons_putc+0x109>
		crt_buf[crt_pos++] = c;		/* write the character */
f010049d:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f01004a4:	8d 50 01             	lea    0x1(%eax),%edx
f01004a7:	66 89 93 9c 1f 00 00 	mov    %dx,0x1f9c(%ebx)
f01004ae:	0f b7 c0             	movzwl %ax,%eax
f01004b1:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004b7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004bb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004bf:	e9 59 ff ff ff       	jmp    f010041d <cons_putc+0x126>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004c4:	8b 83 a0 1f 00 00    	mov    0x1fa0(%ebx),%eax
f01004ca:	83 ec 04             	sub    $0x4,%esp
f01004cd:	68 00 0f 00 00       	push   $0xf00
f01004d2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d8:	52                   	push   %edx
f01004d9:	50                   	push   %eax
f01004da:	e8 86 38 00 00       	call   f0103d65 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004df:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004e5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004eb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004f1:	83 c4 10             	add    $0x10,%esp
f01004f4:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f9:	83 c0 02             	add    $0x2,%eax
f01004fc:	39 d0                	cmp    %edx,%eax
f01004fe:	75 f4                	jne    f01004f4 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100500:	66 83 ab 9c 1f 00 00 	subw   $0x50,0x1f9c(%ebx)
f0100507:	50 
f0100508:	e9 1f ff ff ff       	jmp    f010042c <cons_putc+0x135>

f010050d <serial_intr>:
{
f010050d:	e8 cf 01 00 00       	call   f01006e1 <__x86.get_pc_thunk.ax>
f0100512:	05 fa 6d 01 00       	add    $0x16dfa,%eax
	if (serial_exists)
f0100517:	80 b8 a8 1f 00 00 00 	cmpb   $0x0,0x1fa8(%eax)
f010051e:	75 01                	jne    f0100521 <serial_intr+0x14>
f0100520:	c3                   	ret    
{
f0100521:	55                   	push   %ebp
f0100522:	89 e5                	mov    %esp,%ebp
f0100524:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100527:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
f010052d:	e8 3b fc ff ff       	call   f010016d <cons_intr>
}
f0100532:	c9                   	leave  
f0100533:	c3                   	ret    

f0100534 <kbd_intr>:
{
f0100534:	55                   	push   %ebp
f0100535:	89 e5                	mov    %esp,%ebp
f0100537:	83 ec 08             	sub    $0x8,%esp
f010053a:	e8 a2 01 00 00       	call   f01006e1 <__x86.get_pc_thunk.ax>
f010053f:	05 cd 6d 01 00       	add    $0x16dcd,%eax
	cons_intr(kbd_proc_data);
f0100544:	8d 80 c5 8e fe ff    	lea    -0x1713b(%eax),%eax
f010054a:	e8 1e fc ff ff       	call   f010016d <cons_intr>
}
f010054f:	c9                   	leave  
f0100550:	c3                   	ret    

f0100551 <cons_getc>:
{
f0100551:	55                   	push   %ebp
f0100552:	89 e5                	mov    %esp,%ebp
f0100554:	53                   	push   %ebx
f0100555:	83 ec 04             	sub    $0x4,%esp
f0100558:	e8 f2 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010055d:	81 c3 af 6d 01 00    	add    $0x16daf,%ebx
	serial_intr();
f0100563:	e8 a5 ff ff ff       	call   f010050d <serial_intr>
	kbd_intr();
f0100568:	e8 c7 ff ff ff       	call   f0100534 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010056d:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
	return 0;
f0100573:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100578:	3b 83 98 1f 00 00    	cmp    0x1f98(%ebx),%eax
f010057e:	74 1e                	je     f010059e <cons_getc+0x4d>
		c = cons.buf[cons.rpos++];
f0100580:	8d 48 01             	lea    0x1(%eax),%ecx
f0100583:	0f b6 94 03 94 1d 00 	movzbl 0x1d94(%ebx,%eax,1),%edx
f010058a:	00 
			cons.rpos = 0;
f010058b:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f0100590:	b8 00 00 00 00       	mov    $0x0,%eax
f0100595:	0f 45 c1             	cmovne %ecx,%eax
f0100598:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f010059e:	89 d0                	mov    %edx,%eax
f01005a0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01005a3:	c9                   	leave  
f01005a4:	c3                   	ret    

f01005a5 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a5:	55                   	push   %ebp
f01005a6:	89 e5                	mov    %esp,%ebp
f01005a8:	57                   	push   %edi
f01005a9:	56                   	push   %esi
f01005aa:	53                   	push   %ebx
f01005ab:	83 ec 1c             	sub    $0x1c,%esp
f01005ae:	e8 9c fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b3:	81 c3 59 6d 01 00    	add    $0x16d59,%ebx
	was = *cp;
f01005b9:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005c0:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c7:	5a a5 
	if (*cp != 0xA55A) {
f01005c9:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005d0:	b9 b4 03 00 00       	mov    $0x3b4,%ecx
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005d5:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
	if (*cp != 0xA55A) {
f01005da:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005de:	0f 84 ac 00 00 00    	je     f0100690 <cons_init+0xeb>
		addr_6845 = MONO_BASE;
f01005e4:	89 8b a4 1f 00 00    	mov    %ecx,0x1fa4(%ebx)
f01005ea:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ef:	89 ca                	mov    %ecx,%edx
f01005f1:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f2:	8d 71 01             	lea    0x1(%ecx),%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f5:	89 f2                	mov    %esi,%edx
f01005f7:	ec                   	in     (%dx),%al
f01005f8:	0f b6 c0             	movzbl %al,%eax
f01005fb:	c1 e0 08             	shl    $0x8,%eax
f01005fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100601:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100606:	89 ca                	mov    %ecx,%edx
f0100608:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100609:	89 f2                	mov    %esi,%edx
f010060b:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060c:	89 bb a0 1f 00 00    	mov    %edi,0x1fa0(%ebx)
	pos |= inb(addr_6845 + 1);
f0100612:	0f b6 c0             	movzbl %al,%eax
f0100615:	0b 45 e4             	or     -0x1c(%ebp),%eax
	crt_pos = pos;
f0100618:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100624:	89 c8                	mov    %ecx,%eax
f0100626:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010062b:	ee                   	out    %al,(%dx)
f010062c:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100631:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100636:	89 fa                	mov    %edi,%edx
f0100638:	ee                   	out    %al,(%dx)
f0100639:	b8 0c 00 00 00       	mov    $0xc,%eax
f010063e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100643:	ee                   	out    %al,(%dx)
f0100644:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100649:	89 c8                	mov    %ecx,%eax
f010064b:	89 f2                	mov    %esi,%edx
f010064d:	ee                   	out    %al,(%dx)
f010064e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010065b:	89 c8                	mov    %ecx,%eax
f010065d:	ee                   	out    %al,(%dx)
f010065e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100663:	89 f2                	mov    %esi,%edx
f0100665:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100666:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010066b:	ec                   	in     (%dx),%al
f010066c:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010066e:	3c ff                	cmp    $0xff,%al
f0100670:	0f 95 83 a8 1f 00 00 	setne  0x1fa8(%ebx)
f0100677:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010067c:	ec                   	in     (%dx),%al
f010067d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100682:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100683:	80 f9 ff             	cmp    $0xff,%cl
f0100686:	74 1e                	je     f01006a6 <cons_init+0x101>
		cprintf("Serial port does not exist!\n");
}
f0100688:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010068b:	5b                   	pop    %ebx
f010068c:	5e                   	pop    %esi
f010068d:	5f                   	pop    %edi
f010068e:	5d                   	pop    %ebp
f010068f:	c3                   	ret    
		*cp = was;
f0100690:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
f0100697:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010069c:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
f01006a1:	e9 3e ff ff ff       	jmp    f01005e4 <cons_init+0x3f>
		cprintf("Serial port does not exist!\n");
f01006a6:	83 ec 0c             	sub    $0xc,%esp
f01006a9:	8d 83 ae ce fe ff    	lea    -0x13152(%ebx),%eax
f01006af:	50                   	push   %eax
f01006b0:	e8 69 2a 00 00       	call   f010311e <cprintf>
f01006b5:	83 c4 10             	add    $0x10,%esp
}
f01006b8:	eb ce                	jmp    f0100688 <cons_init+0xe3>

f01006ba <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006ba:	55                   	push   %ebp
f01006bb:	89 e5                	mov    %esp,%ebp
f01006bd:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01006c3:	e8 2f fc ff ff       	call   f01002f7 <cons_putc>
}
f01006c8:	c9                   	leave  
f01006c9:	c3                   	ret    

f01006ca <getchar>:

int
getchar(void)
{
f01006ca:	55                   	push   %ebp
f01006cb:	89 e5                	mov    %esp,%ebp
f01006cd:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006d0:	e8 7c fe ff ff       	call   f0100551 <cons_getc>
f01006d5:	85 c0                	test   %eax,%eax
f01006d7:	74 f7                	je     f01006d0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006d9:	c9                   	leave  
f01006da:	c3                   	ret    

f01006db <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f01006db:	b8 01 00 00 00       	mov    $0x1,%eax
f01006e0:	c3                   	ret    

f01006e1 <__x86.get_pc_thunk.ax>:
f01006e1:	8b 04 24             	mov    (%esp),%eax
f01006e4:	c3                   	ret    

f01006e5 <__x86.get_pc_thunk.si>:
f01006e5:	8b 34 24             	mov    (%esp),%esi
f01006e8:	c3                   	ret    

f01006e9 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006e9:	55                   	push   %ebp
f01006ea:	89 e5                	mov    %esp,%ebp
f01006ec:	56                   	push   %esi
f01006ed:	53                   	push   %ebx
f01006ee:	e8 5c fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006f3:	81 c3 19 6c 01 00    	add    $0x16c19,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f9:	83 ec 04             	sub    $0x4,%esp
f01006fc:	8d 83 d4 d0 fe ff    	lea    -0x12f2c(%ebx),%eax
f0100702:	50                   	push   %eax
f0100703:	8d 83 f2 d0 fe ff    	lea    -0x12f0e(%ebx),%eax
f0100709:	50                   	push   %eax
f010070a:	8d b3 f7 d0 fe ff    	lea    -0x12f09(%ebx),%esi
f0100710:	56                   	push   %esi
f0100711:	e8 08 2a 00 00       	call   f010311e <cprintf>
f0100716:	83 c4 0c             	add    $0xc,%esp
f0100719:	8d 83 a0 d1 fe ff    	lea    -0x12e60(%ebx),%eax
f010071f:	50                   	push   %eax
f0100720:	8d 83 00 d1 fe ff    	lea    -0x12f00(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	56                   	push   %esi
f0100728:	e8 f1 29 00 00       	call   f010311e <cprintf>
	return 0;
}
f010072d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100732:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100735:	5b                   	pop    %ebx
f0100736:	5e                   	pop    %esi
f0100737:	5d                   	pop    %ebp
f0100738:	c3                   	ret    

f0100739 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100739:	55                   	push   %ebp
f010073a:	89 e5                	mov    %esp,%ebp
f010073c:	57                   	push   %edi
f010073d:	56                   	push   %esi
f010073e:	53                   	push   %ebx
f010073f:	83 ec 18             	sub    $0x18,%esp
f0100742:	e8 08 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100747:	81 c3 c5 6b 01 00    	add    $0x16bc5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010074d:	8d 83 09 d1 fe ff    	lea    -0x12ef7(%ebx),%eax
f0100753:	50                   	push   %eax
f0100754:	e8 c5 29 00 00       	call   f010311e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100759:	83 c4 08             	add    $0x8,%esp
f010075c:	ff b3 f4 ff ff ff    	push   -0xc(%ebx)
f0100762:	8d 83 c8 d1 fe ff    	lea    -0x12e38(%ebx),%eax
f0100768:	50                   	push   %eax
f0100769:	e8 b0 29 00 00       	call   f010311e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010076e:	83 c4 0c             	add    $0xc,%esp
f0100771:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100777:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010077d:	50                   	push   %eax
f010077e:	57                   	push   %edi
f010077f:	8d 83 f0 d1 fe ff    	lea    -0x12e10(%ebx),%eax
f0100785:	50                   	push   %eax
f0100786:	e8 93 29 00 00       	call   f010311e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010078b:	83 c4 0c             	add    $0xc,%esp
f010078e:	c7 c0 41 41 10 f0    	mov    $0xf0104141,%eax
f0100794:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010079a:	52                   	push   %edx
f010079b:	50                   	push   %eax
f010079c:	8d 83 14 d2 fe ff    	lea    -0x12dec(%ebx),%eax
f01007a2:	50                   	push   %eax
f01007a3:	e8 76 29 00 00       	call   f010311e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007b1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007b7:	52                   	push   %edx
f01007b8:	50                   	push   %eax
f01007b9:	8d 83 38 d2 fe ff    	lea    -0x12dc8(%ebx),%eax
f01007bf:	50                   	push   %eax
f01007c0:	e8 59 29 00 00       	call   f010311e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007c5:	83 c4 0c             	add    $0xc,%esp
f01007c8:	c7 c6 e0 96 11 f0    	mov    $0xf01196e0,%esi
f01007ce:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007d4:	50                   	push   %eax
f01007d5:	56                   	push   %esi
f01007d6:	8d 83 5c d2 fe ff    	lea    -0x12da4(%ebx),%eax
f01007dc:	50                   	push   %eax
f01007dd:	e8 3c 29 00 00       	call   f010311e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007e2:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007e5:	29 fe                	sub    %edi,%esi
f01007e7:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ed:	c1 fe 0a             	sar    $0xa,%esi
f01007f0:	56                   	push   %esi
f01007f1:	8d 83 80 d2 fe ff    	lea    -0x12d80(%ebx),%eax
f01007f7:	50                   	push   %eax
f01007f8:	e8 21 29 00 00       	call   f010311e <cprintf>
	return 0;
}
f01007fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100802:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100805:	5b                   	pop    %ebx
f0100806:	5e                   	pop    %esi
f0100807:	5f                   	pop    %edi
f0100808:	5d                   	pop    %ebp
f0100809:	c3                   	ret    

f010080a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010080a:	55                   	push   %ebp
f010080b:	89 e5                	mov    %esp,%ebp
f010080d:	57                   	push   %edi
f010080e:	56                   	push   %esi
f010080f:	53                   	push   %ebx
f0100810:	83 ec 58             	sub    $0x58,%esp
f0100813:	e8 37 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100818:	81 c3 f4 6a 01 00    	add    $0x16af4,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010081e:	89 e8                	mov    %ebp,%eax
	unsigned int *ebp = ((unsigned int*)read_ebp());
f0100820:	89 c7                	mov    %eax,%edi
	cprintf("Stack backtrace:\n");
f0100822:	8d 83 22 d1 fe ff    	lea    -0x12ede(%ebx),%eax
f0100828:	50                   	push   %eax
f0100829:	e8 f0 28 00 00       	call   f010311e <cprintf>

	while(ebp) {
f010082e:	83 c4 10             	add    $0x10,%esp
		unsigned int eip = ebp[1];
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
		cprintf("ebp %08x ", ebp);
f0100831:	8d 83 34 d1 fe ff    	lea    -0x12ecc(%ebx),%eax
f0100837:	89 45 b8             	mov    %eax,-0x48(%ebp)
		cprintf("eip %08x args", ebp[1]);
f010083a:	8d 83 3e d1 fe ff    	lea    -0x12ec2(%ebx),%eax
f0100840:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	while(ebp) {
f0100843:	e9 95 00 00 00       	jmp    f01008dd <mon_backtrace+0xd3>
		unsigned int eip = ebp[1];
f0100848:	8b 47 04             	mov    0x4(%edi),%eax
f010084b:	89 c2                	mov    %eax,%edx
f010084d:	89 45 c0             	mov    %eax,-0x40(%ebp)
		debuginfo_eip(eip, &info);
f0100850:	83 ec 08             	sub    $0x8,%esp
f0100853:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100856:	50                   	push   %eax
f0100857:	52                   	push   %edx
f0100858:	e8 ca 29 00 00       	call   f0103227 <debuginfo_eip>
		cprintf("ebp %08x ", ebp);
f010085d:	83 c4 08             	add    $0x8,%esp
f0100860:	57                   	push   %edi
f0100861:	ff 75 b8             	push   -0x48(%ebp)
f0100864:	e8 b5 28 00 00       	call   f010311e <cprintf>
		cprintf("eip %08x args", ebp[1]);
f0100869:	83 c4 08             	add    $0x8,%esp
f010086c:	ff 77 04             	push   0x4(%edi)
f010086f:	ff 75 b4             	push   -0x4c(%ebp)
f0100872:	e8 a7 28 00 00       	call   f010311e <cprintf>
f0100877:	8d 77 08             	lea    0x8(%edi),%esi
f010087a:	8d 47 1c             	lea    0x1c(%edi),%eax
f010087d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100880:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f0100883:	8d 83 4c d1 fe ff    	lea    -0x12eb4(%ebx),%eax
f0100889:	89 7d bc             	mov    %edi,-0x44(%ebp)
f010088c:	89 c7                	mov    %eax,%edi
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	ff 36                	push   (%esi)
f0100893:	57                   	push   %edi
f0100894:	e8 85 28 00 00       	call   f010311e <cprintf>
		for(int i = 2; i <= 6; i++)
f0100899:	83 c6 04             	add    $0x4,%esi
f010089c:	83 c4 10             	add    $0x10,%esp
f010089f:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f01008a2:	75 ea                	jne    f010088e <mon_backtrace+0x84>
		cprintf("\n");
f01008a4:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008a7:	83 ec 0c             	sub    $0xc,%esp
f01008aa:	8d 83 01 d6 fe ff    	lea    -0x129ff(%ebx),%eax
f01008b0:	50                   	push   %eax
f01008b1:	e8 68 28 00 00       	call   f010311e <cprintf>

		cprintf("\t%s:%d: %.*s+%d\n",
f01008b6:	83 c4 08             	add    $0x8,%esp
f01008b9:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01008bc:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008bf:	50                   	push   %eax
f01008c0:	ff 75 d8             	push   -0x28(%ebp)
f01008c3:	ff 75 dc             	push   -0x24(%ebp)
f01008c6:	ff 75 d4             	push   -0x2c(%ebp)
f01008c9:	ff 75 d0             	push   -0x30(%ebp)
f01008cc:	8d 83 52 d1 fe ff    	lea    -0x12eae(%ebx),%eax
f01008d2:	50                   	push   %eax
f01008d3:	e8 46 28 00 00       	call   f010311e <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip - info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f01008d8:	8b 3f                	mov    (%edi),%edi
f01008da:	83 c4 20             	add    $0x20,%esp
	while(ebp) {
f01008dd:	85 ff                	test   %edi,%edi
f01008df:	0f 85 63 ff ff ff    	jne    f0100848 <mon_backtrace+0x3e>
	}
	return 0;
}
f01008e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ed:	5b                   	pop    %ebx
f01008ee:	5e                   	pop    %esi
f01008ef:	5f                   	pop    %edi
f01008f0:	5d                   	pop    %ebp
f01008f1:	c3                   	ret    

f01008f2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008f2:	55                   	push   %ebp
f01008f3:	89 e5                	mov    %esp,%ebp
f01008f5:	57                   	push   %edi
f01008f6:	56                   	push   %esi
f01008f7:	53                   	push   %ebx
f01008f8:	83 ec 68             	sub    $0x68,%esp
f01008fb:	e8 4f f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100900:	81 c3 0c 6a 01 00    	add    $0x16a0c,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100906:	8d 83 ac d2 fe ff    	lea    -0x12d54(%ebx),%eax
f010090c:	50                   	push   %eax
f010090d:	e8 0c 28 00 00       	call   f010311e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100912:	8d 83 d0 d2 fe ff    	lea    -0x12d30(%ebx),%eax
f0100918:	89 04 24             	mov    %eax,(%esp)
f010091b:	e8 fe 27 00 00       	call   f010311e <cprintf>
f0100920:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100923:	8d bb 67 d1 fe ff    	lea    -0x12e99(%ebx),%edi
f0100929:	eb 4a                	jmp    f0100975 <monitor+0x83>
f010092b:	83 ec 08             	sub    $0x8,%esp
f010092e:	0f be c0             	movsbl %al,%eax
f0100931:	50                   	push   %eax
f0100932:	57                   	push   %edi
f0100933:	e8 a8 33 00 00       	call   f0103ce0 <strchr>
f0100938:	83 c4 10             	add    $0x10,%esp
f010093b:	85 c0                	test   %eax,%eax
f010093d:	74 08                	je     f0100947 <monitor+0x55>
			*buf++ = 0;
f010093f:	c6 06 00             	movb   $0x0,(%esi)
f0100942:	8d 76 01             	lea    0x1(%esi),%esi
f0100945:	eb 79                	jmp    f01009c0 <monitor+0xce>
		if (*buf == 0)
f0100947:	80 3e 00             	cmpb   $0x0,(%esi)
f010094a:	74 7f                	je     f01009cb <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010094c:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100950:	74 0f                	je     f0100961 <monitor+0x6f>
		argv[argc++] = buf;
f0100952:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100955:	8d 48 01             	lea    0x1(%eax),%ecx
f0100958:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010095b:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010095f:	eb 44                	jmp    f01009a5 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100961:	83 ec 08             	sub    $0x8,%esp
f0100964:	6a 10                	push   $0x10
f0100966:	8d 83 6c d1 fe ff    	lea    -0x12e94(%ebx),%eax
f010096c:	50                   	push   %eax
f010096d:	e8 ac 27 00 00       	call   f010311e <cprintf>
			return 0;
f0100972:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100975:	8d 83 63 d1 fe ff    	lea    -0x12e9d(%ebx),%eax
f010097b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f010097e:	83 ec 0c             	sub    $0xc,%esp
f0100981:	ff 75 a4             	push   -0x5c(%ebp)
f0100984:	e8 06 31 00 00       	call   f0103a8f <readline>
f0100989:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f010098b:	83 c4 10             	add    $0x10,%esp
f010098e:	85 c0                	test   %eax,%eax
f0100990:	74 ec                	je     f010097e <monitor+0x8c>
	argv[argc] = 0;
f0100992:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100999:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009a0:	eb 1e                	jmp    f01009c0 <monitor+0xce>
			buf++;
f01009a2:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009a5:	0f b6 06             	movzbl (%esi),%eax
f01009a8:	84 c0                	test   %al,%al
f01009aa:	74 14                	je     f01009c0 <monitor+0xce>
f01009ac:	83 ec 08             	sub    $0x8,%esp
f01009af:	0f be c0             	movsbl %al,%eax
f01009b2:	50                   	push   %eax
f01009b3:	57                   	push   %edi
f01009b4:	e8 27 33 00 00       	call   f0103ce0 <strchr>
f01009b9:	83 c4 10             	add    $0x10,%esp
f01009bc:	85 c0                	test   %eax,%eax
f01009be:	74 e2                	je     f01009a2 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01009c0:	0f b6 06             	movzbl (%esi),%eax
f01009c3:	84 c0                	test   %al,%al
f01009c5:	0f 85 60 ff ff ff    	jne    f010092b <monitor+0x39>
	argv[argc] = 0;
f01009cb:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009ce:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009d5:	00 
	if (argc == 0)
f01009d6:	85 c0                	test   %eax,%eax
f01009d8:	74 9b                	je     f0100975 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009da:	83 ec 08             	sub    $0x8,%esp
f01009dd:	8d 83 f2 d0 fe ff    	lea    -0x12f0e(%ebx),%eax
f01009e3:	50                   	push   %eax
f01009e4:	ff 75 a8             	push   -0x58(%ebp)
f01009e7:	e8 94 32 00 00       	call   f0103c80 <strcmp>
f01009ec:	83 c4 10             	add    $0x10,%esp
f01009ef:	85 c0                	test   %eax,%eax
f01009f1:	74 38                	je     f0100a2b <monitor+0x139>
f01009f3:	83 ec 08             	sub    $0x8,%esp
f01009f6:	8d 83 00 d1 fe ff    	lea    -0x12f00(%ebx),%eax
f01009fc:	50                   	push   %eax
f01009fd:	ff 75 a8             	push   -0x58(%ebp)
f0100a00:	e8 7b 32 00 00       	call   f0103c80 <strcmp>
f0100a05:	83 c4 10             	add    $0x10,%esp
f0100a08:	85 c0                	test   %eax,%eax
f0100a0a:	74 1a                	je     f0100a26 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a0c:	83 ec 08             	sub    $0x8,%esp
f0100a0f:	ff 75 a8             	push   -0x58(%ebp)
f0100a12:	8d 83 89 d1 fe ff    	lea    -0x12e77(%ebx),%eax
f0100a18:	50                   	push   %eax
f0100a19:	e8 00 27 00 00       	call   f010311e <cprintf>
	return 0;
f0100a1e:	83 c4 10             	add    $0x10,%esp
f0100a21:	e9 4f ff ff ff       	jmp    f0100975 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a26:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a2b:	83 ec 04             	sub    $0x4,%esp
f0100a2e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a31:	ff 75 08             	push   0x8(%ebp)
f0100a34:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a37:	52                   	push   %edx
f0100a38:	ff 75 a4             	push   -0x5c(%ebp)
f0100a3b:	ff 94 83 0c 1d 00 00 	call   *0x1d0c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a42:	83 c4 10             	add    $0x10,%esp
f0100a45:	85 c0                	test   %eax,%eax
f0100a47:	0f 89 28 ff ff ff    	jns    f0100975 <monitor+0x83>
				break;
	}
}
f0100a4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a50:	5b                   	pop    %ebx
f0100a51:	5e                   	pop    %esi
f0100a52:	5f                   	pop    %edi
f0100a53:	5d                   	pop    %ebp
f0100a54:	c3                   	ret    

f0100a55 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a55:	55                   	push   %ebp
f0100a56:	89 e5                	mov    %esp,%ebp
f0100a58:	57                   	push   %edi
f0100a59:	56                   	push   %esi
f0100a5a:	53                   	push   %ebx
f0100a5b:	83 ec 18             	sub    $0x18,%esp
f0100a5e:	e8 ec f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a63:	81 c3 a9 68 01 00    	add    $0x168a9,%ebx
f0100a69:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a6b:	50                   	push   %eax
f0100a6c:	e8 26 26 00 00       	call   f0103097 <mc146818_read>
f0100a71:	89 c7                	mov    %eax,%edi
f0100a73:	83 c6 01             	add    $0x1,%esi
f0100a76:	89 34 24             	mov    %esi,(%esp)
f0100a79:	e8 19 26 00 00       	call   f0103097 <mc146818_read>
f0100a7e:	c1 e0 08             	shl    $0x8,%eax
f0100a81:	09 f8                	or     %edi,%eax
}
f0100a83:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a86:	5b                   	pop    %ebx
f0100a87:	5e                   	pop    %esi
f0100a88:	5f                   	pop    %edi
f0100a89:	5d                   	pop    %ebp
f0100a8a:	c3                   	ret    

f0100a8b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a8b:	55                   	push   %ebp
f0100a8c:	89 e5                	mov    %esp,%ebp
f0100a8e:	56                   	push   %esi
f0100a8f:	53                   	push   %ebx
f0100a90:	e8 ba f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a95:	81 c3 77 68 01 00    	add    $0x16877,%ebx
f0100a9b:	89 c6                	mov    %eax,%esi
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a9d:	83 bb b8 1f 00 00 00 	cmpl   $0x0,0x1fb8(%ebx)
f0100aa4:	74 28                	je     f0100ace <boot_alloc+0x43>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100aa6:	8b 93 b8 1f 00 00    	mov    0x1fb8(%ebx),%edx
	nextfree = ROUNDUP(result + n, PGSIZE);
f0100aac:	8d 84 32 ff 0f 00 00 	lea    0xfff(%edx,%esi,1),%eax
f0100ab3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab8:	89 83 b8 1f 00 00    	mov    %eax,0x1fb8(%ebx)
	if ((uintptr_t) nextfree >= KERNBASE + PTSIZE) {
f0100abe:	3d ff ff 3f f0       	cmp    $0xf03fffff,%eax
f0100ac3:	77 21                	ja     f0100ae6 <boot_alloc+0x5b>
		cprintf("boot_alloc: out of memory\n");
		panic("boot_alloc: failed to allocate %d bytes", n);
	}
	return result;
}
f0100ac5:	89 d0                	mov    %edx,%eax
f0100ac7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aca:	5b                   	pop    %ebx
f0100acb:	5e                   	pop    %esi
f0100acc:	5d                   	pop    %ebp
f0100acd:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ace:	c7 c0 e0 96 11 f0    	mov    $0xf01196e0,%eax
f0100ad4:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100ad9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ade:	89 83 b8 1f 00 00    	mov    %eax,0x1fb8(%ebx)
f0100ae4:	eb c0                	jmp    f0100aa6 <boot_alloc+0x1b>
		cprintf("boot_alloc: out of memory\n");
f0100ae6:	83 ec 0c             	sub    $0xc,%esp
f0100ae9:	8d 83 f5 d2 fe ff    	lea    -0x12d0b(%ebx),%eax
f0100aef:	50                   	push   %eax
f0100af0:	e8 29 26 00 00       	call   f010311e <cprintf>
		panic("boot_alloc: failed to allocate %d bytes", n);
f0100af5:	56                   	push   %esi
f0100af6:	8d 83 34 d6 fe ff    	lea    -0x129cc(%ebx),%eax
f0100afc:	50                   	push   %eax
f0100afd:	6a 6d                	push   $0x6d
f0100aff:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100b05:	50                   	push   %eax
f0100b06:	e8 8e f5 ff ff       	call   f0100099 <_panic>

f0100b0b <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b0b:	55                   	push   %ebp
f0100b0c:	89 e5                	mov    %esp,%ebp
f0100b0e:	53                   	push   %ebx
f0100b0f:	83 ec 04             	sub    $0x4,%esp
f0100b12:	e8 78 25 00 00       	call   f010308f <__x86.get_pc_thunk.cx>
f0100b17:	81 c1 f5 67 01 00    	add    $0x167f5,%ecx
f0100b1d:	89 c3                	mov    %eax,%ebx
f0100b1f:	89 d0                	mov    %edx,%eax
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b21:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P))
f0100b24:	8b 14 93             	mov    (%ebx,%edx,4),%edx
f0100b27:	f6 c2 01             	test   $0x1,%dl
f0100b2a:	74 54                	je     f0100b80 <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b2c:	89 d3                	mov    %edx,%ebx
f0100b2e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b34:	c1 ea 0c             	shr    $0xc,%edx
f0100b37:	3b 91 b4 1f 00 00    	cmp    0x1fb4(%ecx),%edx
f0100b3d:	73 26                	jae    f0100b65 <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100b3f:	c1 e8 0c             	shr    $0xc,%eax
f0100b42:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100b47:	8b 94 83 00 00 00 f0 	mov    -0x10000000(%ebx,%eax,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b4e:	89 d0                	mov    %edx,%eax
f0100b50:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b55:	f6 c2 01             	test   $0x1,%dl
f0100b58:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b5d:	0f 44 c2             	cmove  %edx,%eax
}
f0100b60:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b63:	c9                   	leave  
f0100b64:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b65:	53                   	push   %ebx
f0100b66:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f0100b6c:	50                   	push   %eax
f0100b6d:	68 de 02 00 00       	push   $0x2de
f0100b72:	8d 81 10 d3 fe ff    	lea    -0x12cf0(%ecx),%eax
f0100b78:	50                   	push   %eax
f0100b79:	89 cb                	mov    %ecx,%ebx
f0100b7b:	e8 19 f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b85:	eb d9                	jmp    f0100b60 <check_va2pa+0x55>

f0100b87 <check_page_free_list>:
{
f0100b87:	55                   	push   %ebp
f0100b88:	89 e5                	mov    %esp,%ebp
f0100b8a:	57                   	push   %edi
f0100b8b:	56                   	push   %esi
f0100b8c:	53                   	push   %ebx
f0100b8d:	83 ec 2c             	sub    $0x2c,%esp
f0100b90:	e8 fe 24 00 00       	call   f0103093 <__x86.get_pc_thunk.di>
f0100b95:	81 c7 77 67 01 00    	add    $0x16777,%edi
f0100b9b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b9e:	84 c0                	test   %al,%al
f0100ba0:	0f 85 dc 02 00 00    	jne    f0100e82 <check_page_free_list+0x2fb>
	if (!page_free_list)
f0100ba6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ba9:	83 b8 bc 1f 00 00 00 	cmpl   $0x0,0x1fbc(%eax)
f0100bb0:	74 0a                	je     f0100bbc <check_page_free_list+0x35>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bb2:	bf 00 04 00 00       	mov    $0x400,%edi
f0100bb7:	e9 29 03 00 00       	jmp    f0100ee5 <check_page_free_list+0x35e>
		panic("'page_free_list' is a null pointer!");
f0100bbc:	83 ec 04             	sub    $0x4,%esp
f0100bbf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100bc2:	8d 83 80 d6 fe ff    	lea    -0x12980(%ebx),%eax
f0100bc8:	50                   	push   %eax
f0100bc9:	68 1f 02 00 00       	push   $0x21f
f0100bce:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100bd4:	50                   	push   %eax
f0100bd5:	e8 bf f4 ff ff       	call   f0100099 <_panic>
f0100bda:	50                   	push   %eax
f0100bdb:	89 cb                	mov    %ecx,%ebx
f0100bdd:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f0100be3:	50                   	push   %eax
f0100be4:	6a 52                	push   $0x52
f0100be6:	8d 81 1c d3 fe ff    	lea    -0x12ce4(%ecx),%eax
f0100bec:	50                   	push   %eax
f0100bed:	e8 a7 f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bf2:	8b 36                	mov    (%esi),%esi
f0100bf4:	85 f6                	test   %esi,%esi
f0100bf6:	74 47                	je     f0100c3f <check_page_free_list+0xb8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bf8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100bfb:	89 f0                	mov    %esi,%eax
f0100bfd:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0100c03:	c1 f8 03             	sar    $0x3,%eax
f0100c06:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c09:	89 c2                	mov    %eax,%edx
f0100c0b:	c1 ea 16             	shr    $0x16,%edx
f0100c0e:	39 fa                	cmp    %edi,%edx
f0100c10:	73 e0                	jae    f0100bf2 <check_page_free_list+0x6b>
	if (PGNUM(pa) >= npages)
f0100c12:	89 c2                	mov    %eax,%edx
f0100c14:	c1 ea 0c             	shr    $0xc,%edx
f0100c17:	3b 91 b4 1f 00 00    	cmp    0x1fb4(%ecx),%edx
f0100c1d:	73 bb                	jae    f0100bda <check_page_free_list+0x53>
			memset(page2kva(pp), 0x97, 128);
f0100c1f:	83 ec 04             	sub    $0x4,%esp
f0100c22:	68 80 00 00 00       	push   $0x80
f0100c27:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c2c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c31:	50                   	push   %eax
f0100c32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c35:	e8 e5 30 00 00       	call   f0103d1f <memset>
f0100c3a:	83 c4 10             	add    $0x10,%esp
f0100c3d:	eb b3                	jmp    f0100bf2 <check_page_free_list+0x6b>
	first_free_page = (char *) boot_alloc(0);
f0100c3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c44:	e8 42 fe ff ff       	call   f0100a8b <boot_alloc>
f0100c49:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c4f:	8b 90 bc 1f 00 00    	mov    0x1fbc(%eax),%edx
		assert(pp >= pages);
f0100c55:	8b 88 ac 1f 00 00    	mov    0x1fac(%eax),%ecx
		assert(pp < pages + npages);
f0100c5b:	8b 80 b4 1f 00 00    	mov    0x1fb4(%eax),%eax
f0100c61:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c64:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c67:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c6c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c71:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c74:	e9 07 01 00 00       	jmp    f0100d80 <check_page_free_list+0x1f9>
		assert(pp >= pages);
f0100c79:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c7c:	8d 83 2a d3 fe ff    	lea    -0x12cd6(%ebx),%eax
f0100c82:	50                   	push   %eax
f0100c83:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100c89:	50                   	push   %eax
f0100c8a:	68 39 02 00 00       	push   $0x239
f0100c8f:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100c95:	50                   	push   %eax
f0100c96:	e8 fe f3 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c9b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c9e:	8d 83 4b d3 fe ff    	lea    -0x12cb5(%ebx),%eax
f0100ca4:	50                   	push   %eax
f0100ca5:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100cab:	50                   	push   %eax
f0100cac:	68 3a 02 00 00       	push   $0x23a
f0100cb1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100cb7:	50                   	push   %eax
f0100cb8:	e8 dc f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cbd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cc0:	8d 83 a4 d6 fe ff    	lea    -0x1295c(%ebx),%eax
f0100cc6:	50                   	push   %eax
f0100cc7:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100ccd:	50                   	push   %eax
f0100cce:	68 3b 02 00 00       	push   $0x23b
f0100cd3:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100cd9:	50                   	push   %eax
f0100cda:	e8 ba f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100cdf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ce2:	8d 83 5f d3 fe ff    	lea    -0x12ca1(%ebx),%eax
f0100ce8:	50                   	push   %eax
f0100ce9:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100cef:	50                   	push   %eax
f0100cf0:	68 3e 02 00 00       	push   $0x23e
f0100cf5:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100cfb:	50                   	push   %eax
f0100cfc:	e8 98 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d04:	8d 83 70 d3 fe ff    	lea    -0x12c90(%ebx),%eax
f0100d0a:	50                   	push   %eax
f0100d0b:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100d11:	50                   	push   %eax
f0100d12:	68 3f 02 00 00       	push   $0x23f
f0100d17:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	e8 76 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d26:	8d 83 d8 d6 fe ff    	lea    -0x12928(%ebx),%eax
f0100d2c:	50                   	push   %eax
f0100d2d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100d33:	50                   	push   %eax
f0100d34:	68 40 02 00 00       	push   $0x240
f0100d39:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	e8 54 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d45:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d48:	8d 83 89 d3 fe ff    	lea    -0x12c77(%ebx),%eax
f0100d4e:	50                   	push   %eax
f0100d4f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100d55:	50                   	push   %eax
f0100d56:	68 41 02 00 00       	push   $0x241
f0100d5b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100d61:	50                   	push   %eax
f0100d62:	e8 32 f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d67:	89 c3                	mov    %eax,%ebx
f0100d69:	c1 eb 0c             	shr    $0xc,%ebx
f0100d6c:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0100d6f:	76 6d                	jbe    f0100dde <check_page_free_list+0x257>
	return (void *)(pa + KERNBASE);
f0100d71:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d76:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d79:	77 7c                	ja     f0100df7 <check_page_free_list+0x270>
			++nfree_extmem;
f0100d7b:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d7e:	8b 12                	mov    (%edx),%edx
f0100d80:	85 d2                	test   %edx,%edx
f0100d82:	0f 84 91 00 00 00    	je     f0100e19 <check_page_free_list+0x292>
		assert(pp >= pages);
f0100d88:	39 d1                	cmp    %edx,%ecx
f0100d8a:	0f 87 e9 fe ff ff    	ja     f0100c79 <check_page_free_list+0xf2>
		assert(pp < pages + npages);
f0100d90:	39 d6                	cmp    %edx,%esi
f0100d92:	0f 86 03 ff ff ff    	jbe    f0100c9b <check_page_free_list+0x114>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d98:	89 d0                	mov    %edx,%eax
f0100d9a:	29 c8                	sub    %ecx,%eax
f0100d9c:	a8 07                	test   $0x7,%al
f0100d9e:	0f 85 19 ff ff ff    	jne    f0100cbd <check_page_free_list+0x136>
	return (pp - pages) << PGSHIFT;
f0100da4:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100da7:	c1 e0 0c             	shl    $0xc,%eax
f0100daa:	0f 84 2f ff ff ff    	je     f0100cdf <check_page_free_list+0x158>
		assert(page2pa(pp) != IOPHYSMEM);
f0100db0:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100db5:	0f 84 46 ff ff ff    	je     f0100d01 <check_page_free_list+0x17a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dbb:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dc0:	0f 84 5d ff ff ff    	je     f0100d23 <check_page_free_list+0x19c>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dc6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dcb:	0f 84 74 ff ff ff    	je     f0100d45 <check_page_free_list+0x1be>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dd1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dd6:	77 8f                	ja     f0100d67 <check_page_free_list+0x1e0>
			++nfree_basemem;
f0100dd8:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
f0100ddc:	eb a0                	jmp    f0100d7e <check_page_free_list+0x1f7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dde:	50                   	push   %eax
f0100ddf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100de2:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f0100de8:	50                   	push   %eax
f0100de9:	6a 52                	push   $0x52
f0100deb:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f0100df1:	50                   	push   %eax
f0100df2:	e8 a2 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100df7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dfa:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0100e00:	50                   	push   %eax
f0100e01:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100e07:	50                   	push   %eax
f0100e08:	68 42 02 00 00       	push   $0x242
f0100e0d:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100e13:	50                   	push   %eax
f0100e14:	e8 80 f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_basemem > 0);
f0100e19:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0100e1c:	85 db                	test   %ebx,%ebx
f0100e1e:	7e 1e                	jle    f0100e3e <check_page_free_list+0x2b7>
	assert(nfree_extmem > 0);
f0100e20:	85 ff                	test   %edi,%edi
f0100e22:	7e 3c                	jle    f0100e60 <check_page_free_list+0x2d9>
	cprintf("check_page_free_list() succeeded!\n");
f0100e24:	83 ec 0c             	sub    $0xc,%esp
f0100e27:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e2a:	8d 83 44 d7 fe ff    	lea    -0x128bc(%ebx),%eax
f0100e30:	50                   	push   %eax
f0100e31:	e8 e8 22 00 00       	call   f010311e <cprintf>
}
f0100e36:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e39:	5b                   	pop    %ebx
f0100e3a:	5e                   	pop    %esi
f0100e3b:	5f                   	pop    %edi
f0100e3c:	5d                   	pop    %ebp
f0100e3d:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e3e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e41:	8d 83 a3 d3 fe ff    	lea    -0x12c5d(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100e4e:	50                   	push   %eax
f0100e4f:	68 4a 02 00 00       	push   $0x24a
f0100e54:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100e5a:	50                   	push   %eax
f0100e5b:	e8 39 f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e63:	8d 83 b5 d3 fe ff    	lea    -0x12c4b(%ebx),%eax
f0100e69:	50                   	push   %eax
f0100e6a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100e70:	50                   	push   %eax
f0100e71:	68 4b 02 00 00       	push   $0x24b
f0100e76:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100e7c:	50                   	push   %eax
f0100e7d:	e8 17 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e85:	8b 80 bc 1f 00 00    	mov    0x1fbc(%eax),%eax
f0100e8b:	85 c0                	test   %eax,%eax
f0100e8d:	0f 84 29 fd ff ff    	je     f0100bbc <check_page_free_list+0x35>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e93:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e96:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e99:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e9c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e9f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ea2:	89 c2                	mov    %eax,%edx
f0100ea4:	2b 97 ac 1f 00 00    	sub    0x1fac(%edi),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100eaa:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100eb0:	0f 95 c2             	setne  %dl
f0100eb3:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100eb6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100eba:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ebc:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ec0:	8b 00                	mov    (%eax),%eax
f0100ec2:	85 c0                	test   %eax,%eax
f0100ec4:	75 d9                	jne    f0100e9f <check_page_free_list+0x318>
		*tp[1] = 0;
f0100ec6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ec9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ecf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ed2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ed5:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ed7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100eda:	89 87 bc 1f 00 00    	mov    %eax,0x1fbc(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ee0:	bf 01 00 00 00       	mov    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ee5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ee8:	8b b0 bc 1f 00 00    	mov    0x1fbc(%eax),%esi
f0100eee:	e9 01 fd ff ff       	jmp    f0100bf4 <check_page_free_list+0x6d>

f0100ef3 <page_init>:
{
f0100ef3:	55                   	push   %ebp
f0100ef4:	89 e5                	mov    %esp,%ebp
f0100ef6:	57                   	push   %edi
f0100ef7:	56                   	push   %esi
f0100ef8:	53                   	push   %ebx
f0100ef9:	83 ec 0c             	sub    $0xc,%esp
f0100efc:	e8 4e f2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f01:	81 c3 0b 64 01 00    	add    $0x1640b,%ebx
	pages[0].pp_ref = 1;
f0100f07:	8b 83 ac 1f 00 00    	mov    0x1fac(%ebx),%eax
f0100f0d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100f13:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (int i = 1 ; i < npages_basemem; i++) {
f0100f19:	8b bb c0 1f 00 00    	mov    0x1fc0(%ebx),%edi
f0100f1f:	8b b3 bc 1f 00 00    	mov    0x1fbc(%ebx),%esi
f0100f25:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f2f:	eb 27                	jmp    f0100f58 <page_init+0x65>
f0100f31:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100f38:	89 d1                	mov    %edx,%ecx
f0100f3a:	03 8b ac 1f 00 00    	add    0x1fac(%ebx),%ecx
f0100f40:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100f46:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0100f48:	89 d6                	mov    %edx,%esi
f0100f4a:	03 b3 ac 1f 00 00    	add    0x1fac(%ebx),%esi
	for (int i = 1 ; i < npages_basemem; i++) {
f0100f50:	83 c0 01             	add    $0x1,%eax
f0100f53:	ba 01 00 00 00       	mov    $0x1,%edx
f0100f58:	39 c7                	cmp    %eax,%edi
f0100f5a:	77 d5                	ja     f0100f31 <page_init+0x3e>
f0100f5c:	84 d2                	test   %dl,%dl
f0100f5e:	74 06                	je     f0100f66 <page_init+0x73>
f0100f60:	89 b3 bc 1f 00 00    	mov    %esi,0x1fbc(%ebx)
	uint32_t first_free_pa = (uint32_t) PADDR(boot_alloc(0));
f0100f66:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f6b:	e8 1b fb ff ff       	call   f0100a8b <boot_alloc>
f0100f70:	89 c2                	mov    %eax,%edx
	if ((uint32_t)kva < KERNBASE)
f0100f72:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f77:	76 35                	jbe    f0100fae <page_init+0xbb>
	return (physaddr_t)kva - KERNBASE;
f0100f79:	8d 80 00 00 00 10    	lea    0x10000000(%eax),%eax
	assert(first_free_pa % PGSIZE == 0);
f0100f7f:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0100f85:	75 40                	jne    f0100fc7 <page_init+0xd4>
	int free_pa_pg_indx = first_free_pa / PGSIZE;
f0100f87:	c1 e8 0c             	shr    $0xc,%eax
	for (int i = npages_basemem ; i < free_pa_pg_indx; i++) {
f0100f8a:	8b 93 c0 1f 00 00    	mov    0x1fc0(%ebx),%edx
f0100f90:	39 c2                	cmp    %eax,%edx
f0100f92:	7d 52                	jge    f0100fe6 <page_init+0xf3>
		pages[i].pp_ref = 1;
f0100f94:	8b 8b ac 1f 00 00    	mov    0x1fac(%ebx),%ecx
f0100f9a:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100f9d:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link = NULL;
f0100fa3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	for (int i = npages_basemem ; i < free_pa_pg_indx; i++) {
f0100fa9:	83 c2 01             	add    $0x1,%edx
f0100fac:	eb e2                	jmp    f0100f90 <page_init+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fae:	50                   	push   %eax
f0100faf:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f0100fb5:	50                   	push   %eax
f0100fb6:	68 0b 01 00 00       	push   $0x10b
f0100fbb:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100fc1:	50                   	push   %eax
f0100fc2:	e8 d2 f0 ff ff       	call   f0100099 <_panic>
	assert(first_free_pa % PGSIZE == 0);
f0100fc7:	8d 83 c6 d3 fe ff    	lea    -0x12c3a(%ebx),%eax
f0100fcd:	50                   	push   %eax
f0100fce:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0100fd4:	50                   	push   %eax
f0100fd5:	68 0c 01 00 00       	push   $0x10c
f0100fda:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100fe0:	50                   	push   %eax
f0100fe1:	e8 b3 f0 ff ff       	call   f0100099 <_panic>
f0100fe6:	8b b3 bc 1f 00 00    	mov    0x1fbc(%ebx),%esi
	for (int i = npages_basemem ; i < free_pa_pg_indx; i++) {
f0100fec:	ba 00 00 00 00       	mov    $0x0,%edx
	for (int i = free_pa_pg_indx; i < npages; i++) {
f0100ff1:	bf 01 00 00 00       	mov    $0x1,%edi
f0100ff6:	39 83 b4 1f 00 00    	cmp    %eax,0x1fb4(%ebx)
f0100ffc:	76 26                	jbe    f0101024 <page_init+0x131>
f0100ffe:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0101005:	89 d1                	mov    %edx,%ecx
f0101007:	03 8b ac 1f 00 00    	add    0x1fac(%ebx),%ecx
f010100d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0101013:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0101015:	89 d6                	mov    %edx,%esi
f0101017:	03 b3 ac 1f 00 00    	add    0x1fac(%ebx),%esi
	for (int i = free_pa_pg_indx; i < npages; i++) {
f010101d:	83 c0 01             	add    $0x1,%eax
f0101020:	89 fa                	mov    %edi,%edx
f0101022:	eb d2                	jmp    f0100ff6 <page_init+0x103>
f0101024:	84 d2                	test   %dl,%dl
f0101026:	74 06                	je     f010102e <page_init+0x13b>
f0101028:	89 b3 bc 1f 00 00    	mov    %esi,0x1fbc(%ebx)
}
f010102e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101031:	5b                   	pop    %ebx
f0101032:	5e                   	pop    %esi
f0101033:	5f                   	pop    %edi
f0101034:	5d                   	pop    %ebp
f0101035:	c3                   	ret    

f0101036 <page_alloc>:
{
f0101036:	55                   	push   %ebp
f0101037:	89 e5                	mov    %esp,%ebp
f0101039:	56                   	push   %esi
f010103a:	53                   	push   %ebx
f010103b:	e8 0f f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101040:	81 c3 cc 62 01 00    	add    $0x162cc,%ebx
	struct PageInfo* pp = page_free_list;
f0101046:	8b b3 bc 1f 00 00    	mov    0x1fbc(%ebx),%esi
	if (!pp) {
f010104c:	85 f6                	test   %esi,%esi
f010104e:	74 14                	je     f0101064 <page_alloc+0x2e>
	page_free_list = pp->pp_link;
f0101050:	8b 06                	mov    (%esi),%eax
f0101052:	89 83 bc 1f 00 00    	mov    %eax,0x1fbc(%ebx)
	pp->pp_link = NULL;
f0101058:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO) {
f010105e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101062:	75 09                	jne    f010106d <page_alloc+0x37>
}
f0101064:	89 f0                	mov    %esi,%eax
f0101066:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101069:	5b                   	pop    %ebx
f010106a:	5e                   	pop    %esi
f010106b:	5d                   	pop    %ebp
f010106c:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f010106d:	89 f0                	mov    %esi,%eax
f010106f:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101075:	c1 f8 03             	sar    $0x3,%eax
f0101078:	89 c2                	mov    %eax,%edx
f010107a:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010107d:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101082:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f0101088:	73 1b                	jae    f01010a5 <page_alloc+0x6f>
		memset(page2kva(pp), 0, PGSIZE);
f010108a:	83 ec 04             	sub    $0x4,%esp
f010108d:	68 00 10 00 00       	push   $0x1000
f0101092:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101094:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010109a:	52                   	push   %edx
f010109b:	e8 7f 2c 00 00       	call   f0103d1f <memset>
f01010a0:	83 c4 10             	add    $0x10,%esp
f01010a3:	eb bf                	jmp    f0101064 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010a5:	52                   	push   %edx
f01010a6:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f01010ac:	50                   	push   %eax
f01010ad:	6a 52                	push   $0x52
f01010af:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f01010b5:	50                   	push   %eax
f01010b6:	e8 de ef ff ff       	call   f0100099 <_panic>

f01010bb <page_free>:
{
f01010bb:	55                   	push   %ebp
f01010bc:	89 e5                	mov    %esp,%ebp
f01010be:	53                   	push   %ebx
f01010bf:	83 ec 04             	sub    $0x4,%esp
f01010c2:	e8 88 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010c7:	81 c3 45 62 01 00    	add    $0x16245,%ebx
f01010cd:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);
f01010d0:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010d5:	75 18                	jne    f01010ef <page_free+0x34>
	assert(pp->pp_link == NULL);
f01010d7:	83 38 00             	cmpl   $0x0,(%eax)
f01010da:	75 32                	jne    f010110e <page_free+0x53>
	pp->pp_link = page_free_list;
f01010dc:	8b 8b bc 1f 00 00    	mov    0x1fbc(%ebx),%ecx
f01010e2:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010e4:	89 83 bc 1f 00 00    	mov    %eax,0x1fbc(%ebx)
}
f01010ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010ed:	c9                   	leave  
f01010ee:	c3                   	ret    
	assert(pp->pp_ref == 0);
f01010ef:	8d 83 e2 d3 fe ff    	lea    -0x12c1e(%ebx),%eax
f01010f5:	50                   	push   %eax
f01010f6:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01010fc:	50                   	push   %eax
f01010fd:	68 47 01 00 00       	push   $0x147
f0101102:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101108:	50                   	push   %eax
f0101109:	e8 8b ef ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL);
f010110e:	8d 83 f2 d3 fe ff    	lea    -0x12c0e(%ebx),%eax
f0101114:	50                   	push   %eax
f0101115:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010111b:	50                   	push   %eax
f010111c:	68 48 01 00 00       	push   $0x148
f0101121:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101127:	50                   	push   %eax
f0101128:	e8 6c ef ff ff       	call   f0100099 <_panic>

f010112d <page_decref>:
{
f010112d:	55                   	push   %ebp
f010112e:	89 e5                	mov    %esp,%ebp
f0101130:	83 ec 08             	sub    $0x8,%esp
f0101133:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101136:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010113a:	83 e8 01             	sub    $0x1,%eax
f010113d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101141:	66 85 c0             	test   %ax,%ax
f0101144:	74 02                	je     f0101148 <page_decref+0x1b>
}
f0101146:	c9                   	leave  
f0101147:	c3                   	ret    
		page_free(pp);
f0101148:	83 ec 0c             	sub    $0xc,%esp
f010114b:	52                   	push   %edx
f010114c:	e8 6a ff ff ff       	call   f01010bb <page_free>
f0101151:	83 c4 10             	add    $0x10,%esp
}
f0101154:	eb f0                	jmp    f0101146 <page_decref+0x19>

f0101156 <pgdir_walk>:
{
f0101156:	55                   	push   %ebp
f0101157:	89 e5                	mov    %esp,%ebp
f0101159:	57                   	push   %edi
f010115a:	56                   	push   %esi
f010115b:	53                   	push   %ebx
f010115c:	83 ec 0c             	sub    $0xc,%esp
f010115f:	e8 2f 1f 00 00       	call   f0103093 <__x86.get_pc_thunk.di>
f0101164:	81 c7 a8 61 01 00    	add    $0x161a8,%edi
f010116a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int pte_index = PTX(va);
f010116d:	89 de                	mov    %ebx,%esi
f010116f:	c1 ee 0c             	shr    $0xc,%esi
f0101172:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	int pde_index = PDX(va);
f0101178:	c1 eb 16             	shr    $0x16,%ebx
	pde_t *pde = &pgdir[pde_index];
f010117b:	c1 e3 02             	shl    $0x2,%ebx
f010117e:	03 5d 08             	add    0x8(%ebp),%ebx
	if (!(*pde & PTE_P)) {
f0101181:	f6 03 01             	testb  $0x1,(%ebx)
f0101184:	75 2d                	jne    f01011b3 <pgdir_walk+0x5d>
		if (create) {
f0101186:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010118a:	74 66                	je     f01011f2 <pgdir_walk+0x9c>
			struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010118c:	83 ec 0c             	sub    $0xc,%esp
f010118f:	6a 01                	push   $0x1
f0101191:	e8 a0 fe ff ff       	call   f0101036 <page_alloc>
			if (!page) return NULL;
f0101196:	83 c4 10             	add    $0x10,%esp
f0101199:	85 c0                	test   %eax,%eax
f010119b:	74 32                	je     f01011cf <pgdir_walk+0x79>
			page->pp_ref++;
f010119d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01011a2:	2b 87 ac 1f 00 00    	sub    0x1fac(%edi),%eax
f01011a8:	c1 f8 03             	sar    $0x3,%eax
f01011ab:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f01011ae:	83 c8 07             	or     $0x7,%eax
f01011b1:	89 03                	mov    %eax,(%ebx)
	pte_t *p = (pte_t *) KADDR(PTE_ADDR(*pde));
f01011b3:	8b 03                	mov    (%ebx),%eax
f01011b5:	89 c2                	mov    %eax,%edx
f01011b7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01011bd:	c1 e8 0c             	shr    $0xc,%eax
f01011c0:	3b 87 b4 1f 00 00    	cmp    0x1fb4(%edi),%eax
f01011c6:	73 0f                	jae    f01011d7 <pgdir_walk+0x81>
	return &p[pte_index];
f01011c8:	8d 84 b2 00 00 00 f0 	lea    -0x10000000(%edx,%esi,4),%eax
}
f01011cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d2:	5b                   	pop    %ebx
f01011d3:	5e                   	pop    %esi
f01011d4:	5f                   	pop    %edi
f01011d5:	5d                   	pop    %ebp
f01011d6:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011d7:	52                   	push   %edx
f01011d8:	8d 87 5c d6 fe ff    	lea    -0x129a4(%edi),%eax
f01011de:	50                   	push   %eax
f01011df:	68 81 01 00 00       	push   $0x181
f01011e4:	8d 87 10 d3 fe ff    	lea    -0x12cf0(%edi),%eax
f01011ea:	50                   	push   %eax
f01011eb:	89 fb                	mov    %edi,%ebx
f01011ed:	e8 a7 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f01011f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f7:	eb d6                	jmp    f01011cf <pgdir_walk+0x79>

f01011f9 <boot_map_region>:
{
f01011f9:	55                   	push   %ebp
f01011fa:	89 e5                	mov    %esp,%ebp
f01011fc:	57                   	push   %edi
f01011fd:	56                   	push   %esi
f01011fe:	53                   	push   %ebx
f01011ff:	83 ec 1c             	sub    $0x1c,%esp
f0101202:	e8 8c 1e 00 00       	call   f0103093 <__x86.get_pc_thunk.di>
f0101207:	81 c7 05 61 01 00    	add    $0x16105,%edi
f010120d:	89 7d dc             	mov    %edi,-0x24(%ebp)
f0101210:	89 c7                	mov    %eax,%edi
f0101212:	8b 45 08             	mov    0x8(%ebp),%eax
	int pages = PGNUM(size);
f0101215:	c1 e9 0c             	shr    $0xc,%ecx
f0101218:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (int i = 0; i < pages; i++) {
f010121b:	89 c3                	mov    %eax,%ebx
f010121d:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);
f0101222:	29 c2                	sub    %eax,%edx
f0101224:	89 55 e0             	mov    %edx,-0x20(%ebp)
	for (int i = 0; i < pages; i++) {
f0101227:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010122a:	7d 4b                	jge    f0101277 <boot_map_region+0x7e>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);
f010122c:	83 ec 04             	sub    $0x4,%esp
f010122f:	6a 01                	push   $0x1
f0101231:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101234:	01 d8                	add    %ebx,%eax
f0101236:	50                   	push   %eax
f0101237:	57                   	push   %edi
f0101238:	e8 19 ff ff ff       	call   f0101156 <pgdir_walk>
		if (!pte) {
f010123d:	83 c4 10             	add    $0x10,%esp
f0101240:	85 c0                	test   %eax,%eax
f0101242:	74 15                	je     f0101259 <boot_map_region+0x60>
		*pte = pa | perm | PTE_P;
f0101244:	89 da                	mov    %ebx,%edx
f0101246:	0b 55 0c             	or     0xc(%ebp),%edx
f0101249:	83 ca 01             	or     $0x1,%edx
f010124c:	89 10                	mov    %edx,(%eax)
		va += PGSIZE, pa += PGSIZE;
f010124e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (int i = 0; i < pages; i++) {
f0101254:	83 c6 01             	add    $0x1,%esi
f0101257:	eb ce                	jmp    f0101227 <boot_map_region+0x2e>
			panic("boot_map_region panic: out of memory");
f0101259:	83 ec 04             	sub    $0x4,%esp
f010125c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010125f:	8d 83 8c d7 fe ff    	lea    -0x12874(%ebx),%eax
f0101265:	50                   	push   %eax
f0101266:	68 98 01 00 00       	push   $0x198
f010126b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101271:	50                   	push   %eax
f0101272:	e8 22 ee ff ff       	call   f0100099 <_panic>
}
f0101277:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010127a:	5b                   	pop    %ebx
f010127b:	5e                   	pop    %esi
f010127c:	5f                   	pop    %edi
f010127d:	5d                   	pop    %ebp
f010127e:	c3                   	ret    

f010127f <page_lookup>:
{
f010127f:	55                   	push   %ebp
f0101280:	89 e5                	mov    %esp,%ebp
f0101282:	56                   	push   %esi
f0101283:	53                   	push   %ebx
f0101284:	e8 c6 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101289:	81 c3 83 60 01 00    	add    $0x16083,%ebx
f010128f:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101292:	83 ec 04             	sub    $0x4,%esp
f0101295:	6a 00                	push   $0x0
f0101297:	ff 75 0c             	push   0xc(%ebp)
f010129a:	ff 75 08             	push   0x8(%ebp)
f010129d:	e8 b4 fe ff ff       	call   f0101156 <pgdir_walk>
	if (!pte || !(*pte & PTE_P)) {
f01012a2:	83 c4 10             	add    $0x10,%esp
f01012a5:	85 c0                	test   %eax,%eax
f01012a7:	74 21                	je     f01012ca <page_lookup+0x4b>
f01012a9:	f6 00 01             	testb  $0x1,(%eax)
f01012ac:	74 3b                	je     f01012e9 <page_lookup+0x6a>
	if (pte_store) {
f01012ae:	85 f6                	test   %esi,%esi
f01012b0:	74 02                	je     f01012b4 <page_lookup+0x35>
		*pte_store = pte;
f01012b2:	89 06                	mov    %eax,(%esi)
f01012b4:	8b 00                	mov    (%eax),%eax
f01012b6:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012b9:	39 83 b4 1f 00 00    	cmp    %eax,0x1fb4(%ebx)
f01012bf:	76 10                	jbe    f01012d1 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01012c1:	8b 93 ac 1f 00 00    	mov    0x1fac(%ebx),%edx
f01012c7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01012ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012cd:	5b                   	pop    %ebx
f01012ce:	5e                   	pop    %esi
f01012cf:	5d                   	pop    %ebp
f01012d0:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01012d1:	83 ec 04             	sub    $0x4,%esp
f01012d4:	8d 83 b4 d7 fe ff    	lea    -0x1284c(%ebx),%eax
f01012da:	50                   	push   %eax
f01012db:	6a 4b                	push   $0x4b
f01012dd:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f01012e3:	50                   	push   %eax
f01012e4:	e8 b0 ed ff ff       	call   f0100099 <_panic>
		return NULL;
f01012e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ee:	eb da                	jmp    f01012ca <page_lookup+0x4b>

f01012f0 <page_remove>:
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	53                   	push   %ebx
f01012f4:	83 ec 18             	sub    $0x18,%esp
f01012f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *page = page_lookup(pgdir, va, &pte);
f01012fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012fd:	50                   	push   %eax
f01012fe:	53                   	push   %ebx
f01012ff:	ff 75 08             	push   0x8(%ebp)
f0101302:	e8 78 ff ff ff       	call   f010127f <page_lookup>
	if (!page || !(*pte & PTE_P)) {
f0101307:	83 c4 10             	add    $0x10,%esp
f010130a:	85 c0                	test   %eax,%eax
f010130c:	74 08                	je     f0101316 <page_remove+0x26>
f010130e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101311:	f6 02 01             	testb  $0x1,(%edx)
f0101314:	75 05                	jne    f010131b <page_remove+0x2b>
}
f0101316:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101319:	c9                   	leave  
f010131a:	c3                   	ret    
	*pte = 0;
f010131b:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	page_decref(page);
f0101321:	83 ec 0c             	sub    $0xc,%esp
f0101324:	50                   	push   %eax
f0101325:	e8 03 fe ff ff       	call   f010112d <page_decref>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010132a:	0f 01 3b             	invlpg (%ebx)
f010132d:	83 c4 10             	add    $0x10,%esp
f0101330:	eb e4                	jmp    f0101316 <page_remove+0x26>

f0101332 <page_insert>:
{
f0101332:	55                   	push   %ebp
f0101333:	89 e5                	mov    %esp,%ebp
f0101335:	57                   	push   %edi
f0101336:	56                   	push   %esi
f0101337:	53                   	push   %ebx
f0101338:	83 ec 10             	sub    $0x10,%esp
f010133b:	e8 53 1d 00 00       	call   f0103093 <__x86.get_pc_thunk.di>
f0101340:	81 c7 cc 5f 01 00    	add    $0x15fcc,%edi
f0101346:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101349:	6a 01                	push   $0x1
f010134b:	ff 75 10             	push   0x10(%ebp)
f010134e:	ff 75 08             	push   0x8(%ebp)
f0101351:	e8 00 fe ff ff       	call   f0101156 <pgdir_walk>
	if (!pte) {
f0101356:	83 c4 10             	add    $0x10,%esp
f0101359:	85 c0                	test   %eax,%eax
f010135b:	74 40                	je     f010139d <page_insert+0x6b>
f010135d:	89 c6                	mov    %eax,%esi
	pp->pp_ref++;
f010135f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte & PTE_P) {
f0101364:	f6 00 01             	testb  $0x1,(%eax)
f0101367:	75 21                	jne    f010138a <page_insert+0x58>
	return (pp - pages) << PGSHIFT;
f0101369:	2b 9f ac 1f 00 00    	sub    0x1fac(%edi),%ebx
f010136f:	c1 fb 03             	sar    $0x3,%ebx
f0101372:	c1 e3 0c             	shl    $0xc,%ebx
	*pte = page2pa(pp) | perm | PTE_P;
f0101375:	0b 5d 14             	or     0x14(%ebp),%ebx
f0101378:	83 cb 01             	or     $0x1,%ebx
f010137b:	89 1e                	mov    %ebx,(%esi)
	return 0;
f010137d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101382:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101385:	5b                   	pop    %ebx
f0101386:	5e                   	pop    %esi
f0101387:	5f                   	pop    %edi
f0101388:	5d                   	pop    %ebp
f0101389:	c3                   	ret    
		page_remove(pgdir, va);
f010138a:	83 ec 08             	sub    $0x8,%esp
f010138d:	ff 75 10             	push   0x10(%ebp)
f0101390:	ff 75 08             	push   0x8(%ebp)
f0101393:	e8 58 ff ff ff       	call   f01012f0 <page_remove>
f0101398:	83 c4 10             	add    $0x10,%esp
f010139b:	eb cc                	jmp    f0101369 <page_insert+0x37>
		return -E_NO_MEM;
f010139d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01013a2:	eb de                	jmp    f0101382 <page_insert+0x50>

f01013a4 <mem_init>:
{
f01013a4:	55                   	push   %ebp
f01013a5:	89 e5                	mov    %esp,%ebp
f01013a7:	57                   	push   %edi
f01013a8:	56                   	push   %esi
f01013a9:	53                   	push   %ebx
f01013aa:	83 ec 3c             	sub    $0x3c,%esp
f01013ad:	e8 2f f3 ff ff       	call   f01006e1 <__x86.get_pc_thunk.ax>
f01013b2:	05 5a 5f 01 00       	add    $0x15f5a,%eax
f01013b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f01013ba:	b8 15 00 00 00       	mov    $0x15,%eax
f01013bf:	e8 91 f6 ff ff       	call   f0100a55 <nvram_read>
f01013c4:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01013c6:	b8 17 00 00 00       	mov    $0x17,%eax
f01013cb:	e8 85 f6 ff ff       	call   f0100a55 <nvram_read>
f01013d0:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013d2:	b8 34 00 00 00       	mov    $0x34,%eax
f01013d7:	e8 79 f6 ff ff       	call   f0100a55 <nvram_read>
	if (ext16mem)
f01013dc:	c1 e0 06             	shl    $0x6,%eax
f01013df:	0f 84 ec 00 00 00    	je     f01014d1 <mem_init+0x12d>
		totalmem = 16 * 1024 + ext16mem;
f01013e5:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013ea:	89 c2                	mov    %eax,%edx
f01013ec:	c1 ea 02             	shr    $0x2,%edx
f01013ef:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013f2:	89 97 b4 1f 00 00    	mov    %edx,0x1fb4(%edi)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013f8:	89 da                	mov    %ebx,%edx
f01013fa:	c1 ea 02             	shr    $0x2,%edx
f01013fd:	89 97 c0 1f 00 00    	mov    %edx,0x1fc0(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101403:	89 c2                	mov    %eax,%edx
f0101405:	29 da                	sub    %ebx,%edx
f0101407:	52                   	push   %edx
f0101408:	53                   	push   %ebx
f0101409:	50                   	push   %eax
f010140a:	8d 87 d4 d7 fe ff    	lea    -0x1282c(%edi),%eax
f0101410:	50                   	push   %eax
f0101411:	89 fb                	mov    %edi,%ebx
f0101413:	e8 06 1d 00 00       	call   f010311e <cprintf>
	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f0101418:	8b 87 b4 1f 00 00    	mov    0x1fb4(%edi),%eax
f010141e:	c1 e0 03             	shl    $0x3,%eax
f0101421:	e8 65 f6 ff ff       	call   f0100a8b <boot_alloc>
f0101426:	89 87 ac 1f 00 00    	mov    %eax,0x1fac(%edi)
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010142c:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101431:	e8 55 f6 ff ff       	call   f0100a8b <boot_alloc>
f0101436:	89 87 b0 1f 00 00    	mov    %eax,0x1fb0(%edi)
	memset(kern_pgdir, 0, PGSIZE);
f010143c:	83 c4 0c             	add    $0xc,%esp
f010143f:	68 00 10 00 00       	push   $0x1000
f0101444:	6a 00                	push   $0x0
f0101446:	50                   	push   %eax
f0101447:	e8 d3 28 00 00       	call   f0103d1f <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010144c:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101452:	83 c4 10             	add    $0x10,%esp
f0101455:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010145a:	0f 86 81 00 00 00    	jbe    f01014e1 <mem_init+0x13d>
	return (physaddr_t)kva - KERNBASE;
f0101460:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101466:	83 ca 05             	or     $0x5,%edx
f0101469:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * 	sizeof(struct PageInfo));
f010146f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101472:	8b 87 b4 1f 00 00    	mov    0x1fb4(%edi),%eax
f0101478:	c1 e0 03             	shl    $0x3,%eax
f010147b:	e8 0b f6 ff ff       	call   f0100a8b <boot_alloc>
f0101480:	89 87 ac 1f 00 00    	mov    %eax,0x1fac(%edi)
	uintptr_t pages_region_sz = (uintptr_t)boot_alloc(0) - (uintptr_t)pages;
f0101486:	b8 00 00 00 00       	mov    $0x0,%eax
f010148b:	e8 fb f5 ff ff       	call   f0100a8b <boot_alloc>
f0101490:	8b 97 ac 1f 00 00    	mov    0x1fac(%edi),%edx
	memset(pages, 0, pages_region_sz);
f0101496:	83 ec 04             	sub    $0x4,%esp
	uintptr_t pages_region_sz = (uintptr_t)boot_alloc(0) - (uintptr_t)pages;
f0101499:	29 d0                	sub    %edx,%eax
	memset(pages, 0, pages_region_sz);
f010149b:	50                   	push   %eax
f010149c:	6a 00                	push   $0x0
f010149e:	52                   	push   %edx
f010149f:	89 fb                	mov    %edi,%ebx
f01014a1:	e8 79 28 00 00       	call   f0103d1f <memset>
	page_init();
f01014a6:	e8 48 fa ff ff       	call   f0100ef3 <page_init>
	check_page_free_list(1);
f01014ab:	b8 01 00 00 00       	mov    $0x1,%eax
f01014b0:	e8 d2 f6 ff ff       	call   f0100b87 <check_page_free_list>
	if (!pages)
f01014b5:	83 c4 10             	add    $0x10,%esp
f01014b8:	83 bf ac 1f 00 00 00 	cmpl   $0x0,0x1fac(%edi)
f01014bf:	74 3c                	je     f01014fd <mem_init+0x159>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014c4:	8b 80 bc 1f 00 00    	mov    0x1fbc(%eax),%eax
f01014ca:	be 00 00 00 00       	mov    $0x0,%esi
f01014cf:	eb 4f                	jmp    f0101520 <mem_init+0x17c>
		totalmem = 1 * 1024 + extmem;
f01014d1:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01014d7:	85 f6                	test   %esi,%esi
f01014d9:	0f 44 c3             	cmove  %ebx,%eax
f01014dc:	e9 09 ff ff ff       	jmp    f01013ea <mem_init+0x46>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014e1:	50                   	push   %eax
f01014e2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014e5:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f01014eb:	50                   	push   %eax
f01014ec:	68 94 00 00 00       	push   $0x94
f01014f1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01014f7:	50                   	push   %eax
f01014f8:	e8 9c eb ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f01014fd:	83 ec 04             	sub    $0x4,%esp
f0101500:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101503:	8d 83 06 d4 fe ff    	lea    -0x12bfa(%ebx),%eax
f0101509:	50                   	push   %eax
f010150a:	68 5e 02 00 00       	push   $0x25e
f010150f:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101515:	50                   	push   %eax
f0101516:	e8 7e eb ff ff       	call   f0100099 <_panic>
		++nfree;
f010151b:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010151e:	8b 00                	mov    (%eax),%eax
f0101520:	85 c0                	test   %eax,%eax
f0101522:	75 f7                	jne    f010151b <mem_init+0x177>
	assert((pp0 = page_alloc(0)));
f0101524:	83 ec 0c             	sub    $0xc,%esp
f0101527:	6a 00                	push   $0x0
f0101529:	e8 08 fb ff ff       	call   f0101036 <page_alloc>
f010152e:	89 c3                	mov    %eax,%ebx
f0101530:	83 c4 10             	add    $0x10,%esp
f0101533:	85 c0                	test   %eax,%eax
f0101535:	0f 84 3a 02 00 00    	je     f0101775 <mem_init+0x3d1>
	assert((pp1 = page_alloc(0)));
f010153b:	83 ec 0c             	sub    $0xc,%esp
f010153e:	6a 00                	push   $0x0
f0101540:	e8 f1 fa ff ff       	call   f0101036 <page_alloc>
f0101545:	89 c7                	mov    %eax,%edi
f0101547:	83 c4 10             	add    $0x10,%esp
f010154a:	85 c0                	test   %eax,%eax
f010154c:	0f 84 45 02 00 00    	je     f0101797 <mem_init+0x3f3>
	assert((pp2 = page_alloc(0)));
f0101552:	83 ec 0c             	sub    $0xc,%esp
f0101555:	6a 00                	push   $0x0
f0101557:	e8 da fa ff ff       	call   f0101036 <page_alloc>
f010155c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010155f:	83 c4 10             	add    $0x10,%esp
f0101562:	85 c0                	test   %eax,%eax
f0101564:	0f 84 4f 02 00 00    	je     f01017b9 <mem_init+0x415>
	assert(pp1 && pp1 != pp0);
f010156a:	39 fb                	cmp    %edi,%ebx
f010156c:	0f 84 69 02 00 00    	je     f01017db <mem_init+0x437>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101572:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101575:	39 c7                	cmp    %eax,%edi
f0101577:	0f 84 80 02 00 00    	je     f01017fd <mem_init+0x459>
f010157d:	39 c3                	cmp    %eax,%ebx
f010157f:	0f 84 78 02 00 00    	je     f01017fd <mem_init+0x459>
	return (pp - pages) << PGSHIFT;
f0101585:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101588:	8b 88 ac 1f 00 00    	mov    0x1fac(%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010158e:	8b 90 b4 1f 00 00    	mov    0x1fb4(%eax),%edx
f0101594:	c1 e2 0c             	shl    $0xc,%edx
f0101597:	89 d8                	mov    %ebx,%eax
f0101599:	29 c8                	sub    %ecx,%eax
f010159b:	c1 f8 03             	sar    $0x3,%eax
f010159e:	c1 e0 0c             	shl    $0xc,%eax
f01015a1:	39 d0                	cmp    %edx,%eax
f01015a3:	0f 83 76 02 00 00    	jae    f010181f <mem_init+0x47b>
f01015a9:	89 f8                	mov    %edi,%eax
f01015ab:	29 c8                	sub    %ecx,%eax
f01015ad:	c1 f8 03             	sar    $0x3,%eax
f01015b0:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01015b3:	39 c2                	cmp    %eax,%edx
f01015b5:	0f 86 86 02 00 00    	jbe    f0101841 <mem_init+0x49d>
f01015bb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015be:	29 c8                	sub    %ecx,%eax
f01015c0:	c1 f8 03             	sar    $0x3,%eax
f01015c3:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015c6:	39 c2                	cmp    %eax,%edx
f01015c8:	0f 86 95 02 00 00    	jbe    f0101863 <mem_init+0x4bf>
	fl = page_free_list;
f01015ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015d1:	8b 88 bc 1f 00 00    	mov    0x1fbc(%eax),%ecx
f01015d7:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01015da:	c7 80 bc 1f 00 00 00 	movl   $0x0,0x1fbc(%eax)
f01015e1:	00 00 00 
	assert(!page_alloc(0));
f01015e4:	83 ec 0c             	sub    $0xc,%esp
f01015e7:	6a 00                	push   $0x0
f01015e9:	e8 48 fa ff ff       	call   f0101036 <page_alloc>
f01015ee:	83 c4 10             	add    $0x10,%esp
f01015f1:	85 c0                	test   %eax,%eax
f01015f3:	0f 85 8c 02 00 00    	jne    f0101885 <mem_init+0x4e1>
	page_free(pp0);
f01015f9:	83 ec 0c             	sub    $0xc,%esp
f01015fc:	53                   	push   %ebx
f01015fd:	e8 b9 fa ff ff       	call   f01010bb <page_free>
	page_free(pp1);
f0101602:	89 3c 24             	mov    %edi,(%esp)
f0101605:	e8 b1 fa ff ff       	call   f01010bb <page_free>
	page_free(pp2);
f010160a:	83 c4 04             	add    $0x4,%esp
f010160d:	ff 75 d0             	push   -0x30(%ebp)
f0101610:	e8 a6 fa ff ff       	call   f01010bb <page_free>
	assert((pp0 = page_alloc(0)));
f0101615:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010161c:	e8 15 fa ff ff       	call   f0101036 <page_alloc>
f0101621:	89 c7                	mov    %eax,%edi
f0101623:	83 c4 10             	add    $0x10,%esp
f0101626:	85 c0                	test   %eax,%eax
f0101628:	0f 84 79 02 00 00    	je     f01018a7 <mem_init+0x503>
	assert((pp1 = page_alloc(0)));
f010162e:	83 ec 0c             	sub    $0xc,%esp
f0101631:	6a 00                	push   $0x0
f0101633:	e8 fe f9 ff ff       	call   f0101036 <page_alloc>
f0101638:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	0f 84 83 02 00 00    	je     f01018c9 <mem_init+0x525>
	assert((pp2 = page_alloc(0)));
f0101646:	83 ec 0c             	sub    $0xc,%esp
f0101649:	6a 00                	push   $0x0
f010164b:	e8 e6 f9 ff ff       	call   f0101036 <page_alloc>
f0101650:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101653:	83 c4 10             	add    $0x10,%esp
f0101656:	85 c0                	test   %eax,%eax
f0101658:	0f 84 8d 02 00 00    	je     f01018eb <mem_init+0x547>
	assert(pp1 && pp1 != pp0);
f010165e:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101661:	0f 84 a6 02 00 00    	je     f010190d <mem_init+0x569>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101667:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010166a:	39 c7                	cmp    %eax,%edi
f010166c:	0f 84 bd 02 00 00    	je     f010192f <mem_init+0x58b>
f0101672:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101675:	0f 84 b4 02 00 00    	je     f010192f <mem_init+0x58b>
	assert(!page_alloc(0));
f010167b:	83 ec 0c             	sub    $0xc,%esp
f010167e:	6a 00                	push   $0x0
f0101680:	e8 b1 f9 ff ff       	call   f0101036 <page_alloc>
f0101685:	83 c4 10             	add    $0x10,%esp
f0101688:	85 c0                	test   %eax,%eax
f010168a:	0f 85 c1 02 00 00    	jne    f0101951 <mem_init+0x5ad>
f0101690:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101693:	89 f8                	mov    %edi,%eax
f0101695:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f010169b:	c1 f8 03             	sar    $0x3,%eax
f010169e:	89 c2                	mov    %eax,%edx
f01016a0:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016a3:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01016a8:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f01016ae:	0f 83 bf 02 00 00    	jae    f0101973 <mem_init+0x5cf>
	memset(page2kva(pp0), 1, PGSIZE);
f01016b4:	83 ec 04             	sub    $0x4,%esp
f01016b7:	68 00 10 00 00       	push   $0x1000
f01016bc:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016be:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01016c4:	52                   	push   %edx
f01016c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016c8:	e8 52 26 00 00       	call   f0103d1f <memset>
	page_free(pp0);
f01016cd:	89 3c 24             	mov    %edi,(%esp)
f01016d0:	e8 e6 f9 ff ff       	call   f01010bb <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016d5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016dc:	e8 55 f9 ff ff       	call   f0101036 <page_alloc>
f01016e1:	83 c4 10             	add    $0x10,%esp
f01016e4:	85 c0                	test   %eax,%eax
f01016e6:	0f 84 9f 02 00 00    	je     f010198b <mem_init+0x5e7>
	assert(pp && pp0 == pp);
f01016ec:	39 c7                	cmp    %eax,%edi
f01016ee:	0f 85 b9 02 00 00    	jne    f01019ad <mem_init+0x609>
	return (pp - pages) << PGSHIFT;
f01016f4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01016f7:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f01016fd:	c1 f8 03             	sar    $0x3,%eax
f0101700:	89 c2                	mov    %eax,%edx
f0101702:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101705:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010170a:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0101710:	0f 83 b9 02 00 00    	jae    f01019cf <mem_init+0x62b>
	return (void *)(pa + KERNBASE);
f0101716:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010171c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101722:	80 38 00             	cmpb   $0x0,(%eax)
f0101725:	0f 85 bc 02 00 00    	jne    f01019e7 <mem_init+0x643>
	for (i = 0; i < PGSIZE; i++)
f010172b:	83 c0 01             	add    $0x1,%eax
f010172e:	39 c2                	cmp    %eax,%edx
f0101730:	75 f0                	jne    f0101722 <mem_init+0x37e>
	page_free_list = fl;
f0101732:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101735:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101738:	89 8b bc 1f 00 00    	mov    %ecx,0x1fbc(%ebx)
	page_free(pp0);
f010173e:	83 ec 0c             	sub    $0xc,%esp
f0101741:	57                   	push   %edi
f0101742:	e8 74 f9 ff ff       	call   f01010bb <page_free>
	page_free(pp1);
f0101747:	83 c4 04             	add    $0x4,%esp
f010174a:	ff 75 d0             	push   -0x30(%ebp)
f010174d:	e8 69 f9 ff ff       	call   f01010bb <page_free>
	page_free(pp2);
f0101752:	83 c4 04             	add    $0x4,%esp
f0101755:	ff 75 cc             	push   -0x34(%ebp)
f0101758:	e8 5e f9 ff ff       	call   f01010bb <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010175d:	8b 83 bc 1f 00 00    	mov    0x1fbc(%ebx),%eax
f0101763:	83 c4 10             	add    $0x10,%esp
f0101766:	85 c0                	test   %eax,%eax
f0101768:	0f 84 9b 02 00 00    	je     f0101a09 <mem_init+0x665>
		--nfree;
f010176e:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101771:	8b 00                	mov    (%eax),%eax
f0101773:	eb f1                	jmp    f0101766 <mem_init+0x3c2>
	assert((pp0 = page_alloc(0)));
f0101775:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101778:	8d 83 21 d4 fe ff    	lea    -0x12bdf(%ebx),%eax
f010177e:	50                   	push   %eax
f010177f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0101785:	50                   	push   %eax
f0101786:	68 66 02 00 00       	push   $0x266
f010178b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101791:	50                   	push   %eax
f0101792:	e8 02 e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101797:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010179a:	8d 83 37 d4 fe ff    	lea    -0x12bc9(%ebx),%eax
f01017a0:	50                   	push   %eax
f01017a1:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01017a7:	50                   	push   %eax
f01017a8:	68 67 02 00 00       	push   $0x267
f01017ad:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01017b3:	50                   	push   %eax
f01017b4:	e8 e0 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01017b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017bc:	8d 83 4d d4 fe ff    	lea    -0x12bb3(%ebx),%eax
f01017c2:	50                   	push   %eax
f01017c3:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01017c9:	50                   	push   %eax
f01017ca:	68 68 02 00 00       	push   $0x268
f01017cf:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01017d5:	50                   	push   %eax
f01017d6:	e8 be e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01017db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017de:	8d 83 63 d4 fe ff    	lea    -0x12b9d(%ebx),%eax
f01017e4:	50                   	push   %eax
f01017e5:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01017eb:	50                   	push   %eax
f01017ec:	68 6b 02 00 00       	push   $0x26b
f01017f1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01017f7:	50                   	push   %eax
f01017f8:	e8 9c e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101800:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0101806:	50                   	push   %eax
f0101807:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010180d:	50                   	push   %eax
f010180e:	68 6c 02 00 00       	push   $0x26c
f0101813:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101819:	50                   	push   %eax
f010181a:	e8 7a e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010181f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101822:	8d 83 75 d4 fe ff    	lea    -0x12b8b(%ebx),%eax
f0101828:	50                   	push   %eax
f0101829:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010182f:	50                   	push   %eax
f0101830:	68 6d 02 00 00       	push   $0x26d
f0101835:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010183b:	50                   	push   %eax
f010183c:	e8 58 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101841:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101844:	8d 83 92 d4 fe ff    	lea    -0x12b6e(%ebx),%eax
f010184a:	50                   	push   %eax
f010184b:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0101851:	50                   	push   %eax
f0101852:	68 6e 02 00 00       	push   $0x26e
f0101857:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010185d:	50                   	push   %eax
f010185e:	e8 36 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101863:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101866:	8d 83 af d4 fe ff    	lea    -0x12b51(%ebx),%eax
f010186c:	50                   	push   %eax
f010186d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0101873:	50                   	push   %eax
f0101874:	68 6f 02 00 00       	push   $0x26f
f0101879:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010187f:	50                   	push   %eax
f0101880:	e8 14 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101885:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101888:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010188e:	50                   	push   %eax
f010188f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0101895:	50                   	push   %eax
f0101896:	68 76 02 00 00       	push   $0x276
f010189b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01018a1:	50                   	push   %eax
f01018a2:	e8 f2 e7 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01018a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018aa:	8d 83 21 d4 fe ff    	lea    -0x12bdf(%ebx),%eax
f01018b0:	50                   	push   %eax
f01018b1:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01018b7:	50                   	push   %eax
f01018b8:	68 7d 02 00 00       	push   $0x27d
f01018bd:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01018c3:	50                   	push   %eax
f01018c4:	e8 d0 e7 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01018c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018cc:	8d 83 37 d4 fe ff    	lea    -0x12bc9(%ebx),%eax
f01018d2:	50                   	push   %eax
f01018d3:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01018d9:	50                   	push   %eax
f01018da:	68 7e 02 00 00       	push   $0x27e
f01018df:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01018e5:	50                   	push   %eax
f01018e6:	e8 ae e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01018eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018ee:	8d 83 4d d4 fe ff    	lea    -0x12bb3(%ebx),%eax
f01018f4:	50                   	push   %eax
f01018f5:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01018fb:	50                   	push   %eax
f01018fc:	68 7f 02 00 00       	push   $0x27f
f0101901:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101907:	50                   	push   %eax
f0101908:	e8 8c e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010190d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101910:	8d 83 63 d4 fe ff    	lea    -0x12b9d(%ebx),%eax
f0101916:	50                   	push   %eax
f0101917:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010191d:	50                   	push   %eax
f010191e:	68 81 02 00 00       	push   $0x281
f0101923:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101929:	50                   	push   %eax
f010192a:	e8 6a e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010192f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101932:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0101938:	50                   	push   %eax
f0101939:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010193f:	50                   	push   %eax
f0101940:	68 82 02 00 00       	push   $0x282
f0101945:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010194b:	50                   	push   %eax
f010194c:	e8 48 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101951:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101954:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010195a:	50                   	push   %eax
f010195b:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0101961:	50                   	push   %eax
f0101962:	68 83 02 00 00       	push   $0x283
f0101967:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010196d:	50                   	push   %eax
f010196e:	e8 26 e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101973:	52                   	push   %edx
f0101974:	89 cb                	mov    %ecx,%ebx
f0101976:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f010197c:	50                   	push   %eax
f010197d:	6a 52                	push   $0x52
f010197f:	8d 81 1c d3 fe ff    	lea    -0x12ce4(%ecx),%eax
f0101985:	50                   	push   %eax
f0101986:	e8 0e e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010198b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010198e:	8d 83 db d4 fe ff    	lea    -0x12b25(%ebx),%eax
f0101994:	50                   	push   %eax
f0101995:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010199b:	50                   	push   %eax
f010199c:	68 88 02 00 00       	push   $0x288
f01019a1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01019a7:	50                   	push   %eax
f01019a8:	e8 ec e6 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01019ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b0:	8d 83 f9 d4 fe ff    	lea    -0x12b07(%ebx),%eax
f01019b6:	50                   	push   %eax
f01019b7:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01019bd:	50                   	push   %eax
f01019be:	68 89 02 00 00       	push   $0x289
f01019c3:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01019c9:	50                   	push   %eax
f01019ca:	e8 ca e6 ff ff       	call   f0100099 <_panic>
f01019cf:	52                   	push   %edx
f01019d0:	89 cb                	mov    %ecx,%ebx
f01019d2:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f01019d8:	50                   	push   %eax
f01019d9:	6a 52                	push   $0x52
f01019db:	8d 81 1c d3 fe ff    	lea    -0x12ce4(%ecx),%eax
f01019e1:	50                   	push   %eax
f01019e2:	e8 b2 e6 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f01019e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019ea:	8d 83 09 d5 fe ff    	lea    -0x12af7(%ebx),%eax
f01019f0:	50                   	push   %eax
f01019f1:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01019f7:	50                   	push   %eax
f01019f8:	68 8c 02 00 00       	push   $0x28c
f01019fd:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0101a03:	50                   	push   %eax
f0101a04:	e8 90 e6 ff ff       	call   f0100099 <_panic>
	assert(nfree == 0);
f0101a09:	85 f6                	test   %esi,%esi
f0101a0b:	0f 85 2b 08 00 00    	jne    f010223c <mem_init+0xe98>
	cprintf("check_page_alloc() succeeded!\n");
f0101a11:	83 ec 0c             	sub    $0xc,%esp
f0101a14:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a17:	8d 83 30 d8 fe ff    	lea    -0x127d0(%ebx),%eax
f0101a1d:	50                   	push   %eax
f0101a1e:	e8 fb 16 00 00       	call   f010311e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a2a:	e8 07 f6 ff ff       	call   f0101036 <page_alloc>
f0101a2f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a32:	83 c4 10             	add    $0x10,%esp
f0101a35:	85 c0                	test   %eax,%eax
f0101a37:	0f 84 21 08 00 00    	je     f010225e <mem_init+0xeba>
	assert((pp1 = page_alloc(0)));
f0101a3d:	83 ec 0c             	sub    $0xc,%esp
f0101a40:	6a 00                	push   $0x0
f0101a42:	e8 ef f5 ff ff       	call   f0101036 <page_alloc>
f0101a47:	89 c7                	mov    %eax,%edi
f0101a49:	83 c4 10             	add    $0x10,%esp
f0101a4c:	85 c0                	test   %eax,%eax
f0101a4e:	0f 84 2c 08 00 00    	je     f0102280 <mem_init+0xedc>
	assert((pp2 = page_alloc(0)));
f0101a54:	83 ec 0c             	sub    $0xc,%esp
f0101a57:	6a 00                	push   $0x0
f0101a59:	e8 d8 f5 ff ff       	call   f0101036 <page_alloc>
f0101a5e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a61:	83 c4 10             	add    $0x10,%esp
f0101a64:	85 c0                	test   %eax,%eax
f0101a66:	0f 84 36 08 00 00    	je     f01022a2 <mem_init+0xefe>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a6c:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101a6f:	0f 84 4f 08 00 00    	je     f01022c4 <mem_init+0xf20>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a75:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a78:	39 c7                	cmp    %eax,%edi
f0101a7a:	0f 84 66 08 00 00    	je     f01022e6 <mem_init+0xf42>
f0101a80:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101a83:	0f 84 5d 08 00 00    	je     f01022e6 <mem_init+0xf42>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a8c:	8b 88 bc 1f 00 00    	mov    0x1fbc(%eax),%ecx
f0101a92:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101a95:	c7 80 bc 1f 00 00 00 	movl   $0x0,0x1fbc(%eax)
f0101a9c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a9f:	83 ec 0c             	sub    $0xc,%esp
f0101aa2:	6a 00                	push   $0x0
f0101aa4:	e8 8d f5 ff ff       	call   f0101036 <page_alloc>
f0101aa9:	83 c4 10             	add    $0x10,%esp
f0101aac:	85 c0                	test   %eax,%eax
f0101aae:	0f 85 54 08 00 00    	jne    f0102308 <mem_init+0xf64>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101ab4:	83 ec 04             	sub    $0x4,%esp
f0101ab7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101aba:	50                   	push   %eax
f0101abb:	6a 00                	push   $0x0
f0101abd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac0:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101ac6:	e8 b4 f7 ff ff       	call   f010127f <page_lookup>
f0101acb:	83 c4 10             	add    $0x10,%esp
f0101ace:	85 c0                	test   %eax,%eax
f0101ad0:	0f 85 54 08 00 00    	jne    f010232a <mem_init+0xf86>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ad6:	6a 02                	push   $0x2
f0101ad8:	6a 00                	push   $0x0
f0101ada:	57                   	push   %edi
f0101adb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ade:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101ae4:	e8 49 f8 ff ff       	call   f0101332 <page_insert>
f0101ae9:	83 c4 10             	add    $0x10,%esp
f0101aec:	85 c0                	test   %eax,%eax
f0101aee:	0f 89 58 08 00 00    	jns    f010234c <mem_init+0xfa8>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101af4:	83 ec 0c             	sub    $0xc,%esp
f0101af7:	ff 75 cc             	push   -0x34(%ebp)
f0101afa:	e8 bc f5 ff ff       	call   f01010bb <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aff:	6a 02                	push   $0x2
f0101b01:	6a 00                	push   $0x0
f0101b03:	57                   	push   %edi
f0101b04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b07:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101b0d:	e8 20 f8 ff ff       	call   f0101332 <page_insert>
f0101b12:	83 c4 20             	add    $0x20,%esp
f0101b15:	85 c0                	test   %eax,%eax
f0101b17:	0f 85 51 08 00 00    	jne    f010236e <mem_init+0xfca>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b20:	8b 98 b0 1f 00 00    	mov    0x1fb0(%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101b26:	8b b0 ac 1f 00 00    	mov    0x1fac(%eax),%esi
f0101b2c:	8b 13                	mov    (%ebx),%edx
f0101b2e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b34:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b37:	29 f0                	sub    %esi,%eax
f0101b39:	c1 f8 03             	sar    $0x3,%eax
f0101b3c:	c1 e0 0c             	shl    $0xc,%eax
f0101b3f:	39 c2                	cmp    %eax,%edx
f0101b41:	0f 85 49 08 00 00    	jne    f0102390 <mem_init+0xfec>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b47:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b4c:	89 d8                	mov    %ebx,%eax
f0101b4e:	e8 b8 ef ff ff       	call   f0100b0b <check_va2pa>
f0101b53:	89 c2                	mov    %eax,%edx
f0101b55:	89 f8                	mov    %edi,%eax
f0101b57:	29 f0                	sub    %esi,%eax
f0101b59:	c1 f8 03             	sar    $0x3,%eax
f0101b5c:	c1 e0 0c             	shl    $0xc,%eax
f0101b5f:	39 c2                	cmp    %eax,%edx
f0101b61:	0f 85 4b 08 00 00    	jne    f01023b2 <mem_init+0x100e>
	assert(pp1->pp_ref == 1);
f0101b67:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b6c:	0f 85 62 08 00 00    	jne    f01023d4 <mem_init+0x1030>
	assert(pp0->pp_ref == 1);
f0101b72:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b75:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b7a:	0f 85 76 08 00 00    	jne    f01023f6 <mem_init+0x1052>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b80:	6a 02                	push   $0x2
f0101b82:	68 00 10 00 00       	push   $0x1000
f0101b87:	ff 75 d0             	push   -0x30(%ebp)
f0101b8a:	53                   	push   %ebx
f0101b8b:	e8 a2 f7 ff ff       	call   f0101332 <page_insert>
f0101b90:	83 c4 10             	add    $0x10,%esp
f0101b93:	85 c0                	test   %eax,%eax
f0101b95:	0f 85 7d 08 00 00    	jne    f0102418 <mem_init+0x1074>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b9b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ba3:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101ba9:	e8 5d ef ff ff       	call   f0100b0b <check_va2pa>
f0101bae:	89 c2                	mov    %eax,%edx
f0101bb0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bb3:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101bb9:	c1 f8 03             	sar    $0x3,%eax
f0101bbc:	c1 e0 0c             	shl    $0xc,%eax
f0101bbf:	39 c2                	cmp    %eax,%edx
f0101bc1:	0f 85 73 08 00 00    	jne    f010243a <mem_init+0x1096>
	assert(pp2->pp_ref == 1);
f0101bc7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bca:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bcf:	0f 85 87 08 00 00    	jne    f010245c <mem_init+0x10b8>

	// should be no free memory
	assert(!page_alloc(0));
f0101bd5:	83 ec 0c             	sub    $0xc,%esp
f0101bd8:	6a 00                	push   $0x0
f0101bda:	e8 57 f4 ff ff       	call   f0101036 <page_alloc>
f0101bdf:	83 c4 10             	add    $0x10,%esp
f0101be2:	85 c0                	test   %eax,%eax
f0101be4:	0f 85 94 08 00 00    	jne    f010247e <mem_init+0x10da>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bea:	6a 02                	push   $0x2
f0101bec:	68 00 10 00 00       	push   $0x1000
f0101bf1:	ff 75 d0             	push   -0x30(%ebp)
f0101bf4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bf7:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101bfd:	e8 30 f7 ff ff       	call   f0101332 <page_insert>
f0101c02:	83 c4 10             	add    $0x10,%esp
f0101c05:	85 c0                	test   %eax,%eax
f0101c07:	0f 85 93 08 00 00    	jne    f01024a0 <mem_init+0x10fc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c0d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c12:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c15:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101c1b:	e8 eb ee ff ff       	call   f0100b0b <check_va2pa>
f0101c20:	89 c2                	mov    %eax,%edx
f0101c22:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c25:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101c2b:	c1 f8 03             	sar    $0x3,%eax
f0101c2e:	c1 e0 0c             	shl    $0xc,%eax
f0101c31:	39 c2                	cmp    %eax,%edx
f0101c33:	0f 85 89 08 00 00    	jne    f01024c2 <mem_init+0x111e>
	assert(pp2->pp_ref == 1);
f0101c39:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c3c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c41:	0f 85 9d 08 00 00    	jne    f01024e4 <mem_init+0x1140>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c47:	83 ec 0c             	sub    $0xc,%esp
f0101c4a:	6a 00                	push   $0x0
f0101c4c:	e8 e5 f3 ff ff       	call   f0101036 <page_alloc>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	85 c0                	test   %eax,%eax
f0101c56:	0f 85 aa 08 00 00    	jne    f0102506 <mem_init+0x1162>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c5c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c5f:	8b 91 b0 1f 00 00    	mov    0x1fb0(%ecx),%edx
f0101c65:	8b 02                	mov    (%edx),%eax
f0101c67:	89 c3                	mov    %eax,%ebx
f0101c69:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (PGNUM(pa) >= npages)
f0101c6f:	c1 e8 0c             	shr    $0xc,%eax
f0101c72:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0101c78:	0f 83 aa 08 00 00    	jae    f0102528 <mem_init+0x1184>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c7e:	83 ec 04             	sub    $0x4,%esp
f0101c81:	6a 00                	push   $0x0
f0101c83:	68 00 10 00 00       	push   $0x1000
f0101c88:	52                   	push   %edx
f0101c89:	e8 c8 f4 ff ff       	call   f0101156 <pgdir_walk>
f0101c8e:	81 eb fc ff ff 0f    	sub    $0xffffffc,%ebx
f0101c94:	83 c4 10             	add    $0x10,%esp
f0101c97:	39 d8                	cmp    %ebx,%eax
f0101c99:	0f 85 a4 08 00 00    	jne    f0102543 <mem_init+0x119f>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9f:	6a 06                	push   $0x6
f0101ca1:	68 00 10 00 00       	push   $0x1000
f0101ca6:	ff 75 d0             	push   -0x30(%ebp)
f0101ca9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cac:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101cb2:	e8 7b f6 ff ff       	call   f0101332 <page_insert>
f0101cb7:	83 c4 10             	add    $0x10,%esp
f0101cba:	85 c0                	test   %eax,%eax
f0101cbc:	0f 85 a3 08 00 00    	jne    f0102565 <mem_init+0x11c1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cc2:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101cc5:	8b 9e b0 1f 00 00    	mov    0x1fb0(%esi),%ebx
f0101ccb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd0:	89 d8                	mov    %ebx,%eax
f0101cd2:	e8 34 ee ff ff       	call   f0100b0b <check_va2pa>
f0101cd7:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101cd9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cdc:	2b 86 ac 1f 00 00    	sub    0x1fac(%esi),%eax
f0101ce2:	c1 f8 03             	sar    $0x3,%eax
f0101ce5:	c1 e0 0c             	shl    $0xc,%eax
f0101ce8:	39 c2                	cmp    %eax,%edx
f0101cea:	0f 85 97 08 00 00    	jne    f0102587 <mem_init+0x11e3>
	assert(pp2->pp_ref == 1);
f0101cf0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cf3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101cf8:	0f 85 ab 08 00 00    	jne    f01025a9 <mem_init+0x1205>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cfe:	83 ec 04             	sub    $0x4,%esp
f0101d01:	6a 00                	push   $0x0
f0101d03:	68 00 10 00 00       	push   $0x1000
f0101d08:	53                   	push   %ebx
f0101d09:	e8 48 f4 ff ff       	call   f0101156 <pgdir_walk>
f0101d0e:	83 c4 10             	add    $0x10,%esp
f0101d11:	f6 00 04             	testb  $0x4,(%eax)
f0101d14:	0f 84 b1 08 00 00    	je     f01025cb <mem_init+0x1227>
	assert(kern_pgdir[0] & PTE_U);
f0101d1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d1d:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0101d23:	f6 00 04             	testb  $0x4,(%eax)
f0101d26:	0f 84 c1 08 00 00    	je     f01025ed <mem_init+0x1249>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d2c:	6a 02                	push   $0x2
f0101d2e:	68 00 10 00 00       	push   $0x1000
f0101d33:	ff 75 d0             	push   -0x30(%ebp)
f0101d36:	50                   	push   %eax
f0101d37:	e8 f6 f5 ff ff       	call   f0101332 <page_insert>
f0101d3c:	83 c4 10             	add    $0x10,%esp
f0101d3f:	85 c0                	test   %eax,%eax
f0101d41:	0f 85 c8 08 00 00    	jne    f010260f <mem_init+0x126b>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d47:	83 ec 04             	sub    $0x4,%esp
f0101d4a:	6a 00                	push   $0x0
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d54:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101d5a:	e8 f7 f3 ff ff       	call   f0101156 <pgdir_walk>
f0101d5f:	83 c4 10             	add    $0x10,%esp
f0101d62:	f6 00 02             	testb  $0x2,(%eax)
f0101d65:	0f 84 c6 08 00 00    	je     f0102631 <mem_init+0x128d>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d6b:	83 ec 04             	sub    $0x4,%esp
f0101d6e:	6a 00                	push   $0x0
f0101d70:	68 00 10 00 00       	push   $0x1000
f0101d75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d78:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101d7e:	e8 d3 f3 ff ff       	call   f0101156 <pgdir_walk>
f0101d83:	83 c4 10             	add    $0x10,%esp
f0101d86:	f6 00 04             	testb  $0x4,(%eax)
f0101d89:	0f 85 c4 08 00 00    	jne    f0102653 <mem_init+0x12af>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d8f:	6a 02                	push   $0x2
f0101d91:	68 00 00 40 00       	push   $0x400000
f0101d96:	ff 75 cc             	push   -0x34(%ebp)
f0101d99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d9c:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101da2:	e8 8b f5 ff ff       	call   f0101332 <page_insert>
f0101da7:	83 c4 10             	add    $0x10,%esp
f0101daa:	85 c0                	test   %eax,%eax
f0101dac:	0f 89 c3 08 00 00    	jns    f0102675 <mem_init+0x12d1>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101db2:	6a 02                	push   $0x2
f0101db4:	68 00 10 00 00       	push   $0x1000
f0101db9:	57                   	push   %edi
f0101dba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dbd:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101dc3:	e8 6a f5 ff ff       	call   f0101332 <page_insert>
f0101dc8:	83 c4 10             	add    $0x10,%esp
f0101dcb:	85 c0                	test   %eax,%eax
f0101dcd:	0f 85 c4 08 00 00    	jne    f0102697 <mem_init+0x12f3>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dd3:	83 ec 04             	sub    $0x4,%esp
f0101dd6:	6a 00                	push   $0x0
f0101dd8:	68 00 10 00 00       	push   $0x1000
f0101ddd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de0:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101de6:	e8 6b f3 ff ff       	call   f0101156 <pgdir_walk>
f0101deb:	83 c4 10             	add    $0x10,%esp
f0101dee:	f6 00 04             	testb  $0x4,(%eax)
f0101df1:	0f 85 c2 08 00 00    	jne    f01026b9 <mem_init+0x1315>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101df7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101dfa:	8b b3 b0 1f 00 00    	mov    0x1fb0(%ebx),%esi
f0101e00:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e05:	89 f0                	mov    %esi,%eax
f0101e07:	e8 ff ec ff ff       	call   f0100b0b <check_va2pa>
f0101e0c:	89 d9                	mov    %ebx,%ecx
f0101e0e:	89 fb                	mov    %edi,%ebx
f0101e10:	2b 99 ac 1f 00 00    	sub    0x1fac(%ecx),%ebx
f0101e16:	c1 fb 03             	sar    $0x3,%ebx
f0101e19:	c1 e3 0c             	shl    $0xc,%ebx
f0101e1c:	39 d8                	cmp    %ebx,%eax
f0101e1e:	0f 85 b7 08 00 00    	jne    f01026db <mem_init+0x1337>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e24:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e29:	89 f0                	mov    %esi,%eax
f0101e2b:	e8 db ec ff ff       	call   f0100b0b <check_va2pa>
f0101e30:	39 c3                	cmp    %eax,%ebx
f0101e32:	0f 85 c5 08 00 00    	jne    f01026fd <mem_init+0x1359>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e38:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e3d:	0f 85 dc 08 00 00    	jne    f010271f <mem_init+0x137b>
	assert(pp2->pp_ref == 0);
f0101e43:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e46:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e4b:	0f 85 f0 08 00 00    	jne    f0102741 <mem_init+0x139d>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e51:	83 ec 0c             	sub    $0xc,%esp
f0101e54:	6a 00                	push   $0x0
f0101e56:	e8 db f1 ff ff       	call   f0101036 <page_alloc>
f0101e5b:	83 c4 10             	add    $0x10,%esp
f0101e5e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e61:	0f 85 fc 08 00 00    	jne    f0102763 <mem_init+0x13bf>
f0101e67:	85 c0                	test   %eax,%eax
f0101e69:	0f 84 f4 08 00 00    	je     f0102763 <mem_init+0x13bf>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e6f:	83 ec 08             	sub    $0x8,%esp
f0101e72:	6a 00                	push   $0x0
f0101e74:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e77:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101e7d:	e8 6e f4 ff ff       	call   f01012f0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e82:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0101e88:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8d:	89 d8                	mov    %ebx,%eax
f0101e8f:	e8 77 ec ff ff       	call   f0100b0b <check_va2pa>
f0101e94:	83 c4 10             	add    $0x10,%esp
f0101e97:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9a:	0f 85 e5 08 00 00    	jne    f0102785 <mem_init+0x13e1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ea0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ea5:	89 d8                	mov    %ebx,%eax
f0101ea7:	e8 5f ec ff ff       	call   f0100b0b <check_va2pa>
f0101eac:	89 c2                	mov    %eax,%edx
f0101eae:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101eb1:	89 f8                	mov    %edi,%eax
f0101eb3:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0101eb9:	c1 f8 03             	sar    $0x3,%eax
f0101ebc:	c1 e0 0c             	shl    $0xc,%eax
f0101ebf:	39 c2                	cmp    %eax,%edx
f0101ec1:	0f 85 e0 08 00 00    	jne    f01027a7 <mem_init+0x1403>
	assert(pp1->pp_ref == 1);
f0101ec7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ecc:	0f 85 f6 08 00 00    	jne    f01027c8 <mem_init+0x1424>
	assert(pp2->pp_ref == 0);
f0101ed2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ed5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101eda:	0f 85 0a 09 00 00    	jne    f01027ea <mem_init+0x1446>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ee0:	6a 00                	push   $0x0
f0101ee2:	68 00 10 00 00       	push   $0x1000
f0101ee7:	57                   	push   %edi
f0101ee8:	53                   	push   %ebx
f0101ee9:	e8 44 f4 ff ff       	call   f0101332 <page_insert>
f0101eee:	83 c4 10             	add    $0x10,%esp
f0101ef1:	85 c0                	test   %eax,%eax
f0101ef3:	0f 85 13 09 00 00    	jne    f010280c <mem_init+0x1468>
	assert(pp1->pp_ref);
f0101ef9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101efe:	0f 84 2a 09 00 00    	je     f010282e <mem_init+0x148a>
	assert(pp1->pp_link == NULL);
f0101f04:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f07:	0f 85 43 09 00 00    	jne    f0102850 <mem_init+0x14ac>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f0d:	83 ec 08             	sub    $0x8,%esp
f0101f10:	68 00 10 00 00       	push   $0x1000
f0101f15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f18:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101f1e:	e8 cd f3 ff ff       	call   f01012f0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f23:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0101f29:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f2e:	89 d8                	mov    %ebx,%eax
f0101f30:	e8 d6 eb ff ff       	call   f0100b0b <check_va2pa>
f0101f35:	83 c4 10             	add    $0x10,%esp
f0101f38:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f3b:	0f 85 31 09 00 00    	jne    f0102872 <mem_init+0x14ce>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f41:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f46:	89 d8                	mov    %ebx,%eax
f0101f48:	e8 be eb ff ff       	call   f0100b0b <check_va2pa>
f0101f4d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f50:	0f 85 3e 09 00 00    	jne    f0102894 <mem_init+0x14f0>
	assert(pp1->pp_ref == 0);
f0101f56:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f5b:	0f 85 55 09 00 00    	jne    f01028b6 <mem_init+0x1512>
	assert(pp2->pp_ref == 0);
f0101f61:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f64:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f69:	0f 85 69 09 00 00    	jne    f01028d8 <mem_init+0x1534>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f6f:	83 ec 0c             	sub    $0xc,%esp
f0101f72:	6a 00                	push   $0x0
f0101f74:	e8 bd f0 ff ff       	call   f0101036 <page_alloc>
f0101f79:	83 c4 10             	add    $0x10,%esp
f0101f7c:	85 c0                	test   %eax,%eax
f0101f7e:	0f 84 76 09 00 00    	je     f01028fa <mem_init+0x1556>
f0101f84:	39 c7                	cmp    %eax,%edi
f0101f86:	0f 85 6e 09 00 00    	jne    f01028fa <mem_init+0x1556>

	// should be no free memory
	assert(!page_alloc(0));
f0101f8c:	83 ec 0c             	sub    $0xc,%esp
f0101f8f:	6a 00                	push   $0x0
f0101f91:	e8 a0 f0 ff ff       	call   f0101036 <page_alloc>
f0101f96:	83 c4 10             	add    $0x10,%esp
f0101f99:	85 c0                	test   %eax,%eax
f0101f9b:	0f 85 7b 09 00 00    	jne    f010291c <mem_init+0x1578>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fa1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa4:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0101faa:	8b 11                	mov    (%ecx),%edx
f0101fac:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fb2:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101fb5:	2b 98 ac 1f 00 00    	sub    0x1fac(%eax),%ebx
f0101fbb:	89 d8                	mov    %ebx,%eax
f0101fbd:	c1 f8 03             	sar    $0x3,%eax
f0101fc0:	c1 e0 0c             	shl    $0xc,%eax
f0101fc3:	39 c2                	cmp    %eax,%edx
f0101fc5:	0f 85 73 09 00 00    	jne    f010293e <mem_init+0x159a>
	kern_pgdir[0] = 0;
f0101fcb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fd1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fd4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fd9:	0f 85 81 09 00 00    	jne    f0102960 <mem_init+0x15bc>
	pp0->pp_ref = 0;
f0101fdf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fe2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fe8:	83 ec 0c             	sub    $0xc,%esp
f0101feb:	50                   	push   %eax
f0101fec:	e8 ca f0 ff ff       	call   f01010bb <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ff1:	83 c4 0c             	add    $0xc,%esp
f0101ff4:	6a 01                	push   $0x1
f0101ff6:	68 00 10 40 00       	push   $0x401000
f0101ffb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ffe:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0102004:	e8 4d f1 ff ff       	call   f0101156 <pgdir_walk>
f0102009:	89 c6                	mov    %eax,%esi
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010200b:	89 d9                	mov    %ebx,%ecx
f010200d:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0102013:	8b 43 04             	mov    0x4(%ebx),%eax
f0102016:	89 c2                	mov    %eax,%edx
f0102018:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f010201e:	8b 89 b4 1f 00 00    	mov    0x1fb4(%ecx),%ecx
f0102024:	c1 e8 0c             	shr    $0xc,%eax
f0102027:	83 c4 10             	add    $0x10,%esp
f010202a:	39 c8                	cmp    %ecx,%eax
f010202c:	0f 83 50 09 00 00    	jae    f0102982 <mem_init+0x15de>
	assert(ptep == ptep1 + PTX(va));
f0102032:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102038:	39 d6                	cmp    %edx,%esi
f010203a:	0f 85 5e 09 00 00    	jne    f010299e <mem_init+0x15fa>
	kern_pgdir[PDX(va)] = 0;
f0102040:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102047:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010204a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0102050:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102053:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0102059:	c1 f8 03             	sar    $0x3,%eax
f010205c:	89 c2                	mov    %eax,%edx
f010205e:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102061:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102066:	39 c1                	cmp    %eax,%ecx
f0102068:	0f 86 52 09 00 00    	jbe    f01029c0 <mem_init+0x161c>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010206e:	83 ec 04             	sub    $0x4,%esp
f0102071:	68 00 10 00 00       	push   $0x1000
f0102076:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010207b:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102081:	52                   	push   %edx
f0102082:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102085:	e8 95 1c 00 00       	call   f0103d1f <memset>
	page_free(pp0);
f010208a:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010208d:	89 34 24             	mov    %esi,(%esp)
f0102090:	e8 26 f0 ff ff       	call   f01010bb <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102095:	83 c4 0c             	add    $0xc,%esp
f0102098:	6a 01                	push   $0x1
f010209a:	6a 00                	push   $0x0
f010209c:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f01020a2:	e8 af f0 ff ff       	call   f0101156 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020a7:	89 f0                	mov    %esi,%eax
f01020a9:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f01020af:	c1 f8 03             	sar    $0x3,%eax
f01020b2:	89 c2                	mov    %eax,%edx
f01020b4:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020b7:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01020bc:	83 c4 10             	add    $0x10,%esp
f01020bf:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f01020c5:	0f 83 0b 09 00 00    	jae    f01029d6 <mem_init+0x1632>
	return (void *)(pa + KERNBASE);
f01020cb:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01020d1:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020d7:	8b 30                	mov    (%eax),%esi
f01020d9:	83 e6 01             	and    $0x1,%esi
f01020dc:	0f 85 0d 09 00 00    	jne    f01029ef <mem_init+0x164b>
	for(i=0; i<NPTENTRIES; i++)
f01020e2:	83 c0 04             	add    $0x4,%eax
f01020e5:	39 d0                	cmp    %edx,%eax
f01020e7:	75 ee                	jne    f01020d7 <mem_init+0xd33>
	kern_pgdir[0] = 0;
f01020e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020ec:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f01020f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020f8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020fb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102101:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102104:	89 93 bc 1f 00 00    	mov    %edx,0x1fbc(%ebx)

	// free the pages we took
	page_free(pp0);
f010210a:	83 ec 0c             	sub    $0xc,%esp
f010210d:	50                   	push   %eax
f010210e:	e8 a8 ef ff ff       	call   f01010bb <page_free>
	page_free(pp1);
f0102113:	89 3c 24             	mov    %edi,(%esp)
f0102116:	e8 a0 ef ff ff       	call   f01010bb <page_free>
	page_free(pp2);
f010211b:	83 c4 04             	add    $0x4,%esp
f010211e:	ff 75 d0             	push   -0x30(%ebp)
f0102121:	e8 95 ef ff ff       	call   f01010bb <page_free>

	cprintf("check_page() succeeded!\n");
f0102126:	8d 83 ea d5 fe ff    	lea    -0x12a16(%ebx),%eax
f010212c:	89 04 24             	mov    %eax,(%esp)
f010212f:	e8 ea 0f 00 00       	call   f010311e <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102134:	8b 83 ac 1f 00 00    	mov    0x1fac(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f010213a:	83 c4 10             	add    $0x10,%esp
f010213d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102142:	0f 86 c9 08 00 00    	jbe    f0102a11 <mem_init+0x166d>
f0102148:	83 ec 08             	sub    $0x8,%esp
f010214b:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f010214d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102152:	50                   	push   %eax
f0102153:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102158:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010215d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102160:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f0102166:	e8 8e f0 ff ff       	call   f01011f9 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010216b:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f0102171:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102174:	83 c4 10             	add    $0x10,%esp
f0102177:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010217c:	0f 86 ab 08 00 00    	jbe    f0102a2d <mem_init+0x1689>
	boot_map_region(kern_pgdir, backed_stack, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102182:	83 ec 08             	sub    $0x8,%esp
f0102185:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102187:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010218a:	05 00 00 00 10       	add    $0x10000000,%eax
f010218f:	50                   	push   %eax
f0102190:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102195:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010219a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010219d:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f01021a3:	e8 51 f0 ff ff       	call   f01011f9 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, pa_end, 0, PTE_W);
f01021a8:	83 c4 08             	add    $0x8,%esp
f01021ab:	6a 02                	push   $0x2
f01021ad:	6a 00                	push   $0x0
f01021af:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021b4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021b9:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f01021bf:	e8 35 f0 ff ff       	call   f01011f9 <boot_map_region>
	pgdir = kern_pgdir;
f01021c4:	89 f9                	mov    %edi,%ecx
f01021c6:	8b bf b0 1f 00 00    	mov    0x1fb0(%edi),%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021cc:	8b 81 b4 1f 00 00    	mov    0x1fb4(%ecx),%eax
f01021d2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01021d5:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021e1:	89 c2                	mov    %eax,%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e3:	8b 81 ac 1f 00 00    	mov    0x1fac(%ecx),%eax
f01021e9:	89 45 bc             	mov    %eax,-0x44(%ebp)
f01021ec:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f01021f2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01021f5:	83 c4 10             	add    $0x10,%esp
f01021f8:	89 f3                	mov    %esi,%ebx
f01021fa:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021fd:	89 c7                	mov    %eax,%edi
f01021ff:	89 75 c0             	mov    %esi,-0x40(%ebp)
f0102202:	89 d6                	mov    %edx,%esi
f0102204:	39 de                	cmp    %ebx,%esi
f0102206:	0f 86 82 08 00 00    	jbe    f0102a8e <mem_init+0x16ea>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010220c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102212:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102215:	e8 f1 e8 ff ff       	call   f0100b0b <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010221a:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102220:	0f 86 28 08 00 00    	jbe    f0102a4e <mem_init+0x16aa>
f0102226:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102229:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f010222c:	39 d0                	cmp    %edx,%eax
f010222e:	0f 85 38 08 00 00    	jne    f0102a6c <mem_init+0x16c8>
	for (i = 0; i < n; i += PGSIZE)
f0102234:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010223a:	eb c8                	jmp    f0102204 <mem_init+0xe60>
	assert(nfree == 0);
f010223c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010223f:	8d 83 13 d5 fe ff    	lea    -0x12aed(%ebx),%eax
f0102245:	50                   	push   %eax
f0102246:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010224c:	50                   	push   %eax
f010224d:	68 99 02 00 00       	push   $0x299
f0102252:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102258:	50                   	push   %eax
f0102259:	e8 3b de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010225e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102261:	8d 83 21 d4 fe ff    	lea    -0x12bdf(%ebx),%eax
f0102267:	50                   	push   %eax
f0102268:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010226e:	50                   	push   %eax
f010226f:	68 f2 02 00 00       	push   $0x2f2
f0102274:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010227a:	50                   	push   %eax
f010227b:	e8 19 de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102280:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102283:	8d 83 37 d4 fe ff    	lea    -0x12bc9(%ebx),%eax
f0102289:	50                   	push   %eax
f010228a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102290:	50                   	push   %eax
f0102291:	68 f3 02 00 00       	push   $0x2f3
f0102296:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010229c:	50                   	push   %eax
f010229d:	e8 f7 dd ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01022a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022a5:	8d 83 4d d4 fe ff    	lea    -0x12bb3(%ebx),%eax
f01022ab:	50                   	push   %eax
f01022ac:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01022b2:	50                   	push   %eax
f01022b3:	68 f4 02 00 00       	push   $0x2f4
f01022b8:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01022be:	50                   	push   %eax
f01022bf:	e8 d5 dd ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01022c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022c7:	8d 83 63 d4 fe ff    	lea    -0x12b9d(%ebx),%eax
f01022cd:	50                   	push   %eax
f01022ce:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01022d4:	50                   	push   %eax
f01022d5:	68 f7 02 00 00       	push   $0x2f7
f01022da:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01022e0:	50                   	push   %eax
f01022e1:	e8 b3 dd ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022e9:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f01022ef:	50                   	push   %eax
f01022f0:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01022f6:	50                   	push   %eax
f01022f7:	68 f8 02 00 00       	push   $0x2f8
f01022fc:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102302:	50                   	push   %eax
f0102303:	e8 91 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102308:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230b:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102311:	50                   	push   %eax
f0102312:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102318:	50                   	push   %eax
f0102319:	68 ff 02 00 00       	push   $0x2ff
f010231e:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102324:	50                   	push   %eax
f0102325:	e8 6f dd ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010232a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010232d:	8d 83 50 d8 fe ff    	lea    -0x127b0(%ebx),%eax
f0102333:	50                   	push   %eax
f0102334:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010233a:	50                   	push   %eax
f010233b:	68 02 03 00 00       	push   $0x302
f0102340:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102346:	50                   	push   %eax
f0102347:	e8 4d dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010234c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010234f:	8d 83 88 d8 fe ff    	lea    -0x12778(%ebx),%eax
f0102355:	50                   	push   %eax
f0102356:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010235c:	50                   	push   %eax
f010235d:	68 05 03 00 00       	push   $0x305
f0102362:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102368:	50                   	push   %eax
f0102369:	e8 2b dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010236e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102371:	8d 83 b8 d8 fe ff    	lea    -0x12748(%ebx),%eax
f0102377:	50                   	push   %eax
f0102378:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010237e:	50                   	push   %eax
f010237f:	68 09 03 00 00       	push   $0x309
f0102384:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010238a:	50                   	push   %eax
f010238b:	e8 09 dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102390:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102393:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0102399:	50                   	push   %eax
f010239a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01023a0:	50                   	push   %eax
f01023a1:	68 0a 03 00 00       	push   $0x30a
f01023a6:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01023ac:	50                   	push   %eax
f01023ad:	e8 e7 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01023b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b5:	8d 83 10 d9 fe ff    	lea    -0x126f0(%ebx),%eax
f01023bb:	50                   	push   %eax
f01023bc:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01023c2:	50                   	push   %eax
f01023c3:	68 0b 03 00 00       	push   $0x30b
f01023c8:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01023ce:	50                   	push   %eax
f01023cf:	e8 c5 dc ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01023d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d7:	8d 83 1e d5 fe ff    	lea    -0x12ae2(%ebx),%eax
f01023dd:	50                   	push   %eax
f01023de:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01023e4:	50                   	push   %eax
f01023e5:	68 0c 03 00 00       	push   $0x30c
f01023ea:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01023f0:	50                   	push   %eax
f01023f1:	e8 a3 dc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01023f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023f9:	8d 83 2f d5 fe ff    	lea    -0x12ad1(%ebx),%eax
f01023ff:	50                   	push   %eax
f0102400:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102406:	50                   	push   %eax
f0102407:	68 0d 03 00 00       	push   $0x30d
f010240c:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102412:	50                   	push   %eax
f0102413:	e8 81 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102418:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241b:	8d 83 40 d9 fe ff    	lea    -0x126c0(%ebx),%eax
f0102421:	50                   	push   %eax
f0102422:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102428:	50                   	push   %eax
f0102429:	68 10 03 00 00       	push   $0x310
f010242e:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102434:	50                   	push   %eax
f0102435:	e8 5f dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010243a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243d:	8d 83 7c d9 fe ff    	lea    -0x12684(%ebx),%eax
f0102443:	50                   	push   %eax
f0102444:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010244a:	50                   	push   %eax
f010244b:	68 11 03 00 00       	push   $0x311
f0102450:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	e8 3d dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010245c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010245f:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f0102465:	50                   	push   %eax
f0102466:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010246c:	50                   	push   %eax
f010246d:	68 12 03 00 00       	push   $0x312
f0102472:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102478:	50                   	push   %eax
f0102479:	e8 1b dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010247e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102481:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102487:	50                   	push   %eax
f0102488:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010248e:	50                   	push   %eax
f010248f:	68 15 03 00 00       	push   $0x315
f0102494:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010249a:	50                   	push   %eax
f010249b:	e8 f9 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024a0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a3:	8d 83 40 d9 fe ff    	lea    -0x126c0(%ebx),%eax
f01024a9:	50                   	push   %eax
f01024aa:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01024b0:	50                   	push   %eax
f01024b1:	68 18 03 00 00       	push   $0x318
f01024b6:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01024bc:	50                   	push   %eax
f01024bd:	e8 d7 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c5:	8d 83 7c d9 fe ff    	lea    -0x12684(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01024d2:	50                   	push   %eax
f01024d3:	68 19 03 00 00       	push   $0x319
f01024d8:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	e8 b5 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e7:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f01024ed:	50                   	push   %eax
f01024ee:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01024f4:	50                   	push   %eax
f01024f5:	68 1a 03 00 00       	push   $0x31a
f01024fa:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102500:	50                   	push   %eax
f0102501:	e8 93 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102506:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102509:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010250f:	50                   	push   %eax
f0102510:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102516:	50                   	push   %eax
f0102517:	68 1e 03 00 00       	push   $0x31e
f010251c:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102522:	50                   	push   %eax
f0102523:	e8 71 db ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102528:	53                   	push   %ebx
f0102529:	89 cb                	mov    %ecx,%ebx
f010252b:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f0102531:	50                   	push   %eax
f0102532:	68 21 03 00 00       	push   $0x321
f0102537:	8d 81 10 d3 fe ff    	lea    -0x12cf0(%ecx),%eax
f010253d:	50                   	push   %eax
f010253e:	e8 56 db ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102543:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102546:	8d 83 ac d9 fe ff    	lea    -0x12654(%ebx),%eax
f010254c:	50                   	push   %eax
f010254d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102553:	50                   	push   %eax
f0102554:	68 22 03 00 00       	push   $0x322
f0102559:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010255f:	50                   	push   %eax
f0102560:	e8 34 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102565:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102568:	8d 83 ec d9 fe ff    	lea    -0x12614(%ebx),%eax
f010256e:	50                   	push   %eax
f010256f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102575:	50                   	push   %eax
f0102576:	68 25 03 00 00       	push   $0x325
f010257b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102581:	50                   	push   %eax
f0102582:	e8 12 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102587:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010258a:	8d 83 7c d9 fe ff    	lea    -0x12684(%ebx),%eax
f0102590:	50                   	push   %eax
f0102591:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102597:	50                   	push   %eax
f0102598:	68 26 03 00 00       	push   $0x326
f010259d:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01025a3:	50                   	push   %eax
f01025a4:	e8 f0 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01025a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ac:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f01025b2:	50                   	push   %eax
f01025b3:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01025b9:	50                   	push   %eax
f01025ba:	68 27 03 00 00       	push   $0x327
f01025bf:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01025c5:	50                   	push   %eax
f01025c6:	e8 ce da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025cb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ce:	8d 83 2c da fe ff    	lea    -0x125d4(%ebx),%eax
f01025d4:	50                   	push   %eax
f01025d5:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01025db:	50                   	push   %eax
f01025dc:	68 28 03 00 00       	push   $0x328
f01025e1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01025e7:	50                   	push   %eax
f01025e8:	e8 ac da ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025ed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f0:	8d 83 51 d5 fe ff    	lea    -0x12aaf(%ebx),%eax
f01025f6:	50                   	push   %eax
f01025f7:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01025fd:	50                   	push   %eax
f01025fe:	68 29 03 00 00       	push   $0x329
f0102603:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102609:	50                   	push   %eax
f010260a:	e8 8a da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010260f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102612:	8d 83 40 d9 fe ff    	lea    -0x126c0(%ebx),%eax
f0102618:	50                   	push   %eax
f0102619:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010261f:	50                   	push   %eax
f0102620:	68 2c 03 00 00       	push   $0x32c
f0102625:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010262b:	50                   	push   %eax
f010262c:	e8 68 da ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102631:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102634:	8d 83 60 da fe ff    	lea    -0x125a0(%ebx),%eax
f010263a:	50                   	push   %eax
f010263b:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102641:	50                   	push   %eax
f0102642:	68 2d 03 00 00       	push   $0x32d
f0102647:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010264d:	50                   	push   %eax
f010264e:	e8 46 da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102653:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102656:	8d 83 94 da fe ff    	lea    -0x1256c(%ebx),%eax
f010265c:	50                   	push   %eax
f010265d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102663:	50                   	push   %eax
f0102664:	68 2e 03 00 00       	push   $0x32e
f0102669:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010266f:	50                   	push   %eax
f0102670:	e8 24 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102675:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102678:	8d 83 cc da fe ff    	lea    -0x12534(%ebx),%eax
f010267e:	50                   	push   %eax
f010267f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102685:	50                   	push   %eax
f0102686:	68 31 03 00 00       	push   $0x331
f010268b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102691:	50                   	push   %eax
f0102692:	e8 02 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102697:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269a:	8d 83 04 db fe ff    	lea    -0x124fc(%ebx),%eax
f01026a0:	50                   	push   %eax
f01026a1:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01026a7:	50                   	push   %eax
f01026a8:	68 34 03 00 00       	push   $0x334
f01026ad:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01026b3:	50                   	push   %eax
f01026b4:	e8 e0 d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026bc:	8d 83 94 da fe ff    	lea    -0x1256c(%ebx),%eax
f01026c2:	50                   	push   %eax
f01026c3:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01026c9:	50                   	push   %eax
f01026ca:	68 35 03 00 00       	push   $0x335
f01026cf:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01026d5:	50                   	push   %eax
f01026d6:	e8 be d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026de:	8d 83 40 db fe ff    	lea    -0x124c0(%ebx),%eax
f01026e4:	50                   	push   %eax
f01026e5:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01026eb:	50                   	push   %eax
f01026ec:	68 38 03 00 00       	push   $0x338
f01026f1:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	e8 9c d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102700:	8d 83 6c db fe ff    	lea    -0x12494(%ebx),%eax
f0102706:	50                   	push   %eax
f0102707:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010270d:	50                   	push   %eax
f010270e:	68 39 03 00 00       	push   $0x339
f0102713:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	e8 7a d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f010271f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102722:	8d 83 67 d5 fe ff    	lea    -0x12a99(%ebx),%eax
f0102728:	50                   	push   %eax
f0102729:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010272f:	50                   	push   %eax
f0102730:	68 3b 03 00 00       	push   $0x33b
f0102735:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010273b:	50                   	push   %eax
f010273c:	e8 58 d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102741:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102744:	8d 83 78 d5 fe ff    	lea    -0x12a88(%ebx),%eax
f010274a:	50                   	push   %eax
f010274b:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102751:	50                   	push   %eax
f0102752:	68 3c 03 00 00       	push   $0x33c
f0102757:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010275d:	50                   	push   %eax
f010275e:	e8 36 d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102763:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102766:	8d 83 9c db fe ff    	lea    -0x12464(%ebx),%eax
f010276c:	50                   	push   %eax
f010276d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102773:	50                   	push   %eax
f0102774:	68 3f 03 00 00       	push   $0x33f
f0102779:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010277f:	50                   	push   %eax
f0102780:	e8 14 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102785:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102788:	8d 83 c0 db fe ff    	lea    -0x12440(%ebx),%eax
f010278e:	50                   	push   %eax
f010278f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102795:	50                   	push   %eax
f0102796:	68 43 03 00 00       	push   $0x343
f010279b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	e8 f2 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027a7:	89 cb                	mov    %ecx,%ebx
f01027a9:	8d 81 6c db fe ff    	lea    -0x12494(%ecx),%eax
f01027af:	50                   	push   %eax
f01027b0:	8d 81 36 d3 fe ff    	lea    -0x12cca(%ecx),%eax
f01027b6:	50                   	push   %eax
f01027b7:	68 44 03 00 00       	push   $0x344
f01027bc:	8d 81 10 d3 fe ff    	lea    -0x12cf0(%ecx),%eax
f01027c2:	50                   	push   %eax
f01027c3:	e8 d1 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01027c8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027cb:	8d 83 1e d5 fe ff    	lea    -0x12ae2(%ebx),%eax
f01027d1:	50                   	push   %eax
f01027d2:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01027d8:	50                   	push   %eax
f01027d9:	68 45 03 00 00       	push   $0x345
f01027de:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01027e4:	50                   	push   %eax
f01027e5:	e8 af d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027ea:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ed:	8d 83 78 d5 fe ff    	lea    -0x12a88(%ebx),%eax
f01027f3:	50                   	push   %eax
f01027f4:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01027fa:	50                   	push   %eax
f01027fb:	68 46 03 00 00       	push   $0x346
f0102800:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102806:	50                   	push   %eax
f0102807:	e8 8d d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010280c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010280f:	8d 83 e4 db fe ff    	lea    -0x1241c(%ebx),%eax
f0102815:	50                   	push   %eax
f0102816:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010281c:	50                   	push   %eax
f010281d:	68 49 03 00 00       	push   $0x349
f0102822:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102828:	50                   	push   %eax
f0102829:	e8 6b d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f010282e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102831:	8d 83 89 d5 fe ff    	lea    -0x12a77(%ebx),%eax
f0102837:	50                   	push   %eax
f0102838:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010283e:	50                   	push   %eax
f010283f:	68 4a 03 00 00       	push   $0x34a
f0102844:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010284a:	50                   	push   %eax
f010284b:	e8 49 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102850:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102853:	8d 83 95 d5 fe ff    	lea    -0x12a6b(%ebx),%eax
f0102859:	50                   	push   %eax
f010285a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102860:	50                   	push   %eax
f0102861:	68 4b 03 00 00       	push   $0x34b
f0102866:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010286c:	50                   	push   %eax
f010286d:	e8 27 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102872:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102875:	8d 83 c0 db fe ff    	lea    -0x12440(%ebx),%eax
f010287b:	50                   	push   %eax
f010287c:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102882:	50                   	push   %eax
f0102883:	68 4f 03 00 00       	push   $0x34f
f0102888:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010288e:	50                   	push   %eax
f010288f:	e8 05 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102894:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102897:	8d 83 1c dc fe ff    	lea    -0x123e4(%ebx),%eax
f010289d:	50                   	push   %eax
f010289e:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01028a4:	50                   	push   %eax
f01028a5:	68 50 03 00 00       	push   $0x350
f01028aa:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01028b0:	50                   	push   %eax
f01028b1:	e8 e3 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01028b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b9:	8d 83 aa d5 fe ff    	lea    -0x12a56(%ebx),%eax
f01028bf:	50                   	push   %eax
f01028c0:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01028c6:	50                   	push   %eax
f01028c7:	68 51 03 00 00       	push   $0x351
f01028cc:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01028d2:	50                   	push   %eax
f01028d3:	e8 c1 d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01028d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028db:	8d 83 78 d5 fe ff    	lea    -0x12a88(%ebx),%eax
f01028e1:	50                   	push   %eax
f01028e2:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01028e8:	50                   	push   %eax
f01028e9:	68 52 03 00 00       	push   $0x352
f01028ee:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01028f4:	50                   	push   %eax
f01028f5:	e8 9f d7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028fa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028fd:	8d 83 44 dc fe ff    	lea    -0x123bc(%ebx),%eax
f0102903:	50                   	push   %eax
f0102904:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010290a:	50                   	push   %eax
f010290b:	68 55 03 00 00       	push   $0x355
f0102910:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102916:	50                   	push   %eax
f0102917:	e8 7d d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010291c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010291f:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102925:	50                   	push   %eax
f0102926:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010292c:	50                   	push   %eax
f010292d:	68 58 03 00 00       	push   $0x358
f0102932:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102938:	50                   	push   %eax
f0102939:	e8 5b d7 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010293e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102941:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0102947:	50                   	push   %eax
f0102948:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010294e:	50                   	push   %eax
f010294f:	68 5b 03 00 00       	push   $0x35b
f0102954:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010295a:	50                   	push   %eax
f010295b:	e8 39 d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102960:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102963:	8d 83 2f d5 fe ff    	lea    -0x12ad1(%ebx),%eax
f0102969:	50                   	push   %eax
f010296a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102970:	50                   	push   %eax
f0102971:	68 5d 03 00 00       	push   $0x35d
f0102976:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010297c:	50                   	push   %eax
f010297d:	e8 17 d7 ff ff       	call   f0100099 <_panic>
f0102982:	52                   	push   %edx
f0102983:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102986:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f010298c:	50                   	push   %eax
f010298d:	68 64 03 00 00       	push   $0x364
f0102992:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102998:	50                   	push   %eax
f0102999:	e8 fb d6 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010299e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a1:	8d 83 bb d5 fe ff    	lea    -0x12a45(%ebx),%eax
f01029a7:	50                   	push   %eax
f01029a8:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01029ae:	50                   	push   %eax
f01029af:	68 65 03 00 00       	push   $0x365
f01029b4:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f01029ba:	50                   	push   %eax
f01029bb:	e8 d9 d6 ff ff       	call   f0100099 <_panic>
f01029c0:	52                   	push   %edx
f01029c1:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f01029c7:	50                   	push   %eax
f01029c8:	6a 52                	push   $0x52
f01029ca:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f01029d0:	50                   	push   %eax
f01029d1:	e8 c3 d6 ff ff       	call   f0100099 <_panic>
f01029d6:	52                   	push   %edx
f01029d7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029da:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f01029e0:	50                   	push   %eax
f01029e1:	6a 52                	push   $0x52
f01029e3:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f01029e9:	50                   	push   %eax
f01029ea:	e8 aa d6 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01029ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f2:	8d 83 d3 d5 fe ff    	lea    -0x12a2d(%ebx),%eax
f01029f8:	50                   	push   %eax
f01029f9:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f01029ff:	50                   	push   %eax
f0102a00:	68 6f 03 00 00       	push   $0x36f
f0102a05:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102a0b:	50                   	push   %eax
f0102a0c:	e8 88 d6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a11:	50                   	push   %eax
f0102a12:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a15:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f0102a1b:	50                   	push   %eax
f0102a1c:	68 b8 00 00 00       	push   $0xb8
f0102a21:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102a27:	50                   	push   %eax
f0102a28:	e8 6c d6 ff ff       	call   f0100099 <_panic>
f0102a2d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a30:	ff b3 fc ff ff ff    	push   -0x4(%ebx)
f0102a36:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f0102a3c:	50                   	push   %eax
f0102a3d:	68 c6 00 00 00       	push   $0xc6
f0102a42:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102a48:	50                   	push   %eax
f0102a49:	e8 4b d6 ff ff       	call   f0100099 <_panic>
f0102a4e:	ff 75 bc             	push   -0x44(%ebp)
f0102a51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a54:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f0102a5a:	50                   	push   %eax
f0102a5b:	68 b1 02 00 00       	push   $0x2b1
f0102a60:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102a66:	50                   	push   %eax
f0102a67:	e8 2d d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a6c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a6f:	8d 83 68 dc fe ff    	lea    -0x12398(%ebx),%eax
f0102a75:	50                   	push   %eax
f0102a76:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102a7c:	50                   	push   %eax
f0102a7d:	68 b1 02 00 00       	push   $0x2b1
f0102a82:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	e8 0b d6 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a8e:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102a91:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0102a94:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102a97:	c1 e0 0c             	shl    $0xc,%eax
f0102a9a:	89 f3                	mov    %esi,%ebx
f0102a9c:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102a9f:	89 c6                	mov    %eax,%esi
f0102aa1:	39 f3                	cmp    %esi,%ebx
f0102aa3:	73 3b                	jae    f0102ae0 <mem_init+0x173c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102aa5:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102aab:	89 f8                	mov    %edi,%eax
f0102aad:	e8 59 e0 ff ff       	call   f0100b0b <check_va2pa>
f0102ab2:	39 c3                	cmp    %eax,%ebx
f0102ab4:	75 08                	jne    f0102abe <mem_init+0x171a>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ab6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102abc:	eb e3                	jmp    f0102aa1 <mem_init+0x16fd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102abe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ac1:	8d 83 9c dc fe ff    	lea    -0x12364(%ebx),%eax
f0102ac7:	50                   	push   %eax
f0102ac8:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102ace:	50                   	push   %eax
f0102acf:	68 b6 02 00 00       	push   $0x2b6
f0102ad4:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102ada:	50                   	push   %eax
f0102adb:	e8 b9 d5 ff ff       	call   f0100099 <_panic>
f0102ae0:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ae5:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102ae8:	05 00 80 00 20       	add    $0x20008000,%eax
f0102aed:	89 c6                	mov    %eax,%esi
f0102aef:	89 da                	mov    %ebx,%edx
f0102af1:	89 f8                	mov    %edi,%eax
f0102af3:	e8 13 e0 ff ff       	call   f0100b0b <check_va2pa>
f0102af8:	89 c2                	mov    %eax,%edx
f0102afa:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0102afd:	39 c2                	cmp    %eax,%edx
f0102aff:	75 44                	jne    f0102b45 <mem_init+0x17a1>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102b01:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b07:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102b0d:	75 e0                	jne    f0102aef <mem_init+0x174b>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102b0f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b12:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102b17:	89 f8                	mov    %edi,%eax
f0102b19:	e8 ed df ff ff       	call   f0100b0b <check_va2pa>
f0102b1e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102b21:	74 71                	je     f0102b94 <mem_init+0x17f0>
f0102b23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b26:	8d 83 0c dd fe ff    	lea    -0x122f4(%ebx),%eax
f0102b2c:	50                   	push   %eax
f0102b2d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102b33:	50                   	push   %eax
f0102b34:	68 bb 02 00 00       	push   $0x2bb
f0102b39:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102b3f:	50                   	push   %eax
f0102b40:	e8 54 d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102b45:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b48:	8d 83 c4 dc fe ff    	lea    -0x1233c(%ebx),%eax
f0102b4e:	50                   	push   %eax
f0102b4f:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102b55:	50                   	push   %eax
f0102b56:	68 ba 02 00 00       	push   $0x2ba
f0102b5b:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102b61:	50                   	push   %eax
f0102b62:	e8 32 d5 ff ff       	call   f0100099 <_panic>
		switch (i) {
f0102b67:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102b6d:	75 25                	jne    f0102b94 <mem_init+0x17f0>
			assert(pgdir[i] & PTE_P);
f0102b6f:	f6 04 b7 01          	testb  $0x1,(%edi,%esi,4)
f0102b73:	74 4f                	je     f0102bc4 <mem_init+0x1820>
	for (i = 0; i < NPDENTRIES; i++) {
f0102b75:	83 c6 01             	add    $0x1,%esi
f0102b78:	81 fe ff 03 00 00    	cmp    $0x3ff,%esi
f0102b7e:	0f 87 b1 00 00 00    	ja     f0102c35 <mem_init+0x1891>
		switch (i) {
f0102b84:	81 fe bd 03 00 00    	cmp    $0x3bd,%esi
f0102b8a:	77 db                	ja     f0102b67 <mem_init+0x17c3>
f0102b8c:	81 fe bb 03 00 00    	cmp    $0x3bb,%esi
f0102b92:	77 db                	ja     f0102b6f <mem_init+0x17cb>
			if (i >= PDX(KERNBASE)) {
f0102b94:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102b9a:	77 4a                	ja     f0102be6 <mem_init+0x1842>
				assert(pgdir[i] == 0);
f0102b9c:	83 3c b7 00          	cmpl   $0x0,(%edi,%esi,4)
f0102ba0:	74 d3                	je     f0102b75 <mem_init+0x17d1>
f0102ba2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ba5:	8d 83 25 d6 fe ff    	lea    -0x129db(%ebx),%eax
f0102bab:	50                   	push   %eax
f0102bac:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102bb2:	50                   	push   %eax
f0102bb3:	68 ca 02 00 00       	push   $0x2ca
f0102bb8:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102bbe:	50                   	push   %eax
f0102bbf:	e8 d5 d4 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102bc4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc7:	8d 83 03 d6 fe ff    	lea    -0x129fd(%ebx),%eax
f0102bcd:	50                   	push   %eax
f0102bce:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102bd4:	50                   	push   %eax
f0102bd5:	68 c3 02 00 00       	push   $0x2c3
f0102bda:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102be0:	50                   	push   %eax
f0102be1:	e8 b3 d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102be6:	8b 04 b7             	mov    (%edi,%esi,4),%eax
f0102be9:	a8 01                	test   $0x1,%al
f0102beb:	74 26                	je     f0102c13 <mem_init+0x186f>
				assert(pgdir[i] & PTE_W);
f0102bed:	a8 02                	test   $0x2,%al
f0102bef:	75 84                	jne    f0102b75 <mem_init+0x17d1>
f0102bf1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bf4:	8d 83 14 d6 fe ff    	lea    -0x129ec(%ebx),%eax
f0102bfa:	50                   	push   %eax
f0102bfb:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102c01:	50                   	push   %eax
f0102c02:	68 c8 02 00 00       	push   $0x2c8
f0102c07:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102c0d:	50                   	push   %eax
f0102c0e:	e8 86 d4 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102c13:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c16:	8d 83 03 d6 fe ff    	lea    -0x129fd(%ebx),%eax
f0102c1c:	50                   	push   %eax
f0102c1d:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102c23:	50                   	push   %eax
f0102c24:	68 c7 02 00 00       	push   $0x2c7
f0102c29:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102c2f:	50                   	push   %eax
f0102c30:	e8 64 d4 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102c35:	83 ec 0c             	sub    $0xc,%esp
f0102c38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c3b:	8d 83 3c dd fe ff    	lea    -0x122c4(%ebx),%eax
f0102c41:	50                   	push   %eax
f0102c42:	e8 d7 04 00 00       	call   f010311e <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102c47:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0102c4d:	83 c4 10             	add    $0x10,%esp
f0102c50:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c55:	0f 86 2c 02 00 00    	jbe    f0102e87 <mem_init+0x1ae3>
	return (physaddr_t)kva - KERNBASE;
f0102c5b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c60:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102c63:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c68:	e8 1a df ff ff       	call   f0100b87 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102c6d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102c70:	83 e0 f3             	and    $0xfffffff3,%eax
f0102c73:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102c78:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102c7b:	83 ec 0c             	sub    $0xc,%esp
f0102c7e:	6a 00                	push   $0x0
f0102c80:	e8 b1 e3 ff ff       	call   f0101036 <page_alloc>
f0102c85:	89 c6                	mov    %eax,%esi
f0102c87:	83 c4 10             	add    $0x10,%esp
f0102c8a:	85 c0                	test   %eax,%eax
f0102c8c:	0f 84 11 02 00 00    	je     f0102ea3 <mem_init+0x1aff>
	assert((pp1 = page_alloc(0)));
f0102c92:	83 ec 0c             	sub    $0xc,%esp
f0102c95:	6a 00                	push   $0x0
f0102c97:	e8 9a e3 ff ff       	call   f0101036 <page_alloc>
f0102c9c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c9f:	83 c4 10             	add    $0x10,%esp
f0102ca2:	85 c0                	test   %eax,%eax
f0102ca4:	0f 84 1b 02 00 00    	je     f0102ec5 <mem_init+0x1b21>
	assert((pp2 = page_alloc(0)));
f0102caa:	83 ec 0c             	sub    $0xc,%esp
f0102cad:	6a 00                	push   $0x0
f0102caf:	e8 82 e3 ff ff       	call   f0101036 <page_alloc>
f0102cb4:	89 c7                	mov    %eax,%edi
f0102cb6:	83 c4 10             	add    $0x10,%esp
f0102cb9:	85 c0                	test   %eax,%eax
f0102cbb:	0f 84 26 02 00 00    	je     f0102ee7 <mem_init+0x1b43>
	page_free(pp0);
f0102cc1:	83 ec 0c             	sub    $0xc,%esp
f0102cc4:	56                   	push   %esi
f0102cc5:	e8 f1 e3 ff ff       	call   f01010bb <page_free>
	return (pp - pages) << PGSHIFT;
f0102cca:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ccd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cd0:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0102cd6:	c1 f8 03             	sar    $0x3,%eax
f0102cd9:	89 c2                	mov    %eax,%edx
f0102cdb:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102cde:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102ce3:	83 c4 10             	add    $0x10,%esp
f0102ce6:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0102cec:	0f 83 17 02 00 00    	jae    f0102f09 <mem_init+0x1b65>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cf2:	83 ec 04             	sub    $0x4,%esp
f0102cf5:	68 00 10 00 00       	push   $0x1000
f0102cfa:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102cfc:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d02:	52                   	push   %edx
f0102d03:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d06:	e8 14 10 00 00       	call   f0103d1f <memset>
	return (pp - pages) << PGSHIFT;
f0102d0b:	89 f8                	mov    %edi,%eax
f0102d0d:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0102d13:	c1 f8 03             	sar    $0x3,%eax
f0102d16:	89 c2                	mov    %eax,%edx
f0102d18:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d1b:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d20:	83 c4 10             	add    $0x10,%esp
f0102d23:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f0102d29:	0f 83 f2 01 00 00    	jae    f0102f21 <mem_init+0x1b7d>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d2f:	83 ec 04             	sub    $0x4,%esp
f0102d32:	68 00 10 00 00       	push   $0x1000
f0102d37:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102d39:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102d3f:	52                   	push   %edx
f0102d40:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d43:	e8 d7 0f 00 00       	call   f0103d1f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d48:	6a 02                	push   $0x2
f0102d4a:	68 00 10 00 00       	push   $0x1000
f0102d4f:	ff 75 d0             	push   -0x30(%ebp)
f0102d52:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0102d58:	e8 d5 e5 ff ff       	call   f0101332 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d5d:	83 c4 20             	add    $0x20,%esp
f0102d60:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d63:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102d68:	0f 85 cc 01 00 00    	jne    f0102f3a <mem_init+0x1b96>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d6e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d75:	01 01 01 
f0102d78:	0f 85 de 01 00 00    	jne    f0102f5c <mem_init+0x1bb8>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d7e:	6a 02                	push   $0x2
f0102d80:	68 00 10 00 00       	push   $0x1000
f0102d85:	57                   	push   %edi
f0102d86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d89:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0102d8f:	e8 9e e5 ff ff       	call   f0101332 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d94:	83 c4 10             	add    $0x10,%esp
f0102d97:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d9e:	02 02 02 
f0102da1:	0f 85 d7 01 00 00    	jne    f0102f7e <mem_init+0x1bda>
	assert(pp2->pp_ref == 1);
f0102da7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102dac:	0f 85 ee 01 00 00    	jne    f0102fa0 <mem_init+0x1bfc>
	assert(pp1->pp_ref == 0);
f0102db2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102db5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102dba:	0f 85 02 02 00 00    	jne    f0102fc2 <mem_init+0x1c1e>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102dc0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102dc7:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102dca:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102dcd:	89 f8                	mov    %edi,%eax
f0102dcf:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0102dd5:	c1 f8 03             	sar    $0x3,%eax
f0102dd8:	89 c2                	mov    %eax,%edx
f0102dda:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102ddd:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102de2:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0102de8:	0f 83 f6 01 00 00    	jae    f0102fe4 <mem_init+0x1c40>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dee:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102df5:	03 03 03 
f0102df8:	0f 85 fe 01 00 00    	jne    f0102ffc <mem_init+0x1c58>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dfe:	83 ec 08             	sub    $0x8,%esp
f0102e01:	68 00 10 00 00       	push   $0x1000
f0102e06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e09:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0102e0f:	e8 dc e4 ff ff       	call   f01012f0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e14:	83 c4 10             	add    $0x10,%esp
f0102e17:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e1c:	0f 85 fc 01 00 00    	jne    f010301e <mem_init+0x1c7a>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e25:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0102e2b:	8b 11                	mov    (%ecx),%edx
f0102e2d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102e33:	89 f7                	mov    %esi,%edi
f0102e35:	2b b8 ac 1f 00 00    	sub    0x1fac(%eax),%edi
f0102e3b:	89 f8                	mov    %edi,%eax
f0102e3d:	c1 f8 03             	sar    $0x3,%eax
f0102e40:	c1 e0 0c             	shl    $0xc,%eax
f0102e43:	39 c2                	cmp    %eax,%edx
f0102e45:	0f 85 f5 01 00 00    	jne    f0103040 <mem_init+0x1c9c>
	kern_pgdir[0] = 0;
f0102e4b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102e51:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e56:	0f 85 06 02 00 00    	jne    f0103062 <mem_init+0x1cbe>
	pp0->pp_ref = 0;
f0102e5c:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e62:	83 ec 0c             	sub    $0xc,%esp
f0102e65:	56                   	push   %esi
f0102e66:	e8 50 e2 ff ff       	call   f01010bb <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e6b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e6e:	8d 83 d0 dd fe ff    	lea    -0x12230(%ebx),%eax
f0102e74:	89 04 24             	mov    %eax,(%esp)
f0102e77:	e8 a2 02 00 00       	call   f010311e <cprintf>
}
f0102e7c:	83 c4 10             	add    $0x10,%esp
f0102e7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e82:	5b                   	pop    %ebx
f0102e83:	5e                   	pop    %esi
f0102e84:	5f                   	pop    %edi
f0102e85:	5d                   	pop    %ebp
f0102e86:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e87:	50                   	push   %eax
f0102e88:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e8b:	8d 83 68 d7 fe ff    	lea    -0x12898(%ebx),%eax
f0102e91:	50                   	push   %eax
f0102e92:	68 dd 00 00 00       	push   $0xdd
f0102e97:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102e9d:	50                   	push   %eax
f0102e9e:	e8 f6 d1 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102ea3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ea6:	8d 83 21 d4 fe ff    	lea    -0x12bdf(%ebx),%eax
f0102eac:	50                   	push   %eax
f0102ead:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102eb3:	50                   	push   %eax
f0102eb4:	68 8a 03 00 00       	push   $0x38a
f0102eb9:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102ebf:	50                   	push   %eax
f0102ec0:	e8 d4 d1 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ec5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ec8:	8d 83 37 d4 fe ff    	lea    -0x12bc9(%ebx),%eax
f0102ece:	50                   	push   %eax
f0102ecf:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	68 8b 03 00 00       	push   $0x38b
f0102edb:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102ee1:	50                   	push   %eax
f0102ee2:	e8 b2 d1 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ee7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eea:	8d 83 4d d4 fe ff    	lea    -0x12bb3(%ebx),%eax
f0102ef0:	50                   	push   %eax
f0102ef1:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102ef7:	50                   	push   %eax
f0102ef8:	68 8c 03 00 00       	push   $0x38c
f0102efd:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102f03:	50                   	push   %eax
f0102f04:	e8 90 d1 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f09:	52                   	push   %edx
f0102f0a:	89 cb                	mov    %ecx,%ebx
f0102f0c:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f0102f12:	50                   	push   %eax
f0102f13:	6a 52                	push   $0x52
f0102f15:	8d 81 1c d3 fe ff    	lea    -0x12ce4(%ecx),%eax
f0102f1b:	50                   	push   %eax
f0102f1c:	e8 78 d1 ff ff       	call   f0100099 <_panic>
f0102f21:	52                   	push   %edx
f0102f22:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f25:	8d 83 5c d6 fe ff    	lea    -0x129a4(%ebx),%eax
f0102f2b:	50                   	push   %eax
f0102f2c:	6a 52                	push   $0x52
f0102f2e:	8d 83 1c d3 fe ff    	lea    -0x12ce4(%ebx),%eax
f0102f34:	50                   	push   %eax
f0102f35:	e8 5f d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102f3a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f3d:	8d 83 1e d5 fe ff    	lea    -0x12ae2(%ebx),%eax
f0102f43:	50                   	push   %eax
f0102f44:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102f4a:	50                   	push   %eax
f0102f4b:	68 91 03 00 00       	push   $0x391
f0102f50:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102f56:	50                   	push   %eax
f0102f57:	e8 3d d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102f5c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f5f:	8d 83 5c dd fe ff    	lea    -0x122a4(%ebx),%eax
f0102f65:	50                   	push   %eax
f0102f66:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102f6c:	50                   	push   %eax
f0102f6d:	68 92 03 00 00       	push   $0x392
f0102f72:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102f78:	50                   	push   %eax
f0102f79:	e8 1b d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f7e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f81:	8d 83 80 dd fe ff    	lea    -0x12280(%ebx),%eax
f0102f87:	50                   	push   %eax
f0102f88:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102f8e:	50                   	push   %eax
f0102f8f:	68 94 03 00 00       	push   $0x394
f0102f94:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102f9a:	50                   	push   %eax
f0102f9b:	e8 f9 d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102fa0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fa3:	8d 83 40 d5 fe ff    	lea    -0x12ac0(%ebx),%eax
f0102fa9:	50                   	push   %eax
f0102faa:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102fb0:	50                   	push   %eax
f0102fb1:	68 95 03 00 00       	push   $0x395
f0102fb6:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102fbc:	50                   	push   %eax
f0102fbd:	e8 d7 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102fc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc5:	8d 83 aa d5 fe ff    	lea    -0x12a56(%ebx),%eax
f0102fcb:	50                   	push   %eax
f0102fcc:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0102fd2:	50                   	push   %eax
f0102fd3:	68 96 03 00 00       	push   $0x396
f0102fd8:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0102fde:	50                   	push   %eax
f0102fdf:	e8 b5 d0 ff ff       	call   f0100099 <_panic>
f0102fe4:	52                   	push   %edx
f0102fe5:	89 cb                	mov    %ecx,%ebx
f0102fe7:	8d 81 5c d6 fe ff    	lea    -0x129a4(%ecx),%eax
f0102fed:	50                   	push   %eax
f0102fee:	6a 52                	push   $0x52
f0102ff0:	8d 81 1c d3 fe ff    	lea    -0x12ce4(%ecx),%eax
f0102ff6:	50                   	push   %eax
f0102ff7:	e8 9d d0 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ffc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fff:	8d 83 a4 dd fe ff    	lea    -0x1225c(%ebx),%eax
f0103005:	50                   	push   %eax
f0103006:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010300c:	50                   	push   %eax
f010300d:	68 98 03 00 00       	push   $0x398
f0103012:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0103018:	50                   	push   %eax
f0103019:	e8 7b d0 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010301e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103021:	8d 83 78 d5 fe ff    	lea    -0x12a88(%ebx),%eax
f0103027:	50                   	push   %eax
f0103028:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f010302e:	50                   	push   %eax
f010302f:	68 9a 03 00 00       	push   $0x39a
f0103034:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010303a:	50                   	push   %eax
f010303b:	e8 59 d0 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103040:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103043:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0103049:	50                   	push   %eax
f010304a:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0103050:	50                   	push   %eax
f0103051:	68 9d 03 00 00       	push   $0x39d
f0103056:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010305c:	50                   	push   %eax
f010305d:	e8 37 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0103062:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103065:	8d 83 2f d5 fe ff    	lea    -0x12ad1(%ebx),%eax
f010306b:	50                   	push   %eax
f010306c:	8d 83 36 d3 fe ff    	lea    -0x12cca(%ebx),%eax
f0103072:	50                   	push   %eax
f0103073:	68 9f 03 00 00       	push   $0x39f
f0103078:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f010307e:	50                   	push   %eax
f010307f:	e8 15 d0 ff ff       	call   f0100099 <_panic>

f0103084 <tlb_invalidate>:
{
f0103084:	55                   	push   %ebp
f0103085:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103087:	8b 45 0c             	mov    0xc(%ebp),%eax
f010308a:	0f 01 38             	invlpg (%eax)
}
f010308d:	5d                   	pop    %ebp
f010308e:	c3                   	ret    

f010308f <__x86.get_pc_thunk.cx>:
f010308f:	8b 0c 24             	mov    (%esp),%ecx
f0103092:	c3                   	ret    

f0103093 <__x86.get_pc_thunk.di>:
f0103093:	8b 3c 24             	mov    (%esp),%edi
f0103096:	c3                   	ret    

f0103097 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103097:	55                   	push   %ebp
f0103098:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010309a:	8b 45 08             	mov    0x8(%ebp),%eax
f010309d:	ba 70 00 00 00       	mov    $0x70,%edx
f01030a2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030a3:	ba 71 00 00 00       	mov    $0x71,%edx
f01030a8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030a9:	0f b6 c0             	movzbl %al,%eax
}
f01030ac:	5d                   	pop    %ebp
f01030ad:	c3                   	ret    

f01030ae <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030ae:	55                   	push   %ebp
f01030af:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01030b4:	ba 70 00 00 00       	mov    $0x70,%edx
f01030b9:	ee                   	out    %al,(%dx)
f01030ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030bd:	ba 71 00 00 00       	mov    $0x71,%edx
f01030c2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030c3:	5d                   	pop    %ebp
f01030c4:	c3                   	ret    

f01030c5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030c5:	55                   	push   %ebp
f01030c6:	89 e5                	mov    %esp,%ebp
f01030c8:	53                   	push   %ebx
f01030c9:	83 ec 10             	sub    $0x10,%esp
f01030cc:	e8 7e d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030d1:	81 c3 3b 42 01 00    	add    $0x1423b,%ebx
	cputchar(ch);
f01030d7:	ff 75 08             	push   0x8(%ebp)
f01030da:	e8 db d5 ff ff       	call   f01006ba <cputchar>
	*cnt++;
}
f01030df:	83 c4 10             	add    $0x10,%esp
f01030e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030e5:	c9                   	leave  
f01030e6:	c3                   	ret    

f01030e7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030e7:	55                   	push   %ebp
f01030e8:	89 e5                	mov    %esp,%ebp
f01030ea:	53                   	push   %ebx
f01030eb:	83 ec 14             	sub    $0x14,%esp
f01030ee:	e8 5c d0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01030f3:	81 c3 19 42 01 00    	add    $0x14219,%ebx
	int cnt = 0;
f01030f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103100:	ff 75 0c             	push   0xc(%ebp)
f0103103:	ff 75 08             	push   0x8(%ebp)
f0103106:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103109:	50                   	push   %eax
f010310a:	8d 83 b9 bd fe ff    	lea    -0x14247(%ebx),%eax
f0103110:	50                   	push   %eax
f0103111:	e8 5c 04 00 00       	call   f0103572 <vprintfmt>
	return cnt;
}
f0103116:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010311c:	c9                   	leave  
f010311d:	c3                   	ret    

f010311e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010311e:	55                   	push   %ebp
f010311f:	89 e5                	mov    %esp,%ebp
f0103121:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103124:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103127:	50                   	push   %eax
f0103128:	ff 75 08             	push   0x8(%ebp)
f010312b:	e8 b7 ff ff ff       	call   f01030e7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103130:	c9                   	leave  
f0103131:	c3                   	ret    

f0103132 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103132:	55                   	push   %ebp
f0103133:	89 e5                	mov    %esp,%ebp
f0103135:	57                   	push   %edi
f0103136:	56                   	push   %esi
f0103137:	53                   	push   %ebx
f0103138:	83 ec 14             	sub    $0x14,%esp
f010313b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010313e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103141:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103144:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103147:	8b 1a                	mov    (%edx),%ebx
f0103149:	8b 01                	mov    (%ecx),%eax
f010314b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010314e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103155:	eb 2f                	jmp    f0103186 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103157:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f010315a:	39 c3                	cmp    %eax,%ebx
f010315c:	7f 4e                	jg     f01031ac <stab_binsearch+0x7a>
f010315e:	0f b6 0a             	movzbl (%edx),%ecx
f0103161:	83 ea 0c             	sub    $0xc,%edx
f0103164:	39 f1                	cmp    %esi,%ecx
f0103166:	75 ef                	jne    f0103157 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103168:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010316b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010316e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103172:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103175:	73 3a                	jae    f01031b1 <stab_binsearch+0x7f>
			*region_left = m;
f0103177:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010317a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010317c:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f010317f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103186:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103189:	7f 53                	jg     f01031de <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f010318b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010318e:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f0103191:	89 d0                	mov    %edx,%eax
f0103193:	c1 e8 1f             	shr    $0x1f,%eax
f0103196:	01 d0                	add    %edx,%eax
f0103198:	89 c7                	mov    %eax,%edi
f010319a:	d1 ff                	sar    %edi
f010319c:	83 e0 fe             	and    $0xfffffffe,%eax
f010319f:	01 f8                	add    %edi,%eax
f01031a1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01031a4:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01031a8:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01031aa:	eb ae                	jmp    f010315a <stab_binsearch+0x28>
			l = true_m + 1;
f01031ac:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01031af:	eb d5                	jmp    f0103186 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01031b1:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01031b4:	76 14                	jbe    f01031ca <stab_binsearch+0x98>
			*region_right = m - 1;
f01031b6:	83 e8 01             	sub    $0x1,%eax
f01031b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031bc:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031bf:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f01031c1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031c8:	eb bc                	jmp    f0103186 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01031ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01031cd:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f01031cf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01031d3:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f01031d5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031dc:	eb a8                	jmp    f0103186 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01031de:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031e2:	75 15                	jne    f01031f9 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f01031e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e7:	8b 00                	mov    (%eax),%eax
f01031e9:	83 e8 01             	sub    $0x1,%eax
f01031ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031ef:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01031f1:	83 c4 14             	add    $0x14,%esp
f01031f4:	5b                   	pop    %ebx
f01031f5:	5e                   	pop    %esi
f01031f6:	5f                   	pop    %edi
f01031f7:	5d                   	pop    %ebp
f01031f8:	c3                   	ret    
		for (l = *region_right;
f01031f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031fc:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103201:	8b 0f                	mov    (%edi),%ecx
f0103203:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103206:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103209:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f010320d:	39 c1                	cmp    %eax,%ecx
f010320f:	7d 0f                	jge    f0103220 <stab_binsearch+0xee>
f0103211:	0f b6 1a             	movzbl (%edx),%ebx
f0103214:	83 ea 0c             	sub    $0xc,%edx
f0103217:	39 f3                	cmp    %esi,%ebx
f0103219:	74 05                	je     f0103220 <stab_binsearch+0xee>
		     l--)
f010321b:	83 e8 01             	sub    $0x1,%eax
f010321e:	eb ed                	jmp    f010320d <stab_binsearch+0xdb>
		*region_left = l;
f0103220:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103223:	89 07                	mov    %eax,(%edi)
}
f0103225:	eb ca                	jmp    f01031f1 <stab_binsearch+0xbf>

f0103227 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103227:	55                   	push   %ebp
f0103228:	89 e5                	mov    %esp,%ebp
f010322a:	57                   	push   %edi
f010322b:	56                   	push   %esi
f010322c:	53                   	push   %ebx
f010322d:	83 ec 3c             	sub    $0x3c,%esp
f0103230:	e8 1a cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103235:	81 c3 d7 40 01 00    	add    $0x140d7,%ebx
f010323b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010323e:	8d 83 f9 dd fe ff    	lea    -0x12207(%ebx),%eax
f0103244:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103246:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010324d:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103250:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103257:	8b 45 08             	mov    0x8(%ebp),%eax
f010325a:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f010325d:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103264:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0103269:	0f 86 3e 01 00 00    	jbe    f01033ad <debuginfo_eip+0x186>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010326f:	c7 c0 3d ba 10 f0    	mov    $0xf010ba3d,%eax
f0103275:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f010327b:	0f 86 d0 01 00 00    	jbe    f0103451 <debuginfo_eip+0x22a>
f0103281:	c7 c0 91 d7 10 f0    	mov    $0xf010d791,%eax
f0103287:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010328b:	0f 85 c7 01 00 00    	jne    f0103458 <debuginfo_eip+0x231>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103291:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103298:	c7 c0 1c 53 10 f0    	mov    $0xf010531c,%eax
f010329e:	c7 c2 3c ba 10 f0    	mov    $0xf010ba3c,%edx
f01032a4:	29 c2                	sub    %eax,%edx
f01032a6:	c1 fa 02             	sar    $0x2,%edx
f01032a9:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01032af:	83 ea 01             	sub    $0x1,%edx
f01032b2:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032b5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01032b8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032bb:	83 ec 08             	sub    $0x8,%esp
f01032be:	ff 75 08             	push   0x8(%ebp)
f01032c1:	6a 64                	push   $0x64
f01032c3:	e8 6a fe ff ff       	call   f0103132 <stab_binsearch>
	if (lfile == 0)
f01032c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032cb:	83 c4 10             	add    $0x10,%esp
f01032ce:	85 ff                	test   %edi,%edi
f01032d0:	0f 84 89 01 00 00    	je     f010345f <debuginfo_eip+0x238>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01032d6:	89 7d dc             	mov    %edi,-0x24(%ebp)
	rfun = rfile;
f01032d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032dc:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01032df:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032e2:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01032e5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032e8:	83 ec 08             	sub    $0x8,%esp
f01032eb:	ff 75 08             	push   0x8(%ebp)
f01032ee:	6a 24                	push   $0x24
f01032f0:	c7 c0 1c 53 10 f0    	mov    $0xf010531c,%eax
f01032f6:	e8 37 fe ff ff       	call   f0103132 <stab_binsearch>

	if (lfun <= rfun) {
f01032fb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01032fe:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0103301:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103304:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103307:	83 c4 10             	add    $0x10,%esp
f010330a:	89 f8                	mov    %edi,%eax
f010330c:	39 d1                	cmp    %edx,%ecx
f010330e:	7f 39                	jg     f0103349 <debuginfo_eip+0x122>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103310:	8d 04 49             	lea    (%ecx,%ecx,2),%eax
f0103313:	c7 c2 1c 53 10 f0    	mov    $0xf010531c,%edx
f0103319:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f010331c:	8b 11                	mov    (%ecx),%edx
f010331e:	c7 c0 91 d7 10 f0    	mov    $0xf010d791,%eax
f0103324:	81 e8 3d ba 10 f0    	sub    $0xf010ba3d,%eax
f010332a:	39 c2                	cmp    %eax,%edx
f010332c:	73 09                	jae    f0103337 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010332e:	81 c2 3d ba 10 f0    	add    $0xf010ba3d,%edx
f0103334:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103337:	8b 41 08             	mov    0x8(%ecx),%eax
f010333a:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010333d:	29 45 08             	sub    %eax,0x8(%ebp)
f0103340:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103343:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103346:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0103349:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010334c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010334f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103352:	83 ec 08             	sub    $0x8,%esp
f0103355:	6a 3a                	push   $0x3a
f0103357:	ff 76 08             	push   0x8(%esi)
f010335a:	e8 a4 09 00 00       	call   f0103d03 <strfind>
f010335f:	2b 46 08             	sub    0x8(%esi),%eax
f0103362:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103365:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103368:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010336b:	83 c4 08             	add    $0x8,%esp
f010336e:	ff 75 08             	push   0x8(%ebp)
f0103371:	6a 44                	push   $0x44
f0103373:	c7 c0 1c 53 10 f0    	mov    $0xf010531c,%eax
f0103379:	e8 b4 fd ff ff       	call   f0103132 <stab_binsearch>
		if (lline <= rline)	{
f010337e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103381:	83 c4 10             	add    $0x10,%esp
f0103384:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103387:	0f 8f d9 00 00 00    	jg     f0103466 <debuginfo_eip+0x23f>
			info->eip_line = stabs[lline].n_desc;
f010338d:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103390:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0103393:	c7 c0 1c 53 10 f0    	mov    $0xf010531c,%eax
f0103399:	0f b7 54 88 06       	movzwl 0x6(%eax,%ecx,4),%edx
f010339e:	89 56 04             	mov    %edx,0x4(%esi)
f01033a1:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax
f01033a5:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01033a8:	89 75 0c             	mov    %esi,0xc(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01033ab:	eb 1e                	jmp    f01033cb <debuginfo_eip+0x1a4>
  	        panic("User address");
f01033ad:	83 ec 04             	sub    $0x4,%esp
f01033b0:	8d 83 03 de fe ff    	lea    -0x121fd(%ebx),%eax
f01033b6:	50                   	push   %eax
f01033b7:	6a 7f                	push   $0x7f
f01033b9:	8d 83 10 de fe ff    	lea    -0x121f0(%ebx),%eax
f01033bf:	50                   	push   %eax
f01033c0:	e8 d4 cc ff ff       	call   f0100099 <_panic>
f01033c5:	83 ea 01             	sub    $0x1,%edx
f01033c8:	83 e8 0c             	sub    $0xc,%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033cb:	39 d7                	cmp    %edx,%edi
f01033cd:	7f 3c                	jg     f010340b <debuginfo_eip+0x1e4>
	       && stabs[lline].n_type != N_SOL
f01033cf:	0f b6 08             	movzbl (%eax),%ecx
f01033d2:	80 f9 84             	cmp    $0x84,%cl
f01033d5:	74 0b                	je     f01033e2 <debuginfo_eip+0x1bb>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033d7:	80 f9 64             	cmp    $0x64,%cl
f01033da:	75 e9                	jne    f01033c5 <debuginfo_eip+0x19e>
f01033dc:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f01033e0:	74 e3                	je     f01033c5 <debuginfo_eip+0x19e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01033e2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033e5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01033e8:	c7 c0 1c 53 10 f0    	mov    $0xf010531c,%eax
f01033ee:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01033f1:	c7 c0 91 d7 10 f0    	mov    $0xf010d791,%eax
f01033f7:	81 e8 3d ba 10 f0    	sub    $0xf010ba3d,%eax
f01033fd:	39 c2                	cmp    %eax,%edx
f01033ff:	73 0d                	jae    f010340e <debuginfo_eip+0x1e7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103401:	81 c2 3d ba 10 f0    	add    $0xf010ba3d,%edx
f0103407:	89 16                	mov    %edx,(%esi)
f0103409:	eb 03                	jmp    f010340e <debuginfo_eip+0x1e7>
f010340b:	8b 75 0c             	mov    0xc(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010340e:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103413:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103416:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103419:	39 cf                	cmp    %ecx,%edi
f010341b:	7d 55                	jge    f0103472 <debuginfo_eip+0x24b>
		for (lline = lfun + 1;
f010341d:	83 c7 01             	add    $0x1,%edi
f0103420:	89 f8                	mov    %edi,%eax
f0103422:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0103425:	c7 c2 1c 53 10 f0    	mov    $0xf010531c,%edx
f010342b:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f010342f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103432:	eb 04                	jmp    f0103438 <debuginfo_eip+0x211>
			info->eip_fn_narg++;
f0103434:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103438:	39 c3                	cmp    %eax,%ebx
f010343a:	7e 31                	jle    f010346d <debuginfo_eip+0x246>
f010343c:	0f b6 0a             	movzbl (%edx),%ecx
f010343f:	83 c0 01             	add    $0x1,%eax
f0103442:	83 c2 0c             	add    $0xc,%edx
f0103445:	80 f9 a0             	cmp    $0xa0,%cl
f0103448:	74 ea                	je     f0103434 <debuginfo_eip+0x20d>
	return 0;
f010344a:	b8 00 00 00 00       	mov    $0x0,%eax
f010344f:	eb 21                	jmp    f0103472 <debuginfo_eip+0x24b>
		return -1;
f0103451:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103456:	eb 1a                	jmp    f0103472 <debuginfo_eip+0x24b>
f0103458:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010345d:	eb 13                	jmp    f0103472 <debuginfo_eip+0x24b>
		return -1;
f010345f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103464:	eb 0c                	jmp    f0103472 <debuginfo_eip+0x24b>
		else return -1;
f0103466:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010346b:	eb 05                	jmp    f0103472 <debuginfo_eip+0x24b>
	return 0;
f010346d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103472:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103475:	5b                   	pop    %ebx
f0103476:	5e                   	pop    %esi
f0103477:	5f                   	pop    %edi
f0103478:	5d                   	pop    %ebp
f0103479:	c3                   	ret    

f010347a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010347a:	55                   	push   %ebp
f010347b:	89 e5                	mov    %esp,%ebp
f010347d:	57                   	push   %edi
f010347e:	56                   	push   %esi
f010347f:	53                   	push   %ebx
f0103480:	83 ec 2c             	sub    $0x2c,%esp
f0103483:	e8 07 fc ff ff       	call   f010308f <__x86.get_pc_thunk.cx>
f0103488:	81 c1 84 3e 01 00    	add    $0x13e84,%ecx
f010348e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103491:	89 c7                	mov    %eax,%edi
f0103493:	89 d6                	mov    %edx,%esi
f0103495:	8b 45 08             	mov    0x8(%ebp),%eax
f0103498:	8b 55 0c             	mov    0xc(%ebp),%edx
f010349b:	89 d1                	mov    %edx,%ecx
f010349d:	89 c2                	mov    %eax,%edx
f010349f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034a2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01034a5:	8b 45 10             	mov    0x10(%ebp),%eax
f01034a8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01034ab:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034ae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01034b5:	39 c2                	cmp    %eax,%edx
f01034b7:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f01034ba:	72 41                	jb     f01034fd <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01034bc:	83 ec 0c             	sub    $0xc,%esp
f01034bf:	ff 75 18             	push   0x18(%ebp)
f01034c2:	83 eb 01             	sub    $0x1,%ebx
f01034c5:	53                   	push   %ebx
f01034c6:	50                   	push   %eax
f01034c7:	83 ec 08             	sub    $0x8,%esp
f01034ca:	ff 75 e4             	push   -0x1c(%ebp)
f01034cd:	ff 75 e0             	push   -0x20(%ebp)
f01034d0:	ff 75 d4             	push   -0x2c(%ebp)
f01034d3:	ff 75 d0             	push   -0x30(%ebp)
f01034d6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01034d9:	e8 32 0a 00 00       	call   f0103f10 <__udivdi3>
f01034de:	83 c4 18             	add    $0x18,%esp
f01034e1:	52                   	push   %edx
f01034e2:	50                   	push   %eax
f01034e3:	89 f2                	mov    %esi,%edx
f01034e5:	89 f8                	mov    %edi,%eax
f01034e7:	e8 8e ff ff ff       	call   f010347a <printnum>
f01034ec:	83 c4 20             	add    $0x20,%esp
f01034ef:	eb 13                	jmp    f0103504 <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01034f1:	83 ec 08             	sub    $0x8,%esp
f01034f4:	56                   	push   %esi
f01034f5:	ff 75 18             	push   0x18(%ebp)
f01034f8:	ff d7                	call   *%edi
f01034fa:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01034fd:	83 eb 01             	sub    $0x1,%ebx
f0103500:	85 db                	test   %ebx,%ebx
f0103502:	7f ed                	jg     f01034f1 <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103504:	83 ec 08             	sub    $0x8,%esp
f0103507:	56                   	push   %esi
f0103508:	83 ec 04             	sub    $0x4,%esp
f010350b:	ff 75 e4             	push   -0x1c(%ebp)
f010350e:	ff 75 e0             	push   -0x20(%ebp)
f0103511:	ff 75 d4             	push   -0x2c(%ebp)
f0103514:	ff 75 d0             	push   -0x30(%ebp)
f0103517:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010351a:	e8 11 0b 00 00       	call   f0104030 <__umoddi3>
f010351f:	83 c4 14             	add    $0x14,%esp
f0103522:	0f be 84 03 1e de fe 	movsbl -0x121e2(%ebx,%eax,1),%eax
f0103529:	ff 
f010352a:	50                   	push   %eax
f010352b:	ff d7                	call   *%edi
}
f010352d:	83 c4 10             	add    $0x10,%esp
f0103530:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103533:	5b                   	pop    %ebx
f0103534:	5e                   	pop    %esi
f0103535:	5f                   	pop    %edi
f0103536:	5d                   	pop    %ebp
f0103537:	c3                   	ret    

f0103538 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103538:	55                   	push   %ebp
f0103539:	89 e5                	mov    %esp,%ebp
f010353b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010353e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103542:	8b 10                	mov    (%eax),%edx
f0103544:	3b 50 04             	cmp    0x4(%eax),%edx
f0103547:	73 0a                	jae    f0103553 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103549:	8d 4a 01             	lea    0x1(%edx),%ecx
f010354c:	89 08                	mov    %ecx,(%eax)
f010354e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103551:	88 02                	mov    %al,(%edx)
}
f0103553:	5d                   	pop    %ebp
f0103554:	c3                   	ret    

f0103555 <printfmt>:
{
f0103555:	55                   	push   %ebp
f0103556:	89 e5                	mov    %esp,%ebp
f0103558:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010355b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010355e:	50                   	push   %eax
f010355f:	ff 75 10             	push   0x10(%ebp)
f0103562:	ff 75 0c             	push   0xc(%ebp)
f0103565:	ff 75 08             	push   0x8(%ebp)
f0103568:	e8 05 00 00 00       	call   f0103572 <vprintfmt>
}
f010356d:	83 c4 10             	add    $0x10,%esp
f0103570:	c9                   	leave  
f0103571:	c3                   	ret    

f0103572 <vprintfmt>:
{
f0103572:	55                   	push   %ebp
f0103573:	89 e5                	mov    %esp,%ebp
f0103575:	57                   	push   %edi
f0103576:	56                   	push   %esi
f0103577:	53                   	push   %ebx
f0103578:	83 ec 3c             	sub    $0x3c,%esp
f010357b:	e8 61 d1 ff ff       	call   f01006e1 <__x86.get_pc_thunk.ax>
f0103580:	05 8c 3d 01 00       	add    $0x13d8c,%eax
f0103585:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103588:	8b 75 08             	mov    0x8(%ebp),%esi
f010358b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010358e:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103591:	8d 80 1c 1d 00 00    	lea    0x1d1c(%eax),%eax
f0103597:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010359a:	eb 0a                	jmp    f01035a6 <vprintfmt+0x34>
			putch(ch, putdat);
f010359c:	83 ec 08             	sub    $0x8,%esp
f010359f:	57                   	push   %edi
f01035a0:	50                   	push   %eax
f01035a1:	ff d6                	call   *%esi
f01035a3:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01035a6:	83 c3 01             	add    $0x1,%ebx
f01035a9:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01035ad:	83 f8 25             	cmp    $0x25,%eax
f01035b0:	74 0c                	je     f01035be <vprintfmt+0x4c>
			if (ch == '\0')
f01035b2:	85 c0                	test   %eax,%eax
f01035b4:	75 e6                	jne    f010359c <vprintfmt+0x2a>
}
f01035b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035b9:	5b                   	pop    %ebx
f01035ba:	5e                   	pop    %esi
f01035bb:	5f                   	pop    %edi
f01035bc:	5d                   	pop    %ebp
f01035bd:	c3                   	ret    
		padc = ' ';
f01035be:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f01035c2:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f01035c9:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01035d0:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f01035d7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035dc:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01035df:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035e2:	8d 43 01             	lea    0x1(%ebx),%eax
f01035e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035e8:	0f b6 13             	movzbl (%ebx),%edx
f01035eb:	8d 42 dd             	lea    -0x23(%edx),%eax
f01035ee:	3c 55                	cmp    $0x55,%al
f01035f0:	0f 87 fd 03 00 00    	ja     f01039f3 <.L20>
f01035f6:	0f b6 c0             	movzbl %al,%eax
f01035f9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01035fc:	89 ce                	mov    %ecx,%esi
f01035fe:	03 b4 81 a8 de fe ff 	add    -0x12158(%ecx,%eax,4),%esi
f0103605:	ff e6                	jmp    *%esi

f0103607 <.L68>:
f0103607:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f010360a:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f010360e:	eb d2                	jmp    f01035e2 <vprintfmt+0x70>

f0103610 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0103610:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103613:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0103617:	eb c9                	jmp    f01035e2 <vprintfmt+0x70>

f0103619 <.L31>:
f0103619:	0f b6 d2             	movzbl %dl,%edx
f010361c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f010361f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103624:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0103627:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010362a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010362e:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0103631:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103634:	83 f9 09             	cmp    $0x9,%ecx
f0103637:	77 58                	ja     f0103691 <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0103639:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010363c:	eb e9                	jmp    f0103627 <.L31+0xe>

f010363e <.L34>:
			precision = va_arg(ap, int);
f010363e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103641:	8b 00                	mov    (%eax),%eax
f0103643:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103646:	8b 45 14             	mov    0x14(%ebp),%eax
f0103649:	8d 40 04             	lea    0x4(%eax),%eax
f010364c:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010364f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0103652:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103656:	79 8a                	jns    f01035e2 <vprintfmt+0x70>
				width = precision, precision = -1;
f0103658:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010365b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010365e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0103665:	e9 78 ff ff ff       	jmp    f01035e2 <vprintfmt+0x70>

f010366a <.L33>:
f010366a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010366d:	85 d2                	test   %edx,%edx
f010366f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103674:	0f 49 c2             	cmovns %edx,%eax
f0103677:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010367a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010367d:	e9 60 ff ff ff       	jmp    f01035e2 <vprintfmt+0x70>

f0103682 <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f0103682:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0103685:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f010368c:	e9 51 ff ff ff       	jmp    f01035e2 <vprintfmt+0x70>
f0103691:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103694:	89 75 08             	mov    %esi,0x8(%ebp)
f0103697:	eb b9                	jmp    f0103652 <.L34+0x14>

f0103699 <.L27>:
			lflag++;
f0103699:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010369d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01036a0:	e9 3d ff ff ff       	jmp    f01035e2 <vprintfmt+0x70>

f01036a5 <.L30>:
			putch(va_arg(ap, int), putdat);
f01036a5:	8b 75 08             	mov    0x8(%ebp),%esi
f01036a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ab:	8d 58 04             	lea    0x4(%eax),%ebx
f01036ae:	83 ec 08             	sub    $0x8,%esp
f01036b1:	57                   	push   %edi
f01036b2:	ff 30                	push   (%eax)
f01036b4:	ff d6                	call   *%esi
			break;
f01036b6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01036b9:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f01036bc:	e9 c8 02 00 00       	jmp    f0103989 <.L25+0x45>

f01036c1 <.L28>:
			err = va_arg(ap, int);
f01036c1:	8b 75 08             	mov    0x8(%ebp),%esi
f01036c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01036c7:	8d 58 04             	lea    0x4(%eax),%ebx
f01036ca:	8b 10                	mov    (%eax),%edx
f01036cc:	89 d0                	mov    %edx,%eax
f01036ce:	f7 d8                	neg    %eax
f01036d0:	0f 48 c2             	cmovs  %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01036d3:	83 f8 06             	cmp    $0x6,%eax
f01036d6:	7f 27                	jg     f01036ff <.L28+0x3e>
f01036d8:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01036db:	8b 14 82             	mov    (%edx,%eax,4),%edx
f01036de:	85 d2                	test   %edx,%edx
f01036e0:	74 1d                	je     f01036ff <.L28+0x3e>
				printfmt(putch, putdat, "%s", p);
f01036e2:	52                   	push   %edx
f01036e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036e6:	8d 80 48 d3 fe ff    	lea    -0x12cb8(%eax),%eax
f01036ec:	50                   	push   %eax
f01036ed:	57                   	push   %edi
f01036ee:	56                   	push   %esi
f01036ef:	e8 61 fe ff ff       	call   f0103555 <printfmt>
f01036f4:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01036f7:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01036fa:	e9 8a 02 00 00       	jmp    f0103989 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f01036ff:	50                   	push   %eax
f0103700:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103703:	8d 80 36 de fe ff    	lea    -0x121ca(%eax),%eax
f0103709:	50                   	push   %eax
f010370a:	57                   	push   %edi
f010370b:	56                   	push   %esi
f010370c:	e8 44 fe ff ff       	call   f0103555 <printfmt>
f0103711:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103714:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103717:	e9 6d 02 00 00       	jmp    f0103989 <.L25+0x45>

f010371c <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f010371c:	8b 75 08             	mov    0x8(%ebp),%esi
f010371f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103722:	83 c0 04             	add    $0x4,%eax
f0103725:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103728:	8b 45 14             	mov    0x14(%ebp),%eax
f010372b:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f010372d:	85 d2                	test   %edx,%edx
f010372f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103732:	8d 80 2f de fe ff    	lea    -0x121d1(%eax),%eax
f0103738:	0f 45 c2             	cmovne %edx,%eax
f010373b:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f010373e:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103742:	7e 06                	jle    f010374a <.L24+0x2e>
f0103744:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f0103748:	75 0d                	jne    f0103757 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f010374a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010374d:	89 c3                	mov    %eax,%ebx
f010374f:	03 45 d4             	add    -0x2c(%ebp),%eax
f0103752:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103755:	eb 58                	jmp    f01037af <.L24+0x93>
f0103757:	83 ec 08             	sub    $0x8,%esp
f010375a:	ff 75 d8             	push   -0x28(%ebp)
f010375d:	ff 75 c8             	push   -0x38(%ebp)
f0103760:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103763:	e8 44 04 00 00       	call   f0103bac <strnlen>
f0103768:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010376b:	29 c2                	sub    %eax,%edx
f010376d:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0103770:	83 c4 10             	add    $0x10,%esp
f0103773:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0103775:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0103779:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010377c:	eb 0f                	jmp    f010378d <.L24+0x71>
					putch(padc, putdat);
f010377e:	83 ec 08             	sub    $0x8,%esp
f0103781:	57                   	push   %edi
f0103782:	ff 75 d4             	push   -0x2c(%ebp)
f0103785:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103787:	83 eb 01             	sub    $0x1,%ebx
f010378a:	83 c4 10             	add    $0x10,%esp
f010378d:	85 db                	test   %ebx,%ebx
f010378f:	7f ed                	jg     f010377e <.L24+0x62>
f0103791:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103794:	85 d2                	test   %edx,%edx
f0103796:	b8 00 00 00 00       	mov    $0x0,%eax
f010379b:	0f 49 c2             	cmovns %edx,%eax
f010379e:	29 c2                	sub    %eax,%edx
f01037a0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01037a3:	eb a5                	jmp    f010374a <.L24+0x2e>
					putch(ch, putdat);
f01037a5:	83 ec 08             	sub    $0x8,%esp
f01037a8:	57                   	push   %edi
f01037a9:	52                   	push   %edx
f01037aa:	ff d6                	call   *%esi
f01037ac:	83 c4 10             	add    $0x10,%esp
f01037af:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01037b2:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01037b4:	83 c3 01             	add    $0x1,%ebx
f01037b7:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01037bb:	0f be d0             	movsbl %al,%edx
f01037be:	85 d2                	test   %edx,%edx
f01037c0:	74 4b                	je     f010380d <.L24+0xf1>
f01037c2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01037c6:	78 06                	js     f01037ce <.L24+0xb2>
f01037c8:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f01037cc:	78 1e                	js     f01037ec <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f01037ce:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01037d2:	74 d1                	je     f01037a5 <.L24+0x89>
f01037d4:	0f be c0             	movsbl %al,%eax
f01037d7:	83 e8 20             	sub    $0x20,%eax
f01037da:	83 f8 5e             	cmp    $0x5e,%eax
f01037dd:	76 c6                	jbe    f01037a5 <.L24+0x89>
					putch('?', putdat);
f01037df:	83 ec 08             	sub    $0x8,%esp
f01037e2:	57                   	push   %edi
f01037e3:	6a 3f                	push   $0x3f
f01037e5:	ff d6                	call   *%esi
f01037e7:	83 c4 10             	add    $0x10,%esp
f01037ea:	eb c3                	jmp    f01037af <.L24+0x93>
f01037ec:	89 cb                	mov    %ecx,%ebx
f01037ee:	eb 0e                	jmp    f01037fe <.L24+0xe2>
				putch(' ', putdat);
f01037f0:	83 ec 08             	sub    $0x8,%esp
f01037f3:	57                   	push   %edi
f01037f4:	6a 20                	push   $0x20
f01037f6:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01037f8:	83 eb 01             	sub    $0x1,%ebx
f01037fb:	83 c4 10             	add    $0x10,%esp
f01037fe:	85 db                	test   %ebx,%ebx
f0103800:	7f ee                	jg     f01037f0 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f0103802:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103805:	89 45 14             	mov    %eax,0x14(%ebp)
f0103808:	e9 7c 01 00 00       	jmp    f0103989 <.L25+0x45>
f010380d:	89 cb                	mov    %ecx,%ebx
f010380f:	eb ed                	jmp    f01037fe <.L24+0xe2>

f0103811 <.L29>:
	if (lflag >= 2)
f0103811:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103814:	8b 75 08             	mov    0x8(%ebp),%esi
f0103817:	83 f9 01             	cmp    $0x1,%ecx
f010381a:	7f 1b                	jg     f0103837 <.L29+0x26>
	else if (lflag)
f010381c:	85 c9                	test   %ecx,%ecx
f010381e:	74 63                	je     f0103883 <.L29+0x72>
		return va_arg(*ap, long);
f0103820:	8b 45 14             	mov    0x14(%ebp),%eax
f0103823:	8b 00                	mov    (%eax),%eax
f0103825:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103828:	99                   	cltd   
f0103829:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010382c:	8b 45 14             	mov    0x14(%ebp),%eax
f010382f:	8d 40 04             	lea    0x4(%eax),%eax
f0103832:	89 45 14             	mov    %eax,0x14(%ebp)
f0103835:	eb 17                	jmp    f010384e <.L29+0x3d>
		return va_arg(*ap, long long);
f0103837:	8b 45 14             	mov    0x14(%ebp),%eax
f010383a:	8b 50 04             	mov    0x4(%eax),%edx
f010383d:	8b 00                	mov    (%eax),%eax
f010383f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103842:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103845:	8b 45 14             	mov    0x14(%ebp),%eax
f0103848:	8d 40 08             	lea    0x8(%eax),%eax
f010384b:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010384e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103851:	8b 5d dc             	mov    -0x24(%ebp),%ebx
			base = 10;
f0103854:	ba 0a 00 00 00       	mov    $0xa,%edx
			if ((long long) num < 0) {
f0103859:	85 db                	test   %ebx,%ebx
f010385b:	0f 89 0e 01 00 00    	jns    f010396f <.L25+0x2b>
				putch('-', putdat);
f0103861:	83 ec 08             	sub    $0x8,%esp
f0103864:	57                   	push   %edi
f0103865:	6a 2d                	push   $0x2d
f0103867:	ff d6                	call   *%esi
				num = -(long long) num;
f0103869:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010386c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010386f:	f7 d9                	neg    %ecx
f0103871:	83 d3 00             	adc    $0x0,%ebx
f0103874:	f7 db                	neg    %ebx
f0103876:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103879:	ba 0a 00 00 00       	mov    $0xa,%edx
f010387e:	e9 ec 00 00 00       	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, int);
f0103883:	8b 45 14             	mov    0x14(%ebp),%eax
f0103886:	8b 00                	mov    (%eax),%eax
f0103888:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010388b:	99                   	cltd   
f010388c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010388f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103892:	8d 40 04             	lea    0x4(%eax),%eax
f0103895:	89 45 14             	mov    %eax,0x14(%ebp)
f0103898:	eb b4                	jmp    f010384e <.L29+0x3d>

f010389a <.L23>:
	if (lflag >= 2)
f010389a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010389d:	8b 75 08             	mov    0x8(%ebp),%esi
f01038a0:	83 f9 01             	cmp    $0x1,%ecx
f01038a3:	7f 1e                	jg     f01038c3 <.L23+0x29>
	else if (lflag)
f01038a5:	85 c9                	test   %ecx,%ecx
f01038a7:	74 32                	je     f01038db <.L23+0x41>
		return va_arg(*ap, unsigned long);
f01038a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ac:	8b 08                	mov    (%eax),%ecx
f01038ae:	bb 00 00 00 00       	mov    $0x0,%ebx
f01038b3:	8d 40 04             	lea    0x4(%eax),%eax
f01038b6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038b9:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long);
f01038be:	e9 ac 00 00 00       	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01038c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01038c6:	8b 08                	mov    (%eax),%ecx
f01038c8:	8b 58 04             	mov    0x4(%eax),%ebx
f01038cb:	8d 40 08             	lea    0x8(%eax),%eax
f01038ce:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038d1:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long long);
f01038d6:	e9 94 00 00 00       	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01038db:	8b 45 14             	mov    0x14(%ebp),%eax
f01038de:	8b 08                	mov    (%eax),%ecx
f01038e0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01038e5:	8d 40 04             	lea    0x4(%eax),%eax
f01038e8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01038eb:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned int);
f01038f0:	eb 7d                	jmp    f010396f <.L25+0x2b>

f01038f2 <.L26>:
	if (lflag >= 2)
f01038f2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01038f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01038f8:	83 f9 01             	cmp    $0x1,%ecx
f01038fb:	7f 1b                	jg     f0103918 <.L26+0x26>
	else if (lflag)
f01038fd:	85 c9                	test   %ecx,%ecx
f01038ff:	74 2c                	je     f010392d <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f0103901:	8b 45 14             	mov    0x14(%ebp),%eax
f0103904:	8b 08                	mov    (%eax),%ecx
f0103906:	bb 00 00 00 00       	mov    $0x0,%ebx
f010390b:	8d 40 04             	lea    0x4(%eax),%eax
f010390e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103911:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned long);
f0103916:	eb 57                	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0103918:	8b 45 14             	mov    0x14(%ebp),%eax
f010391b:	8b 08                	mov    (%eax),%ecx
f010391d:	8b 58 04             	mov    0x4(%eax),%ebx
f0103920:	8d 40 08             	lea    0x8(%eax),%eax
f0103923:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103926:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned long long);
f010392b:	eb 42                	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f010392d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103930:	8b 08                	mov    (%eax),%ecx
f0103932:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103937:	8d 40 04             	lea    0x4(%eax),%eax
f010393a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010393d:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned int);
f0103942:	eb 2b                	jmp    f010396f <.L25+0x2b>

f0103944 <.L25>:
			putch('0', putdat);
f0103944:	8b 75 08             	mov    0x8(%ebp),%esi
f0103947:	83 ec 08             	sub    $0x8,%esp
f010394a:	57                   	push   %edi
f010394b:	6a 30                	push   $0x30
f010394d:	ff d6                	call   *%esi
			putch('x', putdat);
f010394f:	83 c4 08             	add    $0x8,%esp
f0103952:	57                   	push   %edi
f0103953:	6a 78                	push   $0x78
f0103955:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103957:	8b 45 14             	mov    0x14(%ebp),%eax
f010395a:	8b 08                	mov    (%eax),%ecx
f010395c:	bb 00 00 00 00       	mov    $0x0,%ebx
			goto number;
f0103961:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103964:	8d 40 04             	lea    0x4(%eax),%eax
f0103967:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010396a:	ba 10 00 00 00       	mov    $0x10,%edx
			printnum(putch, putdat, num, base, width, padc);
f010396f:	83 ec 0c             	sub    $0xc,%esp
f0103972:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f0103976:	50                   	push   %eax
f0103977:	ff 75 d4             	push   -0x2c(%ebp)
f010397a:	52                   	push   %edx
f010397b:	53                   	push   %ebx
f010397c:	51                   	push   %ecx
f010397d:	89 fa                	mov    %edi,%edx
f010397f:	89 f0                	mov    %esi,%eax
f0103981:	e8 f4 fa ff ff       	call   f010347a <printnum>
			break;
f0103986:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103989:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010398c:	e9 15 fc ff ff       	jmp    f01035a6 <vprintfmt+0x34>

f0103991 <.L21>:
	if (lflag >= 2)
f0103991:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103994:	8b 75 08             	mov    0x8(%ebp),%esi
f0103997:	83 f9 01             	cmp    $0x1,%ecx
f010399a:	7f 1b                	jg     f01039b7 <.L21+0x26>
	else if (lflag)
f010399c:	85 c9                	test   %ecx,%ecx
f010399e:	74 2c                	je     f01039cc <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f01039a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01039a3:	8b 08                	mov    (%eax),%ecx
f01039a5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01039aa:	8d 40 04             	lea    0x4(%eax),%eax
f01039ad:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039b0:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long);
f01039b5:	eb b8                	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f01039b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ba:	8b 08                	mov    (%eax),%ecx
f01039bc:	8b 58 04             	mov    0x4(%eax),%ebx
f01039bf:	8d 40 08             	lea    0x8(%eax),%eax
f01039c2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039c5:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long long);
f01039ca:	eb a3                	jmp    f010396f <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f01039cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01039cf:	8b 08                	mov    (%eax),%ecx
f01039d1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01039d6:	8d 40 04             	lea    0x4(%eax),%eax
f01039d9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01039dc:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned int);
f01039e1:	eb 8c                	jmp    f010396f <.L25+0x2b>

f01039e3 <.L35>:
			putch(ch, putdat);
f01039e3:	8b 75 08             	mov    0x8(%ebp),%esi
f01039e6:	83 ec 08             	sub    $0x8,%esp
f01039e9:	57                   	push   %edi
f01039ea:	6a 25                	push   $0x25
f01039ec:	ff d6                	call   *%esi
			break;
f01039ee:	83 c4 10             	add    $0x10,%esp
f01039f1:	eb 96                	jmp    f0103989 <.L25+0x45>

f01039f3 <.L20>:
			putch('%', putdat);
f01039f3:	8b 75 08             	mov    0x8(%ebp),%esi
f01039f6:	83 ec 08             	sub    $0x8,%esp
f01039f9:	57                   	push   %edi
f01039fa:	6a 25                	push   $0x25
f01039fc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01039fe:	83 c4 10             	add    $0x10,%esp
f0103a01:	89 d8                	mov    %ebx,%eax
f0103a03:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103a07:	74 05                	je     f0103a0e <.L20+0x1b>
f0103a09:	83 e8 01             	sub    $0x1,%eax
f0103a0c:	eb f5                	jmp    f0103a03 <.L20+0x10>
f0103a0e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a11:	e9 73 ff ff ff       	jmp    f0103989 <.L25+0x45>

f0103a16 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103a16:	55                   	push   %ebp
f0103a17:	89 e5                	mov    %esp,%ebp
f0103a19:	53                   	push   %ebx
f0103a1a:	83 ec 14             	sub    $0x14,%esp
f0103a1d:	e8 2d c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a22:	81 c3 ea 38 01 00    	add    $0x138ea,%ebx
f0103a28:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a2b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103a2e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a31:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103a35:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103a38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a3f:	85 c0                	test   %eax,%eax
f0103a41:	74 2b                	je     f0103a6e <vsnprintf+0x58>
f0103a43:	85 d2                	test   %edx,%edx
f0103a45:	7e 27                	jle    f0103a6e <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103a47:	ff 75 14             	push   0x14(%ebp)
f0103a4a:	ff 75 10             	push   0x10(%ebp)
f0103a4d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a50:	50                   	push   %eax
f0103a51:	8d 83 2c c2 fe ff    	lea    -0x13dd4(%ebx),%eax
f0103a57:	50                   	push   %eax
f0103a58:	e8 15 fb ff ff       	call   f0103572 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a60:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a66:	83 c4 10             	add    $0x10,%esp
}
f0103a69:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a6c:	c9                   	leave  
f0103a6d:	c3                   	ret    
		return -E_INVAL;
f0103a6e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103a73:	eb f4                	jmp    f0103a69 <vsnprintf+0x53>

f0103a75 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a75:	55                   	push   %ebp
f0103a76:	89 e5                	mov    %esp,%ebp
f0103a78:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a7b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a7e:	50                   	push   %eax
f0103a7f:	ff 75 10             	push   0x10(%ebp)
f0103a82:	ff 75 0c             	push   0xc(%ebp)
f0103a85:	ff 75 08             	push   0x8(%ebp)
f0103a88:	e8 89 ff ff ff       	call   f0103a16 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a8d:	c9                   	leave  
f0103a8e:	c3                   	ret    

f0103a8f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a8f:	55                   	push   %ebp
f0103a90:	89 e5                	mov    %esp,%ebp
f0103a92:	57                   	push   %edi
f0103a93:	56                   	push   %esi
f0103a94:	53                   	push   %ebx
f0103a95:	83 ec 1c             	sub    $0x1c,%esp
f0103a98:	e8 b2 c6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103a9d:	81 c3 6f 38 01 00    	add    $0x1386f,%ebx
f0103aa3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103aa6:	85 c0                	test   %eax,%eax
f0103aa8:	74 13                	je     f0103abd <readline+0x2e>
		cprintf("%s", prompt);
f0103aaa:	83 ec 08             	sub    $0x8,%esp
f0103aad:	50                   	push   %eax
f0103aae:	8d 83 48 d3 fe ff    	lea    -0x12cb8(%ebx),%eax
f0103ab4:	50                   	push   %eax
f0103ab5:	e8 64 f6 ff ff       	call   f010311e <cprintf>
f0103aba:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103abd:	83 ec 0c             	sub    $0xc,%esp
f0103ac0:	6a 00                	push   $0x0
f0103ac2:	e8 14 cc ff ff       	call   f01006db <iscons>
f0103ac7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103aca:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103acd:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0103ad2:	8d 83 d4 1f 00 00    	lea    0x1fd4(%ebx),%eax
f0103ad8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103adb:	eb 45                	jmp    f0103b22 <readline+0x93>
			cprintf("read error: %e\n", c);
f0103add:	83 ec 08             	sub    $0x8,%esp
f0103ae0:	50                   	push   %eax
f0103ae1:	8d 83 00 e0 fe ff    	lea    -0x12000(%ebx),%eax
f0103ae7:	50                   	push   %eax
f0103ae8:	e8 31 f6 ff ff       	call   f010311e <cprintf>
			return NULL;
f0103aed:	83 c4 10             	add    $0x10,%esp
f0103af0:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103af5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103af8:	5b                   	pop    %ebx
f0103af9:	5e                   	pop    %esi
f0103afa:	5f                   	pop    %edi
f0103afb:	5d                   	pop    %ebp
f0103afc:	c3                   	ret    
			if (echoing)
f0103afd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b01:	75 05                	jne    f0103b08 <readline+0x79>
			i--;
f0103b03:	83 ef 01             	sub    $0x1,%edi
f0103b06:	eb 1a                	jmp    f0103b22 <readline+0x93>
				cputchar('\b');
f0103b08:	83 ec 0c             	sub    $0xc,%esp
f0103b0b:	6a 08                	push   $0x8
f0103b0d:	e8 a8 cb ff ff       	call   f01006ba <cputchar>
f0103b12:	83 c4 10             	add    $0x10,%esp
f0103b15:	eb ec                	jmp    f0103b03 <readline+0x74>
			buf[i++] = c;
f0103b17:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103b1a:	89 f0                	mov    %esi,%eax
f0103b1c:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0103b1f:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103b22:	e8 a3 cb ff ff       	call   f01006ca <getchar>
f0103b27:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103b29:	85 c0                	test   %eax,%eax
f0103b2b:	78 b0                	js     f0103add <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103b2d:	83 f8 08             	cmp    $0x8,%eax
f0103b30:	0f 94 c0             	sete   %al
f0103b33:	83 fe 7f             	cmp    $0x7f,%esi
f0103b36:	0f 94 c2             	sete   %dl
f0103b39:	08 d0                	or     %dl,%al
f0103b3b:	74 04                	je     f0103b41 <readline+0xb2>
f0103b3d:	85 ff                	test   %edi,%edi
f0103b3f:	7f bc                	jg     f0103afd <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103b41:	83 fe 1f             	cmp    $0x1f,%esi
f0103b44:	7e 1c                	jle    f0103b62 <readline+0xd3>
f0103b46:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103b4c:	7f 14                	jg     f0103b62 <readline+0xd3>
			if (echoing)
f0103b4e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b52:	74 c3                	je     f0103b17 <readline+0x88>
				cputchar(c);
f0103b54:	83 ec 0c             	sub    $0xc,%esp
f0103b57:	56                   	push   %esi
f0103b58:	e8 5d cb ff ff       	call   f01006ba <cputchar>
f0103b5d:	83 c4 10             	add    $0x10,%esp
f0103b60:	eb b5                	jmp    f0103b17 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f0103b62:	83 fe 0a             	cmp    $0xa,%esi
f0103b65:	74 05                	je     f0103b6c <readline+0xdd>
f0103b67:	83 fe 0d             	cmp    $0xd,%esi
f0103b6a:	75 b6                	jne    f0103b22 <readline+0x93>
			if (echoing)
f0103b6c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b70:	75 13                	jne    f0103b85 <readline+0xf6>
			buf[i] = 0;
f0103b72:	c6 84 3b d4 1f 00 00 	movb   $0x0,0x1fd4(%ebx,%edi,1)
f0103b79:	00 
			return buf;
f0103b7a:	8d 83 d4 1f 00 00    	lea    0x1fd4(%ebx),%eax
f0103b80:	e9 70 ff ff ff       	jmp    f0103af5 <readline+0x66>
				cputchar('\n');
f0103b85:	83 ec 0c             	sub    $0xc,%esp
f0103b88:	6a 0a                	push   $0xa
f0103b8a:	e8 2b cb ff ff       	call   f01006ba <cputchar>
f0103b8f:	83 c4 10             	add    $0x10,%esp
f0103b92:	eb de                	jmp    f0103b72 <readline+0xe3>

f0103b94 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b94:	55                   	push   %ebp
f0103b95:	89 e5                	mov    %esp,%ebp
f0103b97:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b9f:	eb 03                	jmp    f0103ba4 <strlen+0x10>
		n++;
f0103ba1:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103ba4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103ba8:	75 f7                	jne    f0103ba1 <strlen+0xd>
	return n;
}
f0103baa:	5d                   	pop    %ebp
f0103bab:	c3                   	ret    

f0103bac <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103bac:	55                   	push   %ebp
f0103bad:	89 e5                	mov    %esp,%ebp
f0103baf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bb2:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103bb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bba:	eb 03                	jmp    f0103bbf <strnlen+0x13>
		n++;
f0103bbc:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103bbf:	39 d0                	cmp    %edx,%eax
f0103bc1:	74 08                	je     f0103bcb <strnlen+0x1f>
f0103bc3:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103bc7:	75 f3                	jne    f0103bbc <strnlen+0x10>
f0103bc9:	89 c2                	mov    %eax,%edx
	return n;
}
f0103bcb:	89 d0                	mov    %edx,%eax
f0103bcd:	5d                   	pop    %ebp
f0103bce:	c3                   	ret    

f0103bcf <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103bcf:	55                   	push   %ebp
f0103bd0:	89 e5                	mov    %esp,%ebp
f0103bd2:	53                   	push   %ebx
f0103bd3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bd6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103bd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bde:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0103be2:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0103be5:	83 c0 01             	add    $0x1,%eax
f0103be8:	84 d2                	test   %dl,%dl
f0103bea:	75 f2                	jne    f0103bde <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103bec:	89 c8                	mov    %ecx,%eax
f0103bee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bf1:	c9                   	leave  
f0103bf2:	c3                   	ret    

f0103bf3 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103bf3:	55                   	push   %ebp
f0103bf4:	89 e5                	mov    %esp,%ebp
f0103bf6:	53                   	push   %ebx
f0103bf7:	83 ec 10             	sub    $0x10,%esp
f0103bfa:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103bfd:	53                   	push   %ebx
f0103bfe:	e8 91 ff ff ff       	call   f0103b94 <strlen>
f0103c03:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0103c06:	ff 75 0c             	push   0xc(%ebp)
f0103c09:	01 d8                	add    %ebx,%eax
f0103c0b:	50                   	push   %eax
f0103c0c:	e8 be ff ff ff       	call   f0103bcf <strcpy>
	return dst;
}
f0103c11:	89 d8                	mov    %ebx,%eax
f0103c13:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c16:	c9                   	leave  
f0103c17:	c3                   	ret    

f0103c18 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103c18:	55                   	push   %ebp
f0103c19:	89 e5                	mov    %esp,%ebp
f0103c1b:	56                   	push   %esi
f0103c1c:	53                   	push   %ebx
f0103c1d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c20:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c23:	89 f3                	mov    %esi,%ebx
f0103c25:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103c28:	89 f0                	mov    %esi,%eax
f0103c2a:	eb 0f                	jmp    f0103c3b <strncpy+0x23>
		*dst++ = *src;
f0103c2c:	83 c0 01             	add    $0x1,%eax
f0103c2f:	0f b6 0a             	movzbl (%edx),%ecx
f0103c32:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103c35:	80 f9 01             	cmp    $0x1,%cl
f0103c38:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f0103c3b:	39 d8                	cmp    %ebx,%eax
f0103c3d:	75 ed                	jne    f0103c2c <strncpy+0x14>
	}
	return ret;
}
f0103c3f:	89 f0                	mov    %esi,%eax
f0103c41:	5b                   	pop    %ebx
f0103c42:	5e                   	pop    %esi
f0103c43:	5d                   	pop    %ebp
f0103c44:	c3                   	ret    

f0103c45 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103c45:	55                   	push   %ebp
f0103c46:	89 e5                	mov    %esp,%ebp
f0103c48:	56                   	push   %esi
f0103c49:	53                   	push   %ebx
f0103c4a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c4d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c50:	8b 55 10             	mov    0x10(%ebp),%edx
f0103c53:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c55:	85 d2                	test   %edx,%edx
f0103c57:	74 21                	je     f0103c7a <strlcpy+0x35>
f0103c59:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103c5d:	89 f2                	mov    %esi,%edx
f0103c5f:	eb 09                	jmp    f0103c6a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103c61:	83 c1 01             	add    $0x1,%ecx
f0103c64:	83 c2 01             	add    $0x1,%edx
f0103c67:	88 5a ff             	mov    %bl,-0x1(%edx)
		while (--size > 0 && *src != '\0')
f0103c6a:	39 c2                	cmp    %eax,%edx
f0103c6c:	74 09                	je     f0103c77 <strlcpy+0x32>
f0103c6e:	0f b6 19             	movzbl (%ecx),%ebx
f0103c71:	84 db                	test   %bl,%bl
f0103c73:	75 ec                	jne    f0103c61 <strlcpy+0x1c>
f0103c75:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0103c77:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103c7a:	29 f0                	sub    %esi,%eax
}
f0103c7c:	5b                   	pop    %ebx
f0103c7d:	5e                   	pop    %esi
f0103c7e:	5d                   	pop    %ebp
f0103c7f:	c3                   	ret    

f0103c80 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c80:	55                   	push   %ebp
f0103c81:	89 e5                	mov    %esp,%ebp
f0103c83:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c86:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c89:	eb 06                	jmp    f0103c91 <strcmp+0x11>
		p++, q++;
f0103c8b:	83 c1 01             	add    $0x1,%ecx
f0103c8e:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103c91:	0f b6 01             	movzbl (%ecx),%eax
f0103c94:	84 c0                	test   %al,%al
f0103c96:	74 04                	je     f0103c9c <strcmp+0x1c>
f0103c98:	3a 02                	cmp    (%edx),%al
f0103c9a:	74 ef                	je     f0103c8b <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c9c:	0f b6 c0             	movzbl %al,%eax
f0103c9f:	0f b6 12             	movzbl (%edx),%edx
f0103ca2:	29 d0                	sub    %edx,%eax
}
f0103ca4:	5d                   	pop    %ebp
f0103ca5:	c3                   	ret    

f0103ca6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103ca6:	55                   	push   %ebp
f0103ca7:	89 e5                	mov    %esp,%ebp
f0103ca9:	53                   	push   %ebx
f0103caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cad:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cb0:	89 c3                	mov    %eax,%ebx
f0103cb2:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103cb5:	eb 06                	jmp    f0103cbd <strncmp+0x17>
		n--, p++, q++;
f0103cb7:	83 c0 01             	add    $0x1,%eax
f0103cba:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103cbd:	39 d8                	cmp    %ebx,%eax
f0103cbf:	74 18                	je     f0103cd9 <strncmp+0x33>
f0103cc1:	0f b6 08             	movzbl (%eax),%ecx
f0103cc4:	84 c9                	test   %cl,%cl
f0103cc6:	74 04                	je     f0103ccc <strncmp+0x26>
f0103cc8:	3a 0a                	cmp    (%edx),%cl
f0103cca:	74 eb                	je     f0103cb7 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ccc:	0f b6 00             	movzbl (%eax),%eax
f0103ccf:	0f b6 12             	movzbl (%edx),%edx
f0103cd2:	29 d0                	sub    %edx,%eax
}
f0103cd4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103cd7:	c9                   	leave  
f0103cd8:	c3                   	ret    
		return 0;
f0103cd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cde:	eb f4                	jmp    f0103cd4 <strncmp+0x2e>

f0103ce0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103ce0:	55                   	push   %ebp
f0103ce1:	89 e5                	mov    %esp,%ebp
f0103ce3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ce6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103cea:	eb 03                	jmp    f0103cef <strchr+0xf>
f0103cec:	83 c0 01             	add    $0x1,%eax
f0103cef:	0f b6 10             	movzbl (%eax),%edx
f0103cf2:	84 d2                	test   %dl,%dl
f0103cf4:	74 06                	je     f0103cfc <strchr+0x1c>
		if (*s == c)
f0103cf6:	38 ca                	cmp    %cl,%dl
f0103cf8:	75 f2                	jne    f0103cec <strchr+0xc>
f0103cfa:	eb 05                	jmp    f0103d01 <strchr+0x21>
			return (char *) s;
	return 0;
f0103cfc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d01:	5d                   	pop    %ebp
f0103d02:	c3                   	ret    

f0103d03 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103d03:	55                   	push   %ebp
f0103d04:	89 e5                	mov    %esp,%ebp
f0103d06:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d09:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103d0d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103d10:	38 ca                	cmp    %cl,%dl
f0103d12:	74 09                	je     f0103d1d <strfind+0x1a>
f0103d14:	84 d2                	test   %dl,%dl
f0103d16:	74 05                	je     f0103d1d <strfind+0x1a>
	for (; *s; s++)
f0103d18:	83 c0 01             	add    $0x1,%eax
f0103d1b:	eb f0                	jmp    f0103d0d <strfind+0xa>
			break;
	return (char *) s;
}
f0103d1d:	5d                   	pop    %ebp
f0103d1e:	c3                   	ret    

f0103d1f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103d1f:	55                   	push   %ebp
f0103d20:	89 e5                	mov    %esp,%ebp
f0103d22:	57                   	push   %edi
f0103d23:	56                   	push   %esi
f0103d24:	53                   	push   %ebx
f0103d25:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103d28:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103d2b:	85 c9                	test   %ecx,%ecx
f0103d2d:	74 2f                	je     f0103d5e <memset+0x3f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103d2f:	89 f8                	mov    %edi,%eax
f0103d31:	09 c8                	or     %ecx,%eax
f0103d33:	a8 03                	test   $0x3,%al
f0103d35:	75 21                	jne    f0103d58 <memset+0x39>
		c &= 0xFF;
f0103d37:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103d3b:	89 d0                	mov    %edx,%eax
f0103d3d:	c1 e0 08             	shl    $0x8,%eax
f0103d40:	89 d3                	mov    %edx,%ebx
f0103d42:	c1 e3 18             	shl    $0x18,%ebx
f0103d45:	89 d6                	mov    %edx,%esi
f0103d47:	c1 e6 10             	shl    $0x10,%esi
f0103d4a:	09 f3                	or     %esi,%ebx
f0103d4c:	09 da                	or     %ebx,%edx
f0103d4e:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103d50:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103d53:	fc                   	cld    
f0103d54:	f3 ab                	rep stos %eax,%es:(%edi)
f0103d56:	eb 06                	jmp    f0103d5e <memset+0x3f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103d58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d5b:	fc                   	cld    
f0103d5c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103d5e:	89 f8                	mov    %edi,%eax
f0103d60:	5b                   	pop    %ebx
f0103d61:	5e                   	pop    %esi
f0103d62:	5f                   	pop    %edi
f0103d63:	5d                   	pop    %ebp
f0103d64:	c3                   	ret    

f0103d65 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103d65:	55                   	push   %ebp
f0103d66:	89 e5                	mov    %esp,%ebp
f0103d68:	57                   	push   %edi
f0103d69:	56                   	push   %esi
f0103d6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d6d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d70:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103d73:	39 c6                	cmp    %eax,%esi
f0103d75:	73 32                	jae    f0103da9 <memmove+0x44>
f0103d77:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d7a:	39 c2                	cmp    %eax,%edx
f0103d7c:	76 2b                	jbe    f0103da9 <memmove+0x44>
		s += n;
		d += n;
f0103d7e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d81:	89 d6                	mov    %edx,%esi
f0103d83:	09 fe                	or     %edi,%esi
f0103d85:	09 ce                	or     %ecx,%esi
f0103d87:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d8d:	75 0e                	jne    f0103d9d <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103d8f:	83 ef 04             	sub    $0x4,%edi
f0103d92:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d95:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103d98:	fd                   	std    
f0103d99:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d9b:	eb 09                	jmp    f0103da6 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103d9d:	83 ef 01             	sub    $0x1,%edi
f0103da0:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103da3:	fd                   	std    
f0103da4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103da6:	fc                   	cld    
f0103da7:	eb 1a                	jmp    f0103dc3 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103da9:	89 f2                	mov    %esi,%edx
f0103dab:	09 c2                	or     %eax,%edx
f0103dad:	09 ca                	or     %ecx,%edx
f0103daf:	f6 c2 03             	test   $0x3,%dl
f0103db2:	75 0a                	jne    f0103dbe <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103db4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103db7:	89 c7                	mov    %eax,%edi
f0103db9:	fc                   	cld    
f0103dba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103dbc:	eb 05                	jmp    f0103dc3 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f0103dbe:	89 c7                	mov    %eax,%edi
f0103dc0:	fc                   	cld    
f0103dc1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103dc3:	5e                   	pop    %esi
f0103dc4:	5f                   	pop    %edi
f0103dc5:	5d                   	pop    %ebp
f0103dc6:	c3                   	ret    

f0103dc7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103dc7:	55                   	push   %ebp
f0103dc8:	89 e5                	mov    %esp,%ebp
f0103dca:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103dcd:	ff 75 10             	push   0x10(%ebp)
f0103dd0:	ff 75 0c             	push   0xc(%ebp)
f0103dd3:	ff 75 08             	push   0x8(%ebp)
f0103dd6:	e8 8a ff ff ff       	call   f0103d65 <memmove>
}
f0103ddb:	c9                   	leave  
f0103ddc:	c3                   	ret    

f0103ddd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103ddd:	55                   	push   %ebp
f0103dde:	89 e5                	mov    %esp,%ebp
f0103de0:	56                   	push   %esi
f0103de1:	53                   	push   %ebx
f0103de2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103de5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103de8:	89 c6                	mov    %eax,%esi
f0103dea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ded:	eb 06                	jmp    f0103df5 <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103def:	83 c0 01             	add    $0x1,%eax
f0103df2:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f0103df5:	39 f0                	cmp    %esi,%eax
f0103df7:	74 14                	je     f0103e0d <memcmp+0x30>
		if (*s1 != *s2)
f0103df9:	0f b6 08             	movzbl (%eax),%ecx
f0103dfc:	0f b6 1a             	movzbl (%edx),%ebx
f0103dff:	38 d9                	cmp    %bl,%cl
f0103e01:	74 ec                	je     f0103def <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0103e03:	0f b6 c1             	movzbl %cl,%eax
f0103e06:	0f b6 db             	movzbl %bl,%ebx
f0103e09:	29 d8                	sub    %ebx,%eax
f0103e0b:	eb 05                	jmp    f0103e12 <memcmp+0x35>
	}

	return 0;
f0103e0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e12:	5b                   	pop    %ebx
f0103e13:	5e                   	pop    %esi
f0103e14:	5d                   	pop    %ebp
f0103e15:	c3                   	ret    

f0103e16 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103e16:	55                   	push   %ebp
f0103e17:	89 e5                	mov    %esp,%ebp
f0103e19:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e1c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103e1f:	89 c2                	mov    %eax,%edx
f0103e21:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103e24:	eb 03                	jmp    f0103e29 <memfind+0x13>
f0103e26:	83 c0 01             	add    $0x1,%eax
f0103e29:	39 d0                	cmp    %edx,%eax
f0103e2b:	73 04                	jae    f0103e31 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103e2d:	38 08                	cmp    %cl,(%eax)
f0103e2f:	75 f5                	jne    f0103e26 <memfind+0x10>
			break;
	return (void *) s;
}
f0103e31:	5d                   	pop    %ebp
f0103e32:	c3                   	ret    

f0103e33 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103e33:	55                   	push   %ebp
f0103e34:	89 e5                	mov    %esp,%ebp
f0103e36:	57                   	push   %edi
f0103e37:	56                   	push   %esi
f0103e38:	53                   	push   %ebx
f0103e39:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e3c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e3f:	eb 03                	jmp    f0103e44 <strtol+0x11>
		s++;
f0103e41:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103e44:	0f b6 02             	movzbl (%edx),%eax
f0103e47:	3c 20                	cmp    $0x20,%al
f0103e49:	74 f6                	je     f0103e41 <strtol+0xe>
f0103e4b:	3c 09                	cmp    $0x9,%al
f0103e4d:	74 f2                	je     f0103e41 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103e4f:	3c 2b                	cmp    $0x2b,%al
f0103e51:	74 2a                	je     f0103e7d <strtol+0x4a>
	int neg = 0;
f0103e53:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103e58:	3c 2d                	cmp    $0x2d,%al
f0103e5a:	74 2b                	je     f0103e87 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e5c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103e62:	75 0f                	jne    f0103e73 <strtol+0x40>
f0103e64:	80 3a 30             	cmpb   $0x30,(%edx)
f0103e67:	74 28                	je     f0103e91 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e69:	85 db                	test   %ebx,%ebx
f0103e6b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e70:	0f 44 d8             	cmove  %eax,%ebx
f0103e73:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e78:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103e7b:	eb 46                	jmp    f0103ec3 <strtol+0x90>
		s++;
f0103e7d:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103e80:	bf 00 00 00 00       	mov    $0x0,%edi
f0103e85:	eb d5                	jmp    f0103e5c <strtol+0x29>
		s++, neg = 1;
f0103e87:	83 c2 01             	add    $0x1,%edx
f0103e8a:	bf 01 00 00 00       	mov    $0x1,%edi
f0103e8f:	eb cb                	jmp    f0103e5c <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e91:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103e95:	74 0e                	je     f0103ea5 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f0103e97:	85 db                	test   %ebx,%ebx
f0103e99:	75 d8                	jne    f0103e73 <strtol+0x40>
		s++, base = 8;
f0103e9b:	83 c2 01             	add    $0x1,%edx
f0103e9e:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103ea3:	eb ce                	jmp    f0103e73 <strtol+0x40>
		s += 2, base = 16;
f0103ea5:	83 c2 02             	add    $0x2,%edx
f0103ea8:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103ead:	eb c4                	jmp    f0103e73 <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0103eaf:	0f be c0             	movsbl %al,%eax
f0103eb2:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103eb5:	3b 45 10             	cmp    0x10(%ebp),%eax
f0103eb8:	7d 3a                	jge    f0103ef4 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103eba:	83 c2 01             	add    $0x1,%edx
f0103ebd:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f0103ec1:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f0103ec3:	0f b6 02             	movzbl (%edx),%eax
f0103ec6:	8d 70 d0             	lea    -0x30(%eax),%esi
f0103ec9:	89 f3                	mov    %esi,%ebx
f0103ecb:	80 fb 09             	cmp    $0x9,%bl
f0103ece:	76 df                	jbe    f0103eaf <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f0103ed0:	8d 70 9f             	lea    -0x61(%eax),%esi
f0103ed3:	89 f3                	mov    %esi,%ebx
f0103ed5:	80 fb 19             	cmp    $0x19,%bl
f0103ed8:	77 08                	ja     f0103ee2 <strtol+0xaf>
			dig = *s - 'a' + 10;
f0103eda:	0f be c0             	movsbl %al,%eax
f0103edd:	83 e8 57             	sub    $0x57,%eax
f0103ee0:	eb d3                	jmp    f0103eb5 <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f0103ee2:	8d 70 bf             	lea    -0x41(%eax),%esi
f0103ee5:	89 f3                	mov    %esi,%ebx
f0103ee7:	80 fb 19             	cmp    $0x19,%bl
f0103eea:	77 08                	ja     f0103ef4 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0103eec:	0f be c0             	movsbl %al,%eax
f0103eef:	83 e8 37             	sub    $0x37,%eax
f0103ef2:	eb c1                	jmp    f0103eb5 <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103ef4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ef8:	74 05                	je     f0103eff <strtol+0xcc>
		*endptr = (char *) s;
f0103efa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103efd:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0103eff:	89 c8                	mov    %ecx,%eax
f0103f01:	f7 d8                	neg    %eax
f0103f03:	85 ff                	test   %edi,%edi
f0103f05:	0f 45 c8             	cmovne %eax,%ecx
}
f0103f08:	89 c8                	mov    %ecx,%eax
f0103f0a:	5b                   	pop    %ebx
f0103f0b:	5e                   	pop    %esi
f0103f0c:	5f                   	pop    %edi
f0103f0d:	5d                   	pop    %ebp
f0103f0e:	c3                   	ret    
f0103f0f:	90                   	nop

f0103f10 <__udivdi3>:
f0103f10:	f3 0f 1e fb          	endbr32 
f0103f14:	55                   	push   %ebp
f0103f15:	57                   	push   %edi
f0103f16:	56                   	push   %esi
f0103f17:	53                   	push   %ebx
f0103f18:	83 ec 1c             	sub    $0x1c,%esp
f0103f1b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103f1f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103f23:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f27:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103f2b:	85 c0                	test   %eax,%eax
f0103f2d:	75 19                	jne    f0103f48 <__udivdi3+0x38>
f0103f2f:	39 f3                	cmp    %esi,%ebx
f0103f31:	76 4d                	jbe    f0103f80 <__udivdi3+0x70>
f0103f33:	31 ff                	xor    %edi,%edi
f0103f35:	89 e8                	mov    %ebp,%eax
f0103f37:	89 f2                	mov    %esi,%edx
f0103f39:	f7 f3                	div    %ebx
f0103f3b:	89 fa                	mov    %edi,%edx
f0103f3d:	83 c4 1c             	add    $0x1c,%esp
f0103f40:	5b                   	pop    %ebx
f0103f41:	5e                   	pop    %esi
f0103f42:	5f                   	pop    %edi
f0103f43:	5d                   	pop    %ebp
f0103f44:	c3                   	ret    
f0103f45:	8d 76 00             	lea    0x0(%esi),%esi
f0103f48:	39 f0                	cmp    %esi,%eax
f0103f4a:	76 14                	jbe    f0103f60 <__udivdi3+0x50>
f0103f4c:	31 ff                	xor    %edi,%edi
f0103f4e:	31 c0                	xor    %eax,%eax
f0103f50:	89 fa                	mov    %edi,%edx
f0103f52:	83 c4 1c             	add    $0x1c,%esp
f0103f55:	5b                   	pop    %ebx
f0103f56:	5e                   	pop    %esi
f0103f57:	5f                   	pop    %edi
f0103f58:	5d                   	pop    %ebp
f0103f59:	c3                   	ret    
f0103f5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f60:	0f bd f8             	bsr    %eax,%edi
f0103f63:	83 f7 1f             	xor    $0x1f,%edi
f0103f66:	75 48                	jne    f0103fb0 <__udivdi3+0xa0>
f0103f68:	39 f0                	cmp    %esi,%eax
f0103f6a:	72 06                	jb     f0103f72 <__udivdi3+0x62>
f0103f6c:	31 c0                	xor    %eax,%eax
f0103f6e:	39 eb                	cmp    %ebp,%ebx
f0103f70:	77 de                	ja     f0103f50 <__udivdi3+0x40>
f0103f72:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f77:	eb d7                	jmp    f0103f50 <__udivdi3+0x40>
f0103f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f80:	89 d9                	mov    %ebx,%ecx
f0103f82:	85 db                	test   %ebx,%ebx
f0103f84:	75 0b                	jne    f0103f91 <__udivdi3+0x81>
f0103f86:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f8b:	31 d2                	xor    %edx,%edx
f0103f8d:	f7 f3                	div    %ebx
f0103f8f:	89 c1                	mov    %eax,%ecx
f0103f91:	31 d2                	xor    %edx,%edx
f0103f93:	89 f0                	mov    %esi,%eax
f0103f95:	f7 f1                	div    %ecx
f0103f97:	89 c6                	mov    %eax,%esi
f0103f99:	89 e8                	mov    %ebp,%eax
f0103f9b:	89 f7                	mov    %esi,%edi
f0103f9d:	f7 f1                	div    %ecx
f0103f9f:	89 fa                	mov    %edi,%edx
f0103fa1:	83 c4 1c             	add    $0x1c,%esp
f0103fa4:	5b                   	pop    %ebx
f0103fa5:	5e                   	pop    %esi
f0103fa6:	5f                   	pop    %edi
f0103fa7:	5d                   	pop    %ebp
f0103fa8:	c3                   	ret    
f0103fa9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fb0:	89 f9                	mov    %edi,%ecx
f0103fb2:	ba 20 00 00 00       	mov    $0x20,%edx
f0103fb7:	29 fa                	sub    %edi,%edx
f0103fb9:	d3 e0                	shl    %cl,%eax
f0103fbb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fbf:	89 d1                	mov    %edx,%ecx
f0103fc1:	89 d8                	mov    %ebx,%eax
f0103fc3:	d3 e8                	shr    %cl,%eax
f0103fc5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103fc9:	09 c1                	or     %eax,%ecx
f0103fcb:	89 f0                	mov    %esi,%eax
f0103fcd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fd1:	89 f9                	mov    %edi,%ecx
f0103fd3:	d3 e3                	shl    %cl,%ebx
f0103fd5:	89 d1                	mov    %edx,%ecx
f0103fd7:	d3 e8                	shr    %cl,%eax
f0103fd9:	89 f9                	mov    %edi,%ecx
f0103fdb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103fdf:	89 eb                	mov    %ebp,%ebx
f0103fe1:	d3 e6                	shl    %cl,%esi
f0103fe3:	89 d1                	mov    %edx,%ecx
f0103fe5:	d3 eb                	shr    %cl,%ebx
f0103fe7:	09 f3                	or     %esi,%ebx
f0103fe9:	89 c6                	mov    %eax,%esi
f0103feb:	89 f2                	mov    %esi,%edx
f0103fed:	89 d8                	mov    %ebx,%eax
f0103fef:	f7 74 24 08          	divl   0x8(%esp)
f0103ff3:	89 d6                	mov    %edx,%esi
f0103ff5:	89 c3                	mov    %eax,%ebx
f0103ff7:	f7 64 24 0c          	mull   0xc(%esp)
f0103ffb:	39 d6                	cmp    %edx,%esi
f0103ffd:	72 19                	jb     f0104018 <__udivdi3+0x108>
f0103fff:	89 f9                	mov    %edi,%ecx
f0104001:	d3 e5                	shl    %cl,%ebp
f0104003:	39 c5                	cmp    %eax,%ebp
f0104005:	73 04                	jae    f010400b <__udivdi3+0xfb>
f0104007:	39 d6                	cmp    %edx,%esi
f0104009:	74 0d                	je     f0104018 <__udivdi3+0x108>
f010400b:	89 d8                	mov    %ebx,%eax
f010400d:	31 ff                	xor    %edi,%edi
f010400f:	e9 3c ff ff ff       	jmp    f0103f50 <__udivdi3+0x40>
f0104014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104018:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010401b:	31 ff                	xor    %edi,%edi
f010401d:	e9 2e ff ff ff       	jmp    f0103f50 <__udivdi3+0x40>
f0104022:	66 90                	xchg   %ax,%ax
f0104024:	66 90                	xchg   %ax,%ax
f0104026:	66 90                	xchg   %ax,%ax
f0104028:	66 90                	xchg   %ax,%ax
f010402a:	66 90                	xchg   %ax,%ax
f010402c:	66 90                	xchg   %ax,%ax
f010402e:	66 90                	xchg   %ax,%ax

f0104030 <__umoddi3>:
f0104030:	f3 0f 1e fb          	endbr32 
f0104034:	55                   	push   %ebp
f0104035:	57                   	push   %edi
f0104036:	56                   	push   %esi
f0104037:	53                   	push   %ebx
f0104038:	83 ec 1c             	sub    $0x1c,%esp
f010403b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010403f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104043:	8b 7c 24 3c          	mov    0x3c(%esp),%edi
f0104047:	8b 6c 24 38          	mov    0x38(%esp),%ebp
f010404b:	89 f0                	mov    %esi,%eax
f010404d:	89 da                	mov    %ebx,%edx
f010404f:	85 ff                	test   %edi,%edi
f0104051:	75 15                	jne    f0104068 <__umoddi3+0x38>
f0104053:	39 dd                	cmp    %ebx,%ebp
f0104055:	76 39                	jbe    f0104090 <__umoddi3+0x60>
f0104057:	f7 f5                	div    %ebp
f0104059:	89 d0                	mov    %edx,%eax
f010405b:	31 d2                	xor    %edx,%edx
f010405d:	83 c4 1c             	add    $0x1c,%esp
f0104060:	5b                   	pop    %ebx
f0104061:	5e                   	pop    %esi
f0104062:	5f                   	pop    %edi
f0104063:	5d                   	pop    %ebp
f0104064:	c3                   	ret    
f0104065:	8d 76 00             	lea    0x0(%esi),%esi
f0104068:	39 df                	cmp    %ebx,%edi
f010406a:	77 f1                	ja     f010405d <__umoddi3+0x2d>
f010406c:	0f bd cf             	bsr    %edi,%ecx
f010406f:	83 f1 1f             	xor    $0x1f,%ecx
f0104072:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104076:	75 40                	jne    f01040b8 <__umoddi3+0x88>
f0104078:	39 df                	cmp    %ebx,%edi
f010407a:	72 04                	jb     f0104080 <__umoddi3+0x50>
f010407c:	39 f5                	cmp    %esi,%ebp
f010407e:	77 dd                	ja     f010405d <__umoddi3+0x2d>
f0104080:	89 da                	mov    %ebx,%edx
f0104082:	89 f0                	mov    %esi,%eax
f0104084:	29 e8                	sub    %ebp,%eax
f0104086:	19 fa                	sbb    %edi,%edx
f0104088:	eb d3                	jmp    f010405d <__umoddi3+0x2d>
f010408a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104090:	89 e9                	mov    %ebp,%ecx
f0104092:	85 ed                	test   %ebp,%ebp
f0104094:	75 0b                	jne    f01040a1 <__umoddi3+0x71>
f0104096:	b8 01 00 00 00       	mov    $0x1,%eax
f010409b:	31 d2                	xor    %edx,%edx
f010409d:	f7 f5                	div    %ebp
f010409f:	89 c1                	mov    %eax,%ecx
f01040a1:	89 d8                	mov    %ebx,%eax
f01040a3:	31 d2                	xor    %edx,%edx
f01040a5:	f7 f1                	div    %ecx
f01040a7:	89 f0                	mov    %esi,%eax
f01040a9:	f7 f1                	div    %ecx
f01040ab:	89 d0                	mov    %edx,%eax
f01040ad:	31 d2                	xor    %edx,%edx
f01040af:	eb ac                	jmp    f010405d <__umoddi3+0x2d>
f01040b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040b8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040bc:	ba 20 00 00 00       	mov    $0x20,%edx
f01040c1:	29 c2                	sub    %eax,%edx
f01040c3:	89 c1                	mov    %eax,%ecx
f01040c5:	89 e8                	mov    %ebp,%eax
f01040c7:	d3 e7                	shl    %cl,%edi
f01040c9:	89 d1                	mov    %edx,%ecx
f01040cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01040cf:	d3 e8                	shr    %cl,%eax
f01040d1:	89 c1                	mov    %eax,%ecx
f01040d3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01040d7:	09 f9                	or     %edi,%ecx
f01040d9:	89 df                	mov    %ebx,%edi
f01040db:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01040df:	89 c1                	mov    %eax,%ecx
f01040e1:	d3 e5                	shl    %cl,%ebp
f01040e3:	89 d1                	mov    %edx,%ecx
f01040e5:	d3 ef                	shr    %cl,%edi
f01040e7:	89 c1                	mov    %eax,%ecx
f01040e9:	89 f0                	mov    %esi,%eax
f01040eb:	d3 e3                	shl    %cl,%ebx
f01040ed:	89 d1                	mov    %edx,%ecx
f01040ef:	89 fa                	mov    %edi,%edx
f01040f1:	d3 e8                	shr    %cl,%eax
f01040f3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01040f8:	09 d8                	or     %ebx,%eax
f01040fa:	f7 74 24 08          	divl   0x8(%esp)
f01040fe:	89 d3                	mov    %edx,%ebx
f0104100:	d3 e6                	shl    %cl,%esi
f0104102:	f7 e5                	mul    %ebp
f0104104:	89 c7                	mov    %eax,%edi
f0104106:	89 d1                	mov    %edx,%ecx
f0104108:	39 d3                	cmp    %edx,%ebx
f010410a:	72 06                	jb     f0104112 <__umoddi3+0xe2>
f010410c:	75 0e                	jne    f010411c <__umoddi3+0xec>
f010410e:	39 c6                	cmp    %eax,%esi
f0104110:	73 0a                	jae    f010411c <__umoddi3+0xec>
f0104112:	29 e8                	sub    %ebp,%eax
f0104114:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0104118:	89 d1                	mov    %edx,%ecx
f010411a:	89 c7                	mov    %eax,%edi
f010411c:	89 f5                	mov    %esi,%ebp
f010411e:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104122:	29 fd                	sub    %edi,%ebp
f0104124:	19 cb                	sbb    %ecx,%ebx
f0104126:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f010412b:	89 d8                	mov    %ebx,%eax
f010412d:	d3 e0                	shl    %cl,%eax
f010412f:	89 f1                	mov    %esi,%ecx
f0104131:	d3 ed                	shr    %cl,%ebp
f0104133:	d3 eb                	shr    %cl,%ebx
f0104135:	09 e8                	or     %ebp,%eax
f0104137:	89 da                	mov    %ebx,%edx
f0104139:	83 c4 1c             	add    $0x1c,%esp
f010413c:	5b                   	pop    %ebx
f010413d:	5e                   	pop    %esi
f010413e:	5f                   	pop    %edi
f010413f:	5d                   	pop    %ebp
f0104140:	c3                   	ret    
