
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00097517          	auipc	a0,0x97
ffffffffc020004e:	0fe50513          	addi	a0,a0,254 # ffffffffc0297148 <buf>
ffffffffc0200052:	0009b617          	auipc	a2,0x9b
ffffffffc0200056:	59e60613          	addi	a2,a2,1438 # ffffffffc029b5f0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7a8050ef          	jal	ffffffffc020580a <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7ca58593          	addi	a1,a1,1994 # ffffffffc0205838 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7e250513          	addi	a0,a0,2018 # ffffffffc0205858 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6e0020ef          	jal	ffffffffc0202766 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	213030ef          	jal	ffffffffc0203aa4 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6bf040ef          	jal	ffffffffc0204f54 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	052050ef          	jal	ffffffffc02050f4 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00005517          	auipc	a0,0x5
ffffffffc02000ba:	7aa50513          	addi	a0,a0,1962 # ffffffffc0205860 <etext+0x2c>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00097997          	auipc	s3,0x97
ffffffffc02000ca:	08298993          	addi	s3,s3,130 # ffffffffc0297148 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00097517          	auipc	a0,0x97
ffffffffc0200144:	00850513          	addi	a0,a0,8 # ffffffffc0297148 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	268050ef          	jal	ffffffffc02053f0 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	234050ef          	jal	ffffffffc02053f0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00005517          	auipc	a0,0x5
ffffffffc020022c:	64050513          	addi	a0,a0,1600 # ffffffffc0205868 <etext+0x34>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	64a50513          	addi	a0,a0,1610 # ffffffffc0205888 <etext+0x54>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	5ea58593          	addi	a1,a1,1514 # ffffffffc0205834 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	65650513          	addi	a0,a0,1622 # ffffffffc02058a8 <etext+0x74>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	eea58593          	addi	a1,a1,-278 # ffffffffc0297148 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	66250513          	addi	a0,a0,1634 # ffffffffc02058c8 <etext+0x94>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	37e58593          	addi	a1,a1,894 # ffffffffc029b5f0 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	66e50513          	addi	a0,a0,1646 # ffffffffc02058e8 <etext+0xb4>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	0009b797          	auipc	a5,0x9b
ffffffffc0200292:	76178793          	addi	a5,a5,1889 # ffffffffc029b9ef <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	66250513          	addi	a0,a0,1634 # ffffffffc0205908 <etext+0xd4>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	68460613          	addi	a2,a2,1668 # ffffffffc0205938 <etext+0x104>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	69050513          	addi	a0,a0,1680 # ffffffffc0205950 <etext+0x11c>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	29a40413          	addi	s0,s0,666 # ffffffffc0207570 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	2da48493          	addi	s1,s1,730 # ffffffffc02075b8 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	67e50513          	addi	a0,a0,1662 # ffffffffc0205968 <etext+0x134>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00005517          	auipc	a0,0x5
ffffffffc0200332:	64a50513          	addi	a0,a0,1610 # ffffffffc0205978 <etext+0x144>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00005517          	auipc	a0,0x5
ffffffffc020034a:	65a50513          	addi	a0,a0,1626 # ffffffffc02059a0 <etext+0x16c>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	214a8a93          	addi	s5,s5,532 # ffffffffc0207570 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	66250513          	addi	a0,a0,1634 # ffffffffc02059c8 <etext+0x194>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	1ec48493          	addi	s1,s1,492 # ffffffffc0207570 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	40a050ef          	jal	ffffffffc020579c <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	65450513          	addi	a0,a0,1620 # ffffffffc02059f8 <etext+0x1c4>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	61e50513          	addi	a0,a0,1566 # ffffffffc02059d0 <etext+0x19c>
ffffffffc02003ba:	43e050ef          	jal	ffffffffc02057f8 <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00005517          	auipc	a0,0x5
ffffffffc02003f8:	5dc50513          	addi	a0,a0,1500 # ffffffffc02059d0 <etext+0x19c>
ffffffffc02003fc:	3fc050ef          	jal	ffffffffc02057f8 <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	5cc50513          	addi	a0,a0,1484 # ffffffffc02059d8 <etext+0x1a4>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	0009b317          	auipc	t1,0x9b
ffffffffc020044a:	12a33303          	ld	t1,298(t1) # ffffffffc029b570 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00005517          	auipc	a0,0x5
ffffffffc0200470:	63450513          	addi	a0,a0,1588 # ffffffffc0205aa0 <etext+0x26c>
    is_panic = 1;
ffffffffc0200474:	0009b697          	auipc	a3,0x9b
ffffffffc0200478:	0ee6be23          	sd	a4,252(a3) # ffffffffc029b570 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00005517          	auipc	a0,0x5
ffffffffc020048e:	63650513          	addi	a0,a0,1590 # ffffffffc0205ac0 <etext+0x28c>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00005517          	auipc	a0,0x5
ffffffffc02004c2:	60a50513          	addi	a0,a0,1546 # ffffffffc0205ac8 <etext+0x294>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00005517          	auipc	a0,0x5
ffffffffc02004e4:	5e050513          	addi	a0,a0,1504 # ffffffffc0205ac0 <etext+0x28c>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xe4e8>
ffffffffc02004fa:	0009b717          	auipc	a4,0x9b
ffffffffc02004fe:	06f73f23          	sd	a5,126(a4) # ffffffffc029b578 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00005517          	auipc	a0,0x5
ffffffffc020051e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0205ae8 <etext+0x2b4>
    ticks = 0;
ffffffffc0200522:	0009b797          	auipc	a5,0x9b
ffffffffc0200526:	0407bf23          	sd	zero,94(a5) # ffffffffc029b580 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	0009b797          	auipc	a5,0x9b
ffffffffc0200534:	0487b783          	ld	a5,72(a5) # ffffffffc029b578 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	54e50513          	addi	a0,a0,1358 # ffffffffc0205b08 <etext+0x2d4>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	54650513          	addi	a0,a0,1350 # ffffffffc0205b18 <etext+0x2e4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	54050513          	addi	a0,a0,1344 # ffffffffc0205b28 <etext+0x2f4>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	54a50513          	addi	a0,a0,1354 # ffffffffc0205b40 <etext+0x30c>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe448fd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	52050513          	addi	a0,a0,1312 # ffffffffc0205c08 <etext+0x3d4>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	54850513          	addi	a0,a0,1352 # ffffffffc0205c40 <etext+0x40c>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	45450513          	addi	a0,a0,1108 # ffffffffc0205b60 <etext+0x32c>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	004050ef          	jal	ffffffffc0205756 <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	42c58593          	addi	a1,a1,1068 # ffffffffc0205b88 <etext+0x354>
ffffffffc0200764:	06c050ef          	jal	ffffffffc02057d0 <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	40858593          	addi	a1,a1,1032 # ffffffffc0205b90 <etext+0x35c>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	7df040ef          	jal	ffffffffc020579c <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	3ba50513          	addi	a0,a0,954 # ffffffffc0205b98 <etext+0x364>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	31050513          	addi	a0,a0,784 # ffffffffc0205bb8 <etext+0x384>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	31650513          	addi	a0,a0,790 # ffffffffc0205bd0 <etext+0x39c>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	32450513          	addi	a0,a0,804 # ffffffffc0205bf0 <etext+0x3bc>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	0009b797          	auipc	a5,0x9b
ffffffffc02008dc:	ca97bc23          	sd	s1,-840(a5) # ffffffffc029b590 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	0009b797          	auipc	a5,0x9b
ffffffffc02008e4:	ca87b423          	sd	s0,-856(a5) # ffffffffc029b588 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	0009b517          	auipc	a0,0x9b
ffffffffc02008ee:	ca653503          	ld	a0,-858(a0) # ffffffffc029b590 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	0009b517          	auipc	a0,0x9b
ffffffffc02008f8:	c9453503          	ld	a0,-876(a0) # ffffffffc029b588 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	4dc78793          	addi	a5,a5,1244 # ffffffffc0200dec <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	32a50513          	addi	a0,a0,810 # ffffffffc0205c58 <etext+0x424>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	33250513          	addi	a0,a0,818 # ffffffffc0205c70 <etext+0x43c>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	33c50513          	addi	a0,a0,828 # ffffffffc0205c88 <etext+0x454>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	34650513          	addi	a0,a0,838 # ffffffffc0205ca0 <etext+0x46c>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	35050513          	addi	a0,a0,848 # ffffffffc0205cb8 <etext+0x484>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	35a50513          	addi	a0,a0,858 # ffffffffc0205cd0 <etext+0x49c>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	36450513          	addi	a0,a0,868 # ffffffffc0205ce8 <etext+0x4b4>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	36e50513          	addi	a0,a0,878 # ffffffffc0205d00 <etext+0x4cc>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	37850513          	addi	a0,a0,888 # ffffffffc0205d18 <etext+0x4e4>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	38250513          	addi	a0,a0,898 # ffffffffc0205d30 <etext+0x4fc>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	38c50513          	addi	a0,a0,908 # ffffffffc0205d48 <etext+0x514>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	39650513          	addi	a0,a0,918 # ffffffffc0205d60 <etext+0x52c>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	3a050513          	addi	a0,a0,928 # ffffffffc0205d78 <etext+0x544>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	3aa50513          	addi	a0,a0,938 # ffffffffc0205d90 <etext+0x55c>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	3b450513          	addi	a0,a0,948 # ffffffffc0205da8 <etext+0x574>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	3be50513          	addi	a0,a0,958 # ffffffffc0205dc0 <etext+0x58c>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	3c850513          	addi	a0,a0,968 # ffffffffc0205dd8 <etext+0x5a4>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	3d250513          	addi	a0,a0,978 # ffffffffc0205df0 <etext+0x5bc>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	3dc50513          	addi	a0,a0,988 # ffffffffc0205e08 <etext+0x5d4>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	3e650513          	addi	a0,a0,998 # ffffffffc0205e20 <etext+0x5ec>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	3f050513          	addi	a0,a0,1008 # ffffffffc0205e38 <etext+0x604>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205e50 <etext+0x61c>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	40450513          	addi	a0,a0,1028 # ffffffffc0205e68 <etext+0x634>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	40e50513          	addi	a0,a0,1038 # ffffffffc0205e80 <etext+0x64c>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	41850513          	addi	a0,a0,1048 # ffffffffc0205e98 <etext+0x664>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	42250513          	addi	a0,a0,1058 # ffffffffc0205eb0 <etext+0x67c>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	42c50513          	addi	a0,a0,1068 # ffffffffc0205ec8 <etext+0x694>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	43650513          	addi	a0,a0,1078 # ffffffffc0205ee0 <etext+0x6ac>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	44050513          	addi	a0,a0,1088 # ffffffffc0205ef8 <etext+0x6c4>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	44a50513          	addi	a0,a0,1098 # ffffffffc0205f10 <etext+0x6dc>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	45450513          	addi	a0,a0,1108 # ffffffffc0205f28 <etext+0x6f4>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	45a50513          	addi	a0,a0,1114 # ffffffffc0205f40 <etext+0x70c>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	45c50513          	addi	a0,a0,1116 # ffffffffc0205f58 <etext+0x724>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	45c50513          	addi	a0,a0,1116 # ffffffffc0205f70 <etext+0x73c>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	46450513          	addi	a0,a0,1124 # ffffffffc0205f88 <etext+0x754>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	46c50513          	addi	a0,a0,1132 # ffffffffc0205fa0 <etext+0x76c>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	46850513          	addi	a0,a0,1128 # ffffffffc0205fb0 <etext+0x77c>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b56:	11853783          	ld	a5,280(a0)
ffffffffc0200b5a:	472d                	li	a4,11
ffffffffc0200b5c:	0786                	slli	a5,a5,0x1
ffffffffc0200b5e:	8385                	srli	a5,a5,0x1
ffffffffc0200b60:	08f76863          	bltu	a4,a5,ffffffffc0200bf0 <interrupt_handler+0x9a>
ffffffffc0200b64:	00007717          	auipc	a4,0x7
ffffffffc0200b68:	a5470713          	addi	a4,a4,-1452 # ffffffffc02075b8 <commands+0x48>
ffffffffc0200b6c:	078a                	slli	a5,a5,0x2
ffffffffc0200b6e:	97ba                	add	a5,a5,a4
ffffffffc0200b70:	439c                	lw	a5,0(a5)
ffffffffc0200b72:	97ba                	add	a5,a5,a4
ffffffffc0200b74:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	4b250513          	addi	a0,a0,1202 # ffffffffc0206028 <etext+0x7f4>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	48650513          	addi	a0,a0,1158 # ffffffffc0206008 <etext+0x7d4>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	43a50513          	addi	a0,a0,1082 # ffffffffc0205fc8 <etext+0x794>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	44e50513          	addi	a0,a0,1102 # ffffffffc0205fe8 <etext+0x7b4>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ba6:	1141                	addi	sp,sp,-16
ffffffffc0200ba8:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event(); // 设置下一次时钟中断
ffffffffc0200baa:	983ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        ticks++; // ticks 计数器自增
ffffffffc0200bae:	0009b797          	auipc	a5,0x9b
ffffffffc0200bb2:	9d278793          	addi	a5,a5,-1582 # ffffffffc029b580 <ticks>
ffffffffc0200bb6:	6394                	ld	a3,0(a5)
        if (ticks % TICK_NUM == 0) { // 每 TICK_NUM 次中断
ffffffffc0200bb8:	ccccd737          	lui	a4,0xccccd
ffffffffc0200bbc:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xca316dd>
        ticks++; // ticks 计数器自增
ffffffffc0200bc0:	0685                	addi	a3,a3,1
ffffffffc0200bc2:	e394                	sd	a3,0(a5)
        if (ticks % TICK_NUM == 0) { // 每 TICK_NUM 次中断
ffffffffc0200bc4:	6394                	ld	a3,0(a5)
ffffffffc0200bc6:	02071793          	slli	a5,a4,0x20
ffffffffc0200bca:	97ba                	add	a5,a5,a4
ffffffffc0200bcc:	02f6b7b3          	mulhu	a5,a3,a5
ffffffffc0200bd0:	838d                	srli	a5,a5,0x3
ffffffffc0200bd2:	00279713          	slli	a4,a5,0x2
ffffffffc0200bd6:	97ba                	add	a5,a5,a4
ffffffffc0200bd8:	0786                	slli	a5,a5,0x1
ffffffffc0200bda:	00f68c63          	beq	a3,a5,ffffffffc0200bf2 <interrupt_handler+0x9c>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bde:	60a2                	ld	ra,8(sp)
ffffffffc0200be0:	0141                	addi	sp,sp,16
ffffffffc0200be2:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	47450513          	addi	a0,a0,1140 # ffffffffc0206058 <etext+0x824>
ffffffffc0200bec:	da8ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bf0:	b711                	j	ffffffffc0200af4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200bf2:	45a9                	li	a1,10
ffffffffc0200bf4:	00005517          	auipc	a0,0x5
ffffffffc0200bf8:	45450513          	addi	a0,a0,1108 # ffffffffc0206048 <etext+0x814>
ffffffffc0200bfc:	d98ff0ef          	jal	ffffffffc0200194 <cprintf>
            if (current) { // 若有当前进程，设置为需要重调度
ffffffffc0200c00:	0009b797          	auipc	a5,0x9b
ffffffffc0200c04:	9d87b783          	ld	a5,-1576(a5) # ffffffffc029b5d8 <current>
ffffffffc0200c08:	dbf9                	beqz	a5,ffffffffc0200bde <interrupt_handler+0x88>
                current->need_resched = 1;
ffffffffc0200c0a:	4705                	li	a4,1
ffffffffc0200c0c:	ef98                	sd	a4,24(a5)
ffffffffc0200c0e:	bfc1                	j	ffffffffc0200bde <interrupt_handler+0x88>

ffffffffc0200c10 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c10:	11853783          	ld	a5,280(a0)
ffffffffc0200c14:	473d                	li	a4,15
ffffffffc0200c16:	14f76763          	bltu	a4,a5,ffffffffc0200d64 <exception_handler+0x154>
ffffffffc0200c1a:	00007717          	auipc	a4,0x7
ffffffffc0200c1e:	9ce70713          	addi	a4,a4,-1586 # ffffffffc02075e8 <commands+0x78>
ffffffffc0200c22:	078a                	slli	a5,a5,0x2
ffffffffc0200c24:	97ba                	add	a5,a5,a4
ffffffffc0200c26:	439c                	lw	a5,0(a5)
{
ffffffffc0200c28:	1101                	addi	sp,sp,-32
ffffffffc0200c2a:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c2c:	97ba                	add	a5,a5,a4
ffffffffc0200c2e:	86aa                	mv	a3,a0
ffffffffc0200c30:	8782                	jr	a5
ffffffffc0200c32:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c34:	00005517          	auipc	a0,0x5
ffffffffc0200c38:	52c50513          	addi	a0,a0,1324 # ffffffffc0206160 <etext+0x92c>
ffffffffc0200c3c:	d58ff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c40:	66a2                	ld	a3,8(sp)
ffffffffc0200c42:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c46:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c48:	0791                	addi	a5,a5,4
ffffffffc0200c4a:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c4e:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c50:	6a80406f          	j	ffffffffc02052f8 <syscall>
}
ffffffffc0200c54:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c56:	00005517          	auipc	a0,0x5
ffffffffc0200c5a:	52a50513          	addi	a0,a0,1322 # ffffffffc0206180 <etext+0x94c>
}
ffffffffc0200c5e:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c60:	d34ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c64:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c66:	00005517          	auipc	a0,0x5
ffffffffc0200c6a:	53a50513          	addi	a0,a0,1338 # ffffffffc02061a0 <etext+0x96c>
}
ffffffffc0200c6e:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c70:	d24ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c74:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c76:	00005517          	auipc	a0,0x5
ffffffffc0200c7a:	54a50513          	addi	a0,a0,1354 # ffffffffc02061c0 <etext+0x98c>
}
ffffffffc0200c7e:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c80:	d14ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c84:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c86:	00005517          	auipc	a0,0x5
ffffffffc0200c8a:	55250513          	addi	a0,a0,1362 # ffffffffc02061d8 <etext+0x9a4>
}
ffffffffc0200c8e:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c90:	d04ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c96:	00005517          	auipc	a0,0x5
ffffffffc0200c9a:	55a50513          	addi	a0,a0,1370 # ffffffffc02061f0 <etext+0x9bc>
}
ffffffffc0200c9e:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca0:	cf4ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200ca4:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200ca6:	00005517          	auipc	a0,0x5
ffffffffc0200caa:	3d250513          	addi	a0,a0,978 # ffffffffc0206078 <etext+0x844>
}
ffffffffc0200cae:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb0:	ce4ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cb4:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cb6:	00005517          	auipc	a0,0x5
ffffffffc0200cba:	3e250513          	addi	a0,a0,994 # ffffffffc0206098 <etext+0x864>
}
ffffffffc0200cbe:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cc0:	cd4ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cc4:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cc6:	00005517          	auipc	a0,0x5
ffffffffc0200cca:	3f250513          	addi	a0,a0,1010 # ffffffffc02060b8 <etext+0x884>
}
ffffffffc0200cce:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cd0:	cc4ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200cd4:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cd6:	00005517          	auipc	a0,0x5
ffffffffc0200cda:	3fa50513          	addi	a0,a0,1018 # ffffffffc02060d0 <etext+0x89c>
ffffffffc0200cde:	cb6ff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200ce2:	66a2                	ld	a3,8(sp)
ffffffffc0200ce4:	47a9                	li	a5,10
ffffffffc0200ce6:	66d8                	ld	a4,136(a3)
ffffffffc0200ce8:	04f70c63          	beq	a4,a5,ffffffffc0200d40 <exception_handler+0x130>
}
ffffffffc0200cec:	60e2                	ld	ra,24(sp)
ffffffffc0200cee:	6105                	addi	sp,sp,32
ffffffffc0200cf0:	8082                	ret
ffffffffc0200cf2:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cf4:	00005517          	auipc	a0,0x5
ffffffffc0200cf8:	3ec50513          	addi	a0,a0,1004 # ffffffffc02060e0 <etext+0x8ac>
}
ffffffffc0200cfc:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200cfe:	c96ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d02:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206100 <etext+0x8cc>
}
ffffffffc0200d0c:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d0e:	c86ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d12:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d14:	00005517          	auipc	a0,0x5
ffffffffc0200d18:	43450513          	addi	a0,a0,1076 # ffffffffc0206148 <etext+0x914>
}
ffffffffc0200d1c:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d1e:	c76ff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d22:	60e2                	ld	ra,24(sp)
ffffffffc0200d24:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d26:	b3f9                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d28:	00005617          	auipc	a2,0x5
ffffffffc0200d2c:	3f060613          	addi	a2,a2,1008 # ffffffffc0206118 <etext+0x8e4>
ffffffffc0200d30:	0c200593          	li	a1,194
ffffffffc0200d34:	00005517          	auipc	a0,0x5
ffffffffc0200d38:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206130 <etext+0x8fc>
ffffffffc0200d3c:	f0aff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200d40:	1086b783          	ld	a5,264(a3)
ffffffffc0200d44:	0791                	addi	a5,a5,4
ffffffffc0200d46:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200d4a:	5ae040ef          	jal	ffffffffc02052f8 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d4e:	0009b717          	auipc	a4,0x9b
ffffffffc0200d52:	88a73703          	ld	a4,-1910(a4) # ffffffffc029b5d8 <current>
ffffffffc0200d56:	6522                	ld	a0,8(sp)
}
ffffffffc0200d58:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d5a:	6b0c                	ld	a1,16(a4)
ffffffffc0200d5c:	6789                	lui	a5,0x2
ffffffffc0200d5e:	95be                	add	a1,a1,a5
}
ffffffffc0200d60:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d62:	aaa1                	j	ffffffffc0200eba <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200d64:	bb41                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d66 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d66:	0009b717          	auipc	a4,0x9b
ffffffffc0200d6a:	87273703          	ld	a4,-1934(a4) # ffffffffc029b5d8 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d6e:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d72:	cf21                	beqz	a4,ffffffffc0200dca <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d74:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d78:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d7c:	1101                	addi	sp,sp,-32
ffffffffc0200d7e:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d80:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d84:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d86:	e432                	sd	a2,8(sp)
ffffffffc0200d88:	e042                	sd	a6,0(sp)
ffffffffc0200d8a:	0205c763          	bltz	a1,ffffffffc0200db8 <trap+0x52>
        exception_handler(tf);
ffffffffc0200d8e:	e83ff0ef          	jal	ffffffffc0200c10 <exception_handler>
ffffffffc0200d92:	6622                	ld	a2,8(sp)
ffffffffc0200d94:	6802                	ld	a6,0(sp)
ffffffffc0200d96:	0009b697          	auipc	a3,0x9b
ffffffffc0200d9a:	84268693          	addi	a3,a3,-1982 # ffffffffc029b5d8 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d9e:	6298                	ld	a4,0(a3)
ffffffffc0200da0:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200da4:	e619                	bnez	a2,ffffffffc0200db2 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200da6:	0b072783          	lw	a5,176(a4)
ffffffffc0200daa:	8b85                	andi	a5,a5,1
ffffffffc0200dac:	e79d                	bnez	a5,ffffffffc0200dda <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200dae:	6f1c                	ld	a5,24(a4)
ffffffffc0200db0:	e38d                	bnez	a5,ffffffffc0200dd2 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200db2:	60e2                	ld	ra,24(sp)
ffffffffc0200db4:	6105                	addi	sp,sp,32
ffffffffc0200db6:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200db8:	d9fff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200dbc:	6802                	ld	a6,0(sp)
ffffffffc0200dbe:	6622                	ld	a2,8(sp)
ffffffffc0200dc0:	0009b697          	auipc	a3,0x9b
ffffffffc0200dc4:	81868693          	addi	a3,a3,-2024 # ffffffffc029b5d8 <current>
ffffffffc0200dc8:	bfd9                	j	ffffffffc0200d9e <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dca:	0005c363          	bltz	a1,ffffffffc0200dd0 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200dce:	b589                	j	ffffffffc0200c10 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dd0:	b359                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200dd2:	60e2                	ld	ra,24(sp)
ffffffffc0200dd4:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200dd6:	4360406f          	j	ffffffffc020520c <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dda:	555d                	li	a0,-9
ffffffffc0200ddc:	6d0030ef          	jal	ffffffffc02044ac <do_exit>
            if (current->need_resched)
ffffffffc0200de0:	0009a717          	auipc	a4,0x9a
ffffffffc0200de4:	7f873703          	ld	a4,2040(a4) # ffffffffc029b5d8 <current>
ffffffffc0200de8:	b7d9                	j	ffffffffc0200dae <trap+0x48>
	...

ffffffffc0200dec <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dec:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df0:	00011463          	bnez	sp,ffffffffc0200df8 <__alltraps+0xc>
ffffffffc0200df4:	14002173          	csrr	sp,sscratch
ffffffffc0200df8:	712d                	addi	sp,sp,-288
ffffffffc0200dfa:	e002                	sd	zero,0(sp)
ffffffffc0200dfc:	e406                	sd	ra,8(sp)
ffffffffc0200dfe:	ec0e                	sd	gp,24(sp)
ffffffffc0200e00:	f012                	sd	tp,32(sp)
ffffffffc0200e02:	f416                	sd	t0,40(sp)
ffffffffc0200e04:	f81a                	sd	t1,48(sp)
ffffffffc0200e06:	fc1e                	sd	t2,56(sp)
ffffffffc0200e08:	e0a2                	sd	s0,64(sp)
ffffffffc0200e0a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e0c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e0e:	ecae                	sd	a1,88(sp)
ffffffffc0200e10:	f0b2                	sd	a2,96(sp)
ffffffffc0200e12:	f4b6                	sd	a3,104(sp)
ffffffffc0200e14:	f8ba                	sd	a4,112(sp)
ffffffffc0200e16:	fcbe                	sd	a5,120(sp)
ffffffffc0200e18:	e142                	sd	a6,128(sp)
ffffffffc0200e1a:	e546                	sd	a7,136(sp)
ffffffffc0200e1c:	e94a                	sd	s2,144(sp)
ffffffffc0200e1e:	ed4e                	sd	s3,152(sp)
ffffffffc0200e20:	f152                	sd	s4,160(sp)
ffffffffc0200e22:	f556                	sd	s5,168(sp)
ffffffffc0200e24:	f95a                	sd	s6,176(sp)
ffffffffc0200e26:	fd5e                	sd	s7,184(sp)
ffffffffc0200e28:	e1e2                	sd	s8,192(sp)
ffffffffc0200e2a:	e5e6                	sd	s9,200(sp)
ffffffffc0200e2c:	e9ea                	sd	s10,208(sp)
ffffffffc0200e2e:	edee                	sd	s11,216(sp)
ffffffffc0200e30:	f1f2                	sd	t3,224(sp)
ffffffffc0200e32:	f5f6                	sd	t4,232(sp)
ffffffffc0200e34:	f9fa                	sd	t5,240(sp)
ffffffffc0200e36:	fdfe                	sd	t6,248(sp)
ffffffffc0200e38:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e3c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e40:	14102973          	csrr	s2,sepc
ffffffffc0200e44:	143029f3          	csrr	s3,stval
ffffffffc0200e48:	14202a73          	csrr	s4,scause
ffffffffc0200e4c:	e822                	sd	s0,16(sp)
ffffffffc0200e4e:	e226                	sd	s1,256(sp)
ffffffffc0200e50:	e64a                	sd	s2,264(sp)
ffffffffc0200e52:	ea4e                	sd	s3,272(sp)
ffffffffc0200e54:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e56:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e58:	f0fff0ef          	jal	ffffffffc0200d66 <trap>

ffffffffc0200e5c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e5c:	6492                	ld	s1,256(sp)
ffffffffc0200e5e:	6932                	ld	s2,264(sp)
ffffffffc0200e60:	1004f413          	andi	s0,s1,256
ffffffffc0200e64:	e401                	bnez	s0,ffffffffc0200e6c <__trapret+0x10>
ffffffffc0200e66:	1200                	addi	s0,sp,288
ffffffffc0200e68:	14041073          	csrw	sscratch,s0
ffffffffc0200e6c:	10049073          	csrw	sstatus,s1
ffffffffc0200e70:	14191073          	csrw	sepc,s2
ffffffffc0200e74:	60a2                	ld	ra,8(sp)
ffffffffc0200e76:	61e2                	ld	gp,24(sp)
ffffffffc0200e78:	7202                	ld	tp,32(sp)
ffffffffc0200e7a:	72a2                	ld	t0,40(sp)
ffffffffc0200e7c:	7342                	ld	t1,48(sp)
ffffffffc0200e7e:	73e2                	ld	t2,56(sp)
ffffffffc0200e80:	6406                	ld	s0,64(sp)
ffffffffc0200e82:	64a6                	ld	s1,72(sp)
ffffffffc0200e84:	6546                	ld	a0,80(sp)
ffffffffc0200e86:	65e6                	ld	a1,88(sp)
ffffffffc0200e88:	7606                	ld	a2,96(sp)
ffffffffc0200e8a:	76a6                	ld	a3,104(sp)
ffffffffc0200e8c:	7746                	ld	a4,112(sp)
ffffffffc0200e8e:	77e6                	ld	a5,120(sp)
ffffffffc0200e90:	680a                	ld	a6,128(sp)
ffffffffc0200e92:	68aa                	ld	a7,136(sp)
ffffffffc0200e94:	694a                	ld	s2,144(sp)
ffffffffc0200e96:	69ea                	ld	s3,152(sp)
ffffffffc0200e98:	7a0a                	ld	s4,160(sp)
ffffffffc0200e9a:	7aaa                	ld	s5,168(sp)
ffffffffc0200e9c:	7b4a                	ld	s6,176(sp)
ffffffffc0200e9e:	7bea                	ld	s7,184(sp)
ffffffffc0200ea0:	6c0e                	ld	s8,192(sp)
ffffffffc0200ea2:	6cae                	ld	s9,200(sp)
ffffffffc0200ea4:	6d4e                	ld	s10,208(sp)
ffffffffc0200ea6:	6dee                	ld	s11,216(sp)
ffffffffc0200ea8:	7e0e                	ld	t3,224(sp)
ffffffffc0200eaa:	7eae                	ld	t4,232(sp)
ffffffffc0200eac:	7f4e                	ld	t5,240(sp)
ffffffffc0200eae:	7fee                	ld	t6,248(sp)
ffffffffc0200eb0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eb2:	10200073          	sret

ffffffffc0200eb6 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200eb6:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200eb8:	b755                	j	ffffffffc0200e5c <__trapret>

ffffffffc0200eba <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200eba:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200ebe:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200ec2:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200ec6:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200eca:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200ece:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200ed2:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ed6:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200eda:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ede:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ee0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200ee2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ee4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200ee6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ee8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200eea:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200eec:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200eee:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ef0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200ef2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200ef4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200ef6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200ef8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200efa:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200efc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200efe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f00:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f02:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f04:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f06:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f08:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f0a:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f0c:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f0e:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f10:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f12:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f14:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f16:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f18:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f1a:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f1c:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f1e:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f20:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f22:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f24:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f26:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f28:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f2a:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f2c:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f2e:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f30:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f32:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f34:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f36:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f38:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f3a:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f3c:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f3e:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f40:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f42:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f44:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f46:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f48:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f4a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f4c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f4e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f50:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f52:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f54:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f56:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f58:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f5a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f5c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f5e:	812e                	mv	sp,a1
ffffffffc0200f60:	bdf5                	j	ffffffffc0200e5c <__trapret>

ffffffffc0200f62 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f62:	00096797          	auipc	a5,0x96
ffffffffc0200f66:	5e678793          	addi	a5,a5,1510 # ffffffffc0297548 <free_area>
ffffffffc0200f6a:	e79c                	sd	a5,8(a5)
ffffffffc0200f6c:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f72:	8082                	ret

ffffffffc0200f74 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f74:	00096517          	auipc	a0,0x96
ffffffffc0200f78:	5e456503          	lwu	a0,1508(a0) # ffffffffc0297558 <free_area+0x10>
ffffffffc0200f7c:	8082                	ret

ffffffffc0200f7e <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f7e:	711d                	addi	sp,sp,-96
ffffffffc0200f80:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f82:	00096917          	auipc	s2,0x96
ffffffffc0200f86:	5c690913          	addi	s2,s2,1478 # ffffffffc0297548 <free_area>
ffffffffc0200f8a:	00893783          	ld	a5,8(s2)
ffffffffc0200f8e:	ec86                	sd	ra,88(sp)
ffffffffc0200f90:	e8a2                	sd	s0,80(sp)
ffffffffc0200f92:	e4a6                	sd	s1,72(sp)
ffffffffc0200f94:	fc4e                	sd	s3,56(sp)
ffffffffc0200f96:	f852                	sd	s4,48(sp)
ffffffffc0200f98:	f456                	sd	s5,40(sp)
ffffffffc0200f9a:	f05a                	sd	s6,32(sp)
ffffffffc0200f9c:	ec5e                	sd	s7,24(sp)
ffffffffc0200f9e:	e862                	sd	s8,16(sp)
ffffffffc0200fa0:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fa2:	2f278363          	beq	a5,s2,ffffffffc0201288 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200fa6:	4401                	li	s0,0
ffffffffc0200fa8:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200faa:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fae:	8b09                	andi	a4,a4,2
ffffffffc0200fb0:	2e070063          	beqz	a4,ffffffffc0201290 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200fb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fb8:	679c                	ld	a5,8(a5)
ffffffffc0200fba:	2485                	addiw	s1,s1,1
ffffffffc0200fbc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fbe:	ff2796e3          	bne	a5,s2,ffffffffc0200faa <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200fc2:	89a2                	mv	s3,s0
ffffffffc0200fc4:	741000ef          	jal	ffffffffc0201f04 <nr_free_pages>
ffffffffc0200fc8:	73351463          	bne	a0,s3,ffffffffc02016f0 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	6c5000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fd2:	8a2a                	mv	s4,a0
ffffffffc0200fd4:	44050e63          	beqz	a0,ffffffffc0201430 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fd8:	4505                	li	a0,1
ffffffffc0200fda:	6b9000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fde:	89aa                	mv	s3,a0
ffffffffc0200fe0:	72050863          	beqz	a0,ffffffffc0201710 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fe4:	4505                	li	a0,1
ffffffffc0200fe6:	6ad000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0200fea:	8aaa                	mv	s5,a0
ffffffffc0200fec:	4c050263          	beqz	a0,ffffffffc02014b0 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ff0:	40a987b3          	sub	a5,s3,a0
ffffffffc0200ff4:	40aa0733          	sub	a4,s4,a0
ffffffffc0200ff8:	0017b793          	seqz	a5,a5
ffffffffc0200ffc:	00173713          	seqz	a4,a4
ffffffffc0201000:	8fd9                	or	a5,a5,a4
ffffffffc0201002:	30079763          	bnez	a5,ffffffffc0201310 <default_check+0x392>
ffffffffc0201006:	313a0563          	beq	s4,s3,ffffffffc0201310 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020100a:	000a2783          	lw	a5,0(s4)
ffffffffc020100e:	2a079163          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
ffffffffc0201012:	0009a783          	lw	a5,0(s3)
ffffffffc0201016:	28079d63          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
ffffffffc020101a:	411c                	lw	a5,0(a0)
ffffffffc020101c:	28079a63          	bnez	a5,ffffffffc02012b0 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201020:	0009a797          	auipc	a5,0x9a
ffffffffc0201024:	5a87b783          	ld	a5,1448(a5) # ffffffffc029b5c8 <pages>
ffffffffc0201028:	00007617          	auipc	a2,0x7
ffffffffc020102c:	95863603          	ld	a2,-1704(a2) # ffffffffc0207980 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201030:	0009a697          	auipc	a3,0x9a
ffffffffc0201034:	5906b683          	ld	a3,1424(a3) # ffffffffc029b5c0 <npage>
ffffffffc0201038:	40fa0733          	sub	a4,s4,a5
ffffffffc020103c:	8719                	srai	a4,a4,0x6
ffffffffc020103e:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201040:	0732                	slli	a4,a4,0xc
ffffffffc0201042:	06b2                	slli	a3,a3,0xc
ffffffffc0201044:	2ad77663          	bgeu	a4,a3,ffffffffc02012f0 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0201048:	40f98733          	sub	a4,s3,a5
ffffffffc020104c:	8719                	srai	a4,a4,0x6
ffffffffc020104e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201050:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201052:	4cd77f63          	bgeu	a4,a3,ffffffffc0201530 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc0201056:	40f507b3          	sub	a5,a0,a5
ffffffffc020105a:	8799                	srai	a5,a5,0x6
ffffffffc020105c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020105e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201060:	32d7f863          	bgeu	a5,a3,ffffffffc0201390 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc0201064:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201066:	00093c03          	ld	s8,0(s2)
ffffffffc020106a:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020106e:	00096b17          	auipc	s6,0x96
ffffffffc0201072:	4eab2b03          	lw	s6,1258(s6) # ffffffffc0297558 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0201076:	01293023          	sd	s2,0(s2)
ffffffffc020107a:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc020107e:	00096797          	auipc	a5,0x96
ffffffffc0201082:	4c07ad23          	sw	zero,1242(a5) # ffffffffc0297558 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201086:	60d000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020108a:	2e051363          	bnez	a0,ffffffffc0201370 <default_check+0x3f2>
    free_page(p0);
ffffffffc020108e:	8552                	mv	a0,s4
ffffffffc0201090:	4585                	li	a1,1
ffffffffc0201092:	63b000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p1);
ffffffffc0201096:	854e                	mv	a0,s3
ffffffffc0201098:	4585                	li	a1,1
ffffffffc020109a:	633000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc020109e:	8556                	mv	a0,s5
ffffffffc02010a0:	4585                	li	a1,1
ffffffffc02010a2:	62b000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(nr_free == 3);
ffffffffc02010a6:	00096717          	auipc	a4,0x96
ffffffffc02010aa:	4b272703          	lw	a4,1202(a4) # ffffffffc0297558 <free_area+0x10>
ffffffffc02010ae:	478d                	li	a5,3
ffffffffc02010b0:	2af71063          	bne	a4,a5,ffffffffc0201350 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010b4:	4505                	li	a0,1
ffffffffc02010b6:	5dd000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010ba:	89aa                	mv	s3,a0
ffffffffc02010bc:	26050a63          	beqz	a0,ffffffffc0201330 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	5d1000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010c6:	8aaa                	mv	s5,a0
ffffffffc02010c8:	3c050463          	beqz	a0,ffffffffc0201490 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010cc:	4505                	li	a0,1
ffffffffc02010ce:	5c5000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010d2:	8a2a                	mv	s4,a0
ffffffffc02010d4:	38050e63          	beqz	a0,ffffffffc0201470 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010d8:	4505                	li	a0,1
ffffffffc02010da:	5b9000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010de:	36051963          	bnez	a0,ffffffffc0201450 <default_check+0x4d2>
    free_page(p0);
ffffffffc02010e2:	4585                	li	a1,1
ffffffffc02010e4:	854e                	mv	a0,s3
ffffffffc02010e6:	5e7000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010ea:	00893783          	ld	a5,8(s2)
ffffffffc02010ee:	1f278163          	beq	a5,s2,ffffffffc02012d0 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc02010f2:	4505                	li	a0,1
ffffffffc02010f4:	59f000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02010f8:	8caa                	mv	s9,a0
ffffffffc02010fa:	30a99b63          	bne	s3,a0,ffffffffc0201410 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc02010fe:	4505                	li	a0,1
ffffffffc0201100:	593000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201104:	2e051663          	bnez	a0,ffffffffc02013f0 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201108:	00096797          	auipc	a5,0x96
ffffffffc020110c:	4507a783          	lw	a5,1104(a5) # ffffffffc0297558 <free_area+0x10>
ffffffffc0201110:	2c079063          	bnez	a5,ffffffffc02013d0 <default_check+0x452>
    free_page(p);
ffffffffc0201114:	8566                	mv	a0,s9
ffffffffc0201116:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201118:	01893023          	sd	s8,0(s2)
ffffffffc020111c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201120:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201124:	5a9000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p1);
ffffffffc0201128:	8556                	mv	a0,s5
ffffffffc020112a:	4585                	li	a1,1
ffffffffc020112c:	5a1000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc0201130:	8552                	mv	a0,s4
ffffffffc0201132:	4585                	li	a1,1
ffffffffc0201134:	599000ef          	jal	ffffffffc0201ecc <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201138:	4515                	li	a0,5
ffffffffc020113a:	559000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020113e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201140:	26050863          	beqz	a0,ffffffffc02013b0 <default_check+0x432>
ffffffffc0201144:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc0201146:	8b89                	andi	a5,a5,2
ffffffffc0201148:	54079463          	bnez	a5,ffffffffc0201690 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020114c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020114e:	00093b83          	ld	s7,0(s2)
ffffffffc0201152:	00893b03          	ld	s6,8(s2)
ffffffffc0201156:	01293023          	sd	s2,0(s2)
ffffffffc020115a:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc020115e:	535000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201162:	50051763          	bnez	a0,ffffffffc0201670 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201166:	08098a13          	addi	s4,s3,128
ffffffffc020116a:	8552                	mv	a0,s4
ffffffffc020116c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020116e:	00096c17          	auipc	s8,0x96
ffffffffc0201172:	3eac2c03          	lw	s8,1002(s8) # ffffffffc0297558 <free_area+0x10>
    nr_free = 0;
ffffffffc0201176:	00096797          	auipc	a5,0x96
ffffffffc020117a:	3e07a123          	sw	zero,994(a5) # ffffffffc0297558 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020117e:	54f000ef          	jal	ffffffffc0201ecc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201182:	4511                	li	a0,4
ffffffffc0201184:	50f000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201188:	4c051463          	bnez	a0,ffffffffc0201650 <default_check+0x6d2>
ffffffffc020118c:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201190:	8b89                	andi	a5,a5,2
ffffffffc0201192:	48078f63          	beqz	a5,ffffffffc0201630 <default_check+0x6b2>
ffffffffc0201196:	0909a503          	lw	a0,144(s3)
ffffffffc020119a:	478d                	li	a5,3
ffffffffc020119c:	48f51a63          	bne	a0,a5,ffffffffc0201630 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011a0:	4f3000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011a4:	8aaa                	mv	s5,a0
ffffffffc02011a6:	46050563          	beqz	a0,ffffffffc0201610 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02011aa:	4505                	li	a0,1
ffffffffc02011ac:	4e7000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011b0:	44051063          	bnez	a0,ffffffffc02015f0 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02011b4:	415a1e63          	bne	s4,s5,ffffffffc02015d0 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011b8:	4585                	li	a1,1
ffffffffc02011ba:	854e                	mv	a0,s3
ffffffffc02011bc:	511000ef          	jal	ffffffffc0201ecc <free_pages>
    free_pages(p1, 3);
ffffffffc02011c0:	8552                	mv	a0,s4
ffffffffc02011c2:	458d                	li	a1,3
ffffffffc02011c4:	509000ef          	jal	ffffffffc0201ecc <free_pages>
ffffffffc02011c8:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011cc:	8b89                	andi	a5,a5,2
ffffffffc02011ce:	3e078163          	beqz	a5,ffffffffc02015b0 <default_check+0x632>
ffffffffc02011d2:	0109aa83          	lw	s5,16(s3)
ffffffffc02011d6:	4785                	li	a5,1
ffffffffc02011d8:	3cfa9c63          	bne	s5,a5,ffffffffc02015b0 <default_check+0x632>
ffffffffc02011dc:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011e0:	8b89                	andi	a5,a5,2
ffffffffc02011e2:	3a078763          	beqz	a5,ffffffffc0201590 <default_check+0x612>
ffffffffc02011e6:	010a2703          	lw	a4,16(s4)
ffffffffc02011ea:	478d                	li	a5,3
ffffffffc02011ec:	3af71263          	bne	a4,a5,ffffffffc0201590 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011f0:	8556                	mv	a0,s5
ffffffffc02011f2:	4a1000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02011f6:	36a99d63          	bne	s3,a0,ffffffffc0201570 <default_check+0x5f2>
    free_page(p0);
ffffffffc02011fa:	85d6                	mv	a1,s5
ffffffffc02011fc:	4d1000ef          	jal	ffffffffc0201ecc <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201200:	4509                	li	a0,2
ffffffffc0201202:	491000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201206:	34aa1563          	bne	s4,a0,ffffffffc0201550 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020120a:	4589                	li	a1,2
ffffffffc020120c:	4c1000ef          	jal	ffffffffc0201ecc <free_pages>
    free_page(p2);
ffffffffc0201210:	04098513          	addi	a0,s3,64
ffffffffc0201214:	85d6                	mv	a1,s5
ffffffffc0201216:	4b7000ef          	jal	ffffffffc0201ecc <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020121a:	4515                	li	a0,5
ffffffffc020121c:	477000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc0201220:	89aa                	mv	s3,a0
ffffffffc0201222:	48050763          	beqz	a0,ffffffffc02016b0 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc0201226:	8556                	mv	a0,s5
ffffffffc0201228:	46b000ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020122c:	2e051263          	bnez	a0,ffffffffc0201510 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201230:	00096797          	auipc	a5,0x96
ffffffffc0201234:	3287a783          	lw	a5,808(a5) # ffffffffc0297558 <free_area+0x10>
ffffffffc0201238:	2a079c63          	bnez	a5,ffffffffc02014f0 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020123c:	854e                	mv	a0,s3
ffffffffc020123e:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201240:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201244:	01793023          	sd	s7,0(s2)
ffffffffc0201248:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc020124c:	481000ef          	jal	ffffffffc0201ecc <free_pages>
    return listelm->next;
ffffffffc0201250:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201254:	01278963          	beq	a5,s2,ffffffffc0201266 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201258:	ff87a703          	lw	a4,-8(a5)
ffffffffc020125c:	679c                	ld	a5,8(a5)
ffffffffc020125e:	34fd                	addiw	s1,s1,-1
ffffffffc0201260:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201262:	ff279be3          	bne	a5,s2,ffffffffc0201258 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc0201266:	26049563          	bnez	s1,ffffffffc02014d0 <default_check+0x552>
    assert(total == 0);
ffffffffc020126a:	46041363          	bnez	s0,ffffffffc02016d0 <default_check+0x752>
}
ffffffffc020126e:	60e6                	ld	ra,88(sp)
ffffffffc0201270:	6446                	ld	s0,80(sp)
ffffffffc0201272:	64a6                	ld	s1,72(sp)
ffffffffc0201274:	6906                	ld	s2,64(sp)
ffffffffc0201276:	79e2                	ld	s3,56(sp)
ffffffffc0201278:	7a42                	ld	s4,48(sp)
ffffffffc020127a:	7aa2                	ld	s5,40(sp)
ffffffffc020127c:	7b02                	ld	s6,32(sp)
ffffffffc020127e:	6be2                	ld	s7,24(sp)
ffffffffc0201280:	6c42                	ld	s8,16(sp)
ffffffffc0201282:	6ca2                	ld	s9,8(sp)
ffffffffc0201284:	6125                	addi	sp,sp,96
ffffffffc0201286:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201288:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020128a:	4401                	li	s0,0
ffffffffc020128c:	4481                	li	s1,0
ffffffffc020128e:	bb1d                	j	ffffffffc0200fc4 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201290:	00005697          	auipc	a3,0x5
ffffffffc0201294:	f7868693          	addi	a3,a3,-136 # ffffffffc0206208 <etext+0x9d4>
ffffffffc0201298:	00005617          	auipc	a2,0x5
ffffffffc020129c:	f8060613          	addi	a2,a2,-128 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02012a0:	11000593          	li	a1,272
ffffffffc02012a4:	00005517          	auipc	a0,0x5
ffffffffc02012a8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02012ac:	99aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012b0:	00005697          	auipc	a3,0x5
ffffffffc02012b4:	04068693          	addi	a3,a3,64 # ffffffffc02062f0 <etext+0xabc>
ffffffffc02012b8:	00005617          	auipc	a2,0x5
ffffffffc02012bc:	f6060613          	addi	a2,a2,-160 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02012c0:	0dc00593          	li	a1,220
ffffffffc02012c4:	00005517          	auipc	a0,0x5
ffffffffc02012c8:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02012cc:	97aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d0:	00005697          	auipc	a3,0x5
ffffffffc02012d4:	0e868693          	addi	a3,a3,232 # ffffffffc02063b8 <etext+0xb84>
ffffffffc02012d8:	00005617          	auipc	a2,0x5
ffffffffc02012dc:	f4060613          	addi	a2,a2,-192 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02012e0:	0f700593          	li	a1,247
ffffffffc02012e4:	00005517          	auipc	a0,0x5
ffffffffc02012e8:	f4c50513          	addi	a0,a0,-180 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02012ec:	95aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012f0:	00005697          	auipc	a3,0x5
ffffffffc02012f4:	04068693          	addi	a3,a3,64 # ffffffffc0206330 <etext+0xafc>
ffffffffc02012f8:	00005617          	auipc	a2,0x5
ffffffffc02012fc:	f2060613          	addi	a2,a2,-224 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201300:	0de00593          	li	a1,222
ffffffffc0201304:	00005517          	auipc	a0,0x5
ffffffffc0201308:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020130c:	93aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201310:	00005697          	auipc	a3,0x5
ffffffffc0201314:	fb868693          	addi	a3,a3,-72 # ffffffffc02062c8 <etext+0xa94>
ffffffffc0201318:	00005617          	auipc	a2,0x5
ffffffffc020131c:	f0060613          	addi	a2,a2,-256 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201320:	0db00593          	li	a1,219
ffffffffc0201324:	00005517          	auipc	a0,0x5
ffffffffc0201328:	f0c50513          	addi	a0,a0,-244 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020132c:	91aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201330:	00005697          	auipc	a3,0x5
ffffffffc0201334:	f3868693          	addi	a3,a3,-200 # ffffffffc0206268 <etext+0xa34>
ffffffffc0201338:	00005617          	auipc	a2,0x5
ffffffffc020133c:	ee060613          	addi	a2,a2,-288 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201340:	0f000593          	li	a1,240
ffffffffc0201344:	00005517          	auipc	a0,0x5
ffffffffc0201348:	eec50513          	addi	a0,a0,-276 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020134c:	8faff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201350:	00005697          	auipc	a3,0x5
ffffffffc0201354:	05868693          	addi	a3,a3,88 # ffffffffc02063a8 <etext+0xb74>
ffffffffc0201358:	00005617          	auipc	a2,0x5
ffffffffc020135c:	ec060613          	addi	a2,a2,-320 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201360:	0ee00593          	li	a1,238
ffffffffc0201364:	00005517          	auipc	a0,0x5
ffffffffc0201368:	ecc50513          	addi	a0,a0,-308 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020136c:	8daff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201370:	00005697          	auipc	a3,0x5
ffffffffc0201374:	02068693          	addi	a3,a3,32 # ffffffffc0206390 <etext+0xb5c>
ffffffffc0201378:	00005617          	auipc	a2,0x5
ffffffffc020137c:	ea060613          	addi	a2,a2,-352 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201380:	0e900593          	li	a1,233
ffffffffc0201384:	00005517          	auipc	a0,0x5
ffffffffc0201388:	eac50513          	addi	a0,a0,-340 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020138c:	8baff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201390:	00005697          	auipc	a3,0x5
ffffffffc0201394:	fe068693          	addi	a3,a3,-32 # ffffffffc0206370 <etext+0xb3c>
ffffffffc0201398:	00005617          	auipc	a2,0x5
ffffffffc020139c:	e8060613          	addi	a2,a2,-384 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02013a0:	0e000593          	li	a1,224
ffffffffc02013a4:	00005517          	auipc	a0,0x5
ffffffffc02013a8:	e8c50513          	addi	a0,a0,-372 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02013ac:	89aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02013b0:	00005697          	auipc	a3,0x5
ffffffffc02013b4:	05068693          	addi	a3,a3,80 # ffffffffc0206400 <etext+0xbcc>
ffffffffc02013b8:	00005617          	auipc	a2,0x5
ffffffffc02013bc:	e6060613          	addi	a2,a2,-416 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02013c0:	11800593          	li	a1,280
ffffffffc02013c4:	00005517          	auipc	a0,0x5
ffffffffc02013c8:	e6c50513          	addi	a0,a0,-404 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02013cc:	87aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013d0:	00005697          	auipc	a3,0x5
ffffffffc02013d4:	02068693          	addi	a3,a3,32 # ffffffffc02063f0 <etext+0xbbc>
ffffffffc02013d8:	00005617          	auipc	a2,0x5
ffffffffc02013dc:	e4060613          	addi	a2,a2,-448 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02013e0:	0fd00593          	li	a1,253
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	e4c50513          	addi	a0,a0,-436 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02013ec:	85aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f0:	00005697          	auipc	a3,0x5
ffffffffc02013f4:	fa068693          	addi	a3,a3,-96 # ffffffffc0206390 <etext+0xb5c>
ffffffffc02013f8:	00005617          	auipc	a2,0x5
ffffffffc02013fc:	e2060613          	addi	a2,a2,-480 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201400:	0fb00593          	li	a1,251
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	e2c50513          	addi	a0,a0,-468 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020140c:	83aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201410:	00005697          	auipc	a3,0x5
ffffffffc0201414:	fc068693          	addi	a3,a3,-64 # ffffffffc02063d0 <etext+0xb9c>
ffffffffc0201418:	00005617          	auipc	a2,0x5
ffffffffc020141c:	e0060613          	addi	a2,a2,-512 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201420:	0fa00593          	li	a1,250
ffffffffc0201424:	00005517          	auipc	a0,0x5
ffffffffc0201428:	e0c50513          	addi	a0,a0,-500 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020142c:	81aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201430:	00005697          	auipc	a3,0x5
ffffffffc0201434:	e3868693          	addi	a3,a3,-456 # ffffffffc0206268 <etext+0xa34>
ffffffffc0201438:	00005617          	auipc	a2,0x5
ffffffffc020143c:	de060613          	addi	a2,a2,-544 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201440:	0d700593          	li	a1,215
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	dec50513          	addi	a0,a0,-532 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020144c:	ffbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201450:	00005697          	auipc	a3,0x5
ffffffffc0201454:	f4068693          	addi	a3,a3,-192 # ffffffffc0206390 <etext+0xb5c>
ffffffffc0201458:	00005617          	auipc	a2,0x5
ffffffffc020145c:	dc060613          	addi	a2,a2,-576 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201460:	0f400593          	li	a1,244
ffffffffc0201464:	00005517          	auipc	a0,0x5
ffffffffc0201468:	dcc50513          	addi	a0,a0,-564 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020146c:	fdbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	e3868693          	addi	a3,a3,-456 # ffffffffc02062a8 <etext+0xa74>
ffffffffc0201478:	00005617          	auipc	a2,0x5
ffffffffc020147c:	da060613          	addi	a2,a2,-608 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201480:	0f200593          	li	a1,242
ffffffffc0201484:	00005517          	auipc	a0,0x5
ffffffffc0201488:	dac50513          	addi	a0,a0,-596 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020148c:	fbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	df868693          	addi	a3,a3,-520 # ffffffffc0206288 <etext+0xa54>
ffffffffc0201498:	00005617          	auipc	a2,0x5
ffffffffc020149c:	d8060613          	addi	a2,a2,-640 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02014a0:	0f100593          	li	a1,241
ffffffffc02014a4:	00005517          	auipc	a0,0x5
ffffffffc02014a8:	d8c50513          	addi	a0,a0,-628 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02014ac:	f9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014b0:	00005697          	auipc	a3,0x5
ffffffffc02014b4:	df868693          	addi	a3,a3,-520 # ffffffffc02062a8 <etext+0xa74>
ffffffffc02014b8:	00005617          	auipc	a2,0x5
ffffffffc02014bc:	d6060613          	addi	a2,a2,-672 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02014c0:	0d900593          	li	a1,217
ffffffffc02014c4:	00005517          	auipc	a0,0x5
ffffffffc02014c8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02014cc:	f7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014d0:	00005697          	auipc	a3,0x5
ffffffffc02014d4:	08068693          	addi	a3,a3,128 # ffffffffc0206550 <etext+0xd1c>
ffffffffc02014d8:	00005617          	auipc	a2,0x5
ffffffffc02014dc:	d4060613          	addi	a2,a2,-704 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02014e0:	14600593          	li	a1,326
ffffffffc02014e4:	00005517          	auipc	a0,0x5
ffffffffc02014e8:	d4c50513          	addi	a0,a0,-692 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02014ec:	f5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02014f0:	00005697          	auipc	a3,0x5
ffffffffc02014f4:	f0068693          	addi	a3,a3,-256 # ffffffffc02063f0 <etext+0xbbc>
ffffffffc02014f8:	00005617          	auipc	a2,0x5
ffffffffc02014fc:	d2060613          	addi	a2,a2,-736 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201500:	13a00593          	li	a1,314
ffffffffc0201504:	00005517          	auipc	a0,0x5
ffffffffc0201508:	d2c50513          	addi	a0,a0,-724 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020150c:	f3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201510:	00005697          	auipc	a3,0x5
ffffffffc0201514:	e8068693          	addi	a3,a3,-384 # ffffffffc0206390 <etext+0xb5c>
ffffffffc0201518:	00005617          	auipc	a2,0x5
ffffffffc020151c:	d0060613          	addi	a2,a2,-768 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201520:	13800593          	li	a1,312
ffffffffc0201524:	00005517          	auipc	a0,0x5
ffffffffc0201528:	d0c50513          	addi	a0,a0,-756 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020152c:	f1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201530:	00005697          	auipc	a3,0x5
ffffffffc0201534:	e2068693          	addi	a3,a3,-480 # ffffffffc0206350 <etext+0xb1c>
ffffffffc0201538:	00005617          	auipc	a2,0x5
ffffffffc020153c:	ce060613          	addi	a2,a2,-800 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201540:	0df00593          	li	a1,223
ffffffffc0201544:	00005517          	auipc	a0,0x5
ffffffffc0201548:	cec50513          	addi	a0,a0,-788 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020154c:	efbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201550:	00005697          	auipc	a3,0x5
ffffffffc0201554:	fc068693          	addi	a3,a3,-64 # ffffffffc0206510 <etext+0xcdc>
ffffffffc0201558:	00005617          	auipc	a2,0x5
ffffffffc020155c:	cc060613          	addi	a2,a2,-832 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201560:	13200593          	li	a1,306
ffffffffc0201564:	00005517          	auipc	a0,0x5
ffffffffc0201568:	ccc50513          	addi	a0,a0,-820 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020156c:	edbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201570:	00005697          	auipc	a3,0x5
ffffffffc0201574:	f8068693          	addi	a3,a3,-128 # ffffffffc02064f0 <etext+0xcbc>
ffffffffc0201578:	00005617          	auipc	a2,0x5
ffffffffc020157c:	ca060613          	addi	a2,a2,-864 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201580:	13000593          	li	a1,304
ffffffffc0201584:	00005517          	auipc	a0,0x5
ffffffffc0201588:	cac50513          	addi	a0,a0,-852 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020158c:	ebbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201590:	00005697          	auipc	a3,0x5
ffffffffc0201594:	f3868693          	addi	a3,a3,-200 # ffffffffc02064c8 <etext+0xc94>
ffffffffc0201598:	00005617          	auipc	a2,0x5
ffffffffc020159c:	c8060613          	addi	a2,a2,-896 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02015a0:	12e00593          	li	a1,302
ffffffffc02015a4:	00005517          	auipc	a0,0x5
ffffffffc02015a8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02015ac:	e9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	ef068693          	addi	a3,a3,-272 # ffffffffc02064a0 <etext+0xc6c>
ffffffffc02015b8:	00005617          	auipc	a2,0x5
ffffffffc02015bc:	c6060613          	addi	a2,a2,-928 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02015c0:	12d00593          	li	a1,301
ffffffffc02015c4:	00005517          	auipc	a0,0x5
ffffffffc02015c8:	c6c50513          	addi	a0,a0,-916 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02015cc:	e7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015d0:	00005697          	auipc	a3,0x5
ffffffffc02015d4:	ec068693          	addi	a3,a3,-320 # ffffffffc0206490 <etext+0xc5c>
ffffffffc02015d8:	00005617          	auipc	a2,0x5
ffffffffc02015dc:	c4060613          	addi	a2,a2,-960 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02015e0:	12800593          	li	a1,296
ffffffffc02015e4:	00005517          	auipc	a0,0x5
ffffffffc02015e8:	c4c50513          	addi	a0,a0,-948 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02015ec:	e5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015f0:	00005697          	auipc	a3,0x5
ffffffffc02015f4:	da068693          	addi	a3,a3,-608 # ffffffffc0206390 <etext+0xb5c>
ffffffffc02015f8:	00005617          	auipc	a2,0x5
ffffffffc02015fc:	c2060613          	addi	a2,a2,-992 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201600:	12700593          	li	a1,295
ffffffffc0201604:	00005517          	auipc	a0,0x5
ffffffffc0201608:	c2c50513          	addi	a0,a0,-980 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020160c:	e3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201610:	00005697          	auipc	a3,0x5
ffffffffc0201614:	e6068693          	addi	a3,a3,-416 # ffffffffc0206470 <etext+0xc3c>
ffffffffc0201618:	00005617          	auipc	a2,0x5
ffffffffc020161c:	c0060613          	addi	a2,a2,-1024 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201620:	12600593          	li	a1,294
ffffffffc0201624:	00005517          	auipc	a0,0x5
ffffffffc0201628:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020162c:	e1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	e1068693          	addi	a3,a3,-496 # ffffffffc0206440 <etext+0xc0c>
ffffffffc0201638:	00005617          	auipc	a2,0x5
ffffffffc020163c:	be060613          	addi	a2,a2,-1056 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201640:	12500593          	li	a1,293
ffffffffc0201644:	00005517          	auipc	a0,0x5
ffffffffc0201648:	bec50513          	addi	a0,a0,-1044 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020164c:	dfbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201650:	00005697          	auipc	a3,0x5
ffffffffc0201654:	dd868693          	addi	a3,a3,-552 # ffffffffc0206428 <etext+0xbf4>
ffffffffc0201658:	00005617          	auipc	a2,0x5
ffffffffc020165c:	bc060613          	addi	a2,a2,-1088 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201660:	12400593          	li	a1,292
ffffffffc0201664:	00005517          	auipc	a0,0x5
ffffffffc0201668:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020166c:	ddbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201670:	00005697          	auipc	a3,0x5
ffffffffc0201674:	d2068693          	addi	a3,a3,-736 # ffffffffc0206390 <etext+0xb5c>
ffffffffc0201678:	00005617          	auipc	a2,0x5
ffffffffc020167c:	ba060613          	addi	a2,a2,-1120 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201680:	11e00593          	li	a1,286
ffffffffc0201684:	00005517          	auipc	a0,0x5
ffffffffc0201688:	bac50513          	addi	a0,a0,-1108 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020168c:	dbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201690:	00005697          	auipc	a3,0x5
ffffffffc0201694:	d8068693          	addi	a3,a3,-640 # ffffffffc0206410 <etext+0xbdc>
ffffffffc0201698:	00005617          	auipc	a2,0x5
ffffffffc020169c:	b8060613          	addi	a2,a2,-1152 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02016a0:	11900593          	li	a1,281
ffffffffc02016a4:	00005517          	auipc	a0,0x5
ffffffffc02016a8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02016ac:	d9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016b0:	00005697          	auipc	a3,0x5
ffffffffc02016b4:	e8068693          	addi	a3,a3,-384 # ffffffffc0206530 <etext+0xcfc>
ffffffffc02016b8:	00005617          	auipc	a2,0x5
ffffffffc02016bc:	b6060613          	addi	a2,a2,-1184 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02016c0:	13700593          	li	a1,311
ffffffffc02016c4:	00005517          	auipc	a0,0x5
ffffffffc02016c8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02016cc:	d7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016d0:	00005697          	auipc	a3,0x5
ffffffffc02016d4:	e9068693          	addi	a3,a3,-368 # ffffffffc0206560 <etext+0xd2c>
ffffffffc02016d8:	00005617          	auipc	a2,0x5
ffffffffc02016dc:	b4060613          	addi	a2,a2,-1216 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02016e0:	14700593          	li	a1,327
ffffffffc02016e4:	00005517          	auipc	a0,0x5
ffffffffc02016e8:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0206230 <etext+0x9fc>
ffffffffc02016ec:	d5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016f0:	00005697          	auipc	a3,0x5
ffffffffc02016f4:	b5868693          	addi	a3,a3,-1192 # ffffffffc0206248 <etext+0xa14>
ffffffffc02016f8:	00005617          	auipc	a2,0x5
ffffffffc02016fc:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201700:	11300593          	li	a1,275
ffffffffc0201704:	00005517          	auipc	a0,0x5
ffffffffc0201708:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020170c:	d3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201710:	00005697          	auipc	a3,0x5
ffffffffc0201714:	b7868693          	addi	a3,a3,-1160 # ffffffffc0206288 <etext+0xa54>
ffffffffc0201718:	00005617          	auipc	a2,0x5
ffffffffc020171c:	b0060613          	addi	a2,a2,-1280 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201720:	0d800593          	li	a1,216
ffffffffc0201724:	00005517          	auipc	a0,0x5
ffffffffc0201728:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020172c:	d1bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201730 <default_free_pages>:
{
ffffffffc0201730:	1141                	addi	sp,sp,-16
ffffffffc0201732:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201734:	14058663          	beqz	a1,ffffffffc0201880 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201738:	00659713          	slli	a4,a1,0x6
ffffffffc020173c:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201740:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201742:	c30d                	beqz	a4,ffffffffc0201764 <default_free_pages+0x34>
ffffffffc0201744:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201746:	8b05                	andi	a4,a4,1
ffffffffc0201748:	10071c63          	bnez	a4,ffffffffc0201860 <default_free_pages+0x130>
ffffffffc020174c:	6798                	ld	a4,8(a5)
ffffffffc020174e:	8b09                	andi	a4,a4,2
ffffffffc0201750:	10071863          	bnez	a4,ffffffffc0201860 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201754:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201758:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020175c:	04078793          	addi	a5,a5,64
ffffffffc0201760:	fed792e3          	bne	a5,a3,ffffffffc0201744 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201764:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201766:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020176a:	4789                	li	a5,2
ffffffffc020176c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201770:	00096717          	auipc	a4,0x96
ffffffffc0201774:	de872703          	lw	a4,-536(a4) # ffffffffc0297558 <free_area+0x10>
ffffffffc0201778:	00096697          	auipc	a3,0x96
ffffffffc020177c:	dd068693          	addi	a3,a3,-560 # ffffffffc0297548 <free_area>
    return list->next == list;
ffffffffc0201780:	669c                	ld	a5,8(a3)
ffffffffc0201782:	9f2d                	addw	a4,a4,a1
ffffffffc0201784:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201786:	0ad78163          	beq	a5,a3,ffffffffc0201828 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc020178a:	fe878713          	addi	a4,a5,-24
ffffffffc020178e:	4581                	li	a1,0
ffffffffc0201790:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201794:	00e56a63          	bltu	a0,a4,ffffffffc02017a8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201798:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020179a:	04d70c63          	beq	a4,a3,ffffffffc02017f2 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020179e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017a0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201798 <default_free_pages+0x68>
ffffffffc02017a8:	c199                	beqz	a1,ffffffffc02017ae <default_free_pages+0x7e>
ffffffffc02017aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ae:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017b0:	e390                	sd	a2,0(a5)
ffffffffc02017b2:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02017b4:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017b6:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017b8:	00d70d63          	beq	a4,a3,ffffffffc02017d2 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017bc:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017c0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017c4:	02059813          	slli	a6,a1,0x20
ffffffffc02017c8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017cc:	97b2                	add	a5,a5,a2
ffffffffc02017ce:	02f50c63          	beq	a0,a5,ffffffffc0201806 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017d2:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017d4:	00d78c63          	beq	a5,a3,ffffffffc02017ec <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017d8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017da:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017de:	02061593          	slli	a1,a2,0x20
ffffffffc02017e2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017e6:	972a                	add	a4,a4,a0
ffffffffc02017e8:	04e68c63          	beq	a3,a4,ffffffffc0201840 <default_free_pages+0x110>
}
ffffffffc02017ec:	60a2                	ld	ra,8(sp)
ffffffffc02017ee:	0141                	addi	sp,sp,16
ffffffffc02017f0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017f4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017f6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017f8:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017fa:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02017fc:	02d70f63          	beq	a4,a3,ffffffffc020183a <default_free_pages+0x10a>
ffffffffc0201800:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201802:	87ba                	mv	a5,a4
ffffffffc0201804:	bf71                	j	ffffffffc02017a0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201806:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201808:	5875                	li	a6,-3
ffffffffc020180a:	9fad                	addw	a5,a5,a1
ffffffffc020180c:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201810:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201814:	01853803          	ld	a6,24(a0)
ffffffffc0201818:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020181a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020181c:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e50>
    return listelm->next;
ffffffffc0201820:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201822:	0105b023          	sd	a6,0(a1)
ffffffffc0201826:	b77d                	j	ffffffffc02017d4 <default_free_pages+0xa4>
}
ffffffffc0201828:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020182a:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020182e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201830:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201832:	e398                	sd	a4,0(a5)
ffffffffc0201834:	e798                	sd	a4,8(a5)
}
ffffffffc0201836:	0141                	addi	sp,sp,16
ffffffffc0201838:	8082                	ret
ffffffffc020183a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020183c:	873e                	mv	a4,a5
ffffffffc020183e:	bfad                	j	ffffffffc02017b8 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201840:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201844:	56f5                	li	a3,-3
ffffffffc0201846:	9f31                	addw	a4,a4,a2
ffffffffc0201848:	c918                	sw	a4,16(a0)
ffffffffc020184a:	ff078713          	addi	a4,a5,-16
ffffffffc020184e:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201852:	6398                	ld	a4,0(a5)
ffffffffc0201854:	679c                	ld	a5,8(a5)
}
ffffffffc0201856:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201858:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020185a:	e398                	sd	a4,0(a5)
ffffffffc020185c:	0141                	addi	sp,sp,16
ffffffffc020185e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201860:	00005697          	auipc	a3,0x5
ffffffffc0201864:	d1868693          	addi	a3,a3,-744 # ffffffffc0206578 <etext+0xd44>
ffffffffc0201868:	00005617          	auipc	a2,0x5
ffffffffc020186c:	9b060613          	addi	a2,a2,-1616 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201870:	09400593          	li	a1,148
ffffffffc0201874:	00005517          	auipc	a0,0x5
ffffffffc0201878:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020187c:	bcbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201880:	00005697          	auipc	a3,0x5
ffffffffc0201884:	cf068693          	addi	a3,a3,-784 # ffffffffc0206570 <etext+0xd3c>
ffffffffc0201888:	00005617          	auipc	a2,0x5
ffffffffc020188c:	99060613          	addi	a2,a2,-1648 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201890:	09000593          	li	a1,144
ffffffffc0201894:	00005517          	auipc	a0,0x5
ffffffffc0201898:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206230 <etext+0x9fc>
ffffffffc020189c:	babfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02018a0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a0:	c951                	beqz	a0,ffffffffc0201934 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018a2:	00096597          	auipc	a1,0x96
ffffffffc02018a6:	cb65a583          	lw	a1,-842(a1) # ffffffffc0297558 <free_area+0x10>
ffffffffc02018aa:	86aa                	mv	a3,a0
ffffffffc02018ac:	02059793          	slli	a5,a1,0x20
ffffffffc02018b0:	9381                	srli	a5,a5,0x20
ffffffffc02018b2:	00a7ef63          	bltu	a5,a0,ffffffffc02018d0 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02018b6:	00096617          	auipc	a2,0x96
ffffffffc02018ba:	c9260613          	addi	a2,a2,-878 # ffffffffc0297548 <free_area>
ffffffffc02018be:	87b2                	mv	a5,a2
ffffffffc02018c0:	a029                	j	ffffffffc02018ca <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018c2:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018c6:	00d77763          	bgeu	a4,a3,ffffffffc02018d4 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018ca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018cc:	fec79be3          	bne	a5,a2,ffffffffc02018c2 <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018d0:	4501                	li	a0,0
}
ffffffffc02018d2:	8082                	ret
        if (page->property > n)
ffffffffc02018d4:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018d8:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018dc:	6798                	ld	a4,8(a5)
ffffffffc02018de:	02089313          	slli	t1,a7,0x20
ffffffffc02018e2:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02018e6:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02018ea:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02018ee:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc02018f2:	0266fa63          	bgeu	a3,t1,ffffffffc0201926 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02018f6:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02018fa:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02018fe:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201900:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201904:	00870313          	addi	t1,a4,8
ffffffffc0201908:	4889                	li	a7,2
ffffffffc020190a:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020190e:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201912:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201916:	0068b023          	sd	t1,0(a7)
ffffffffc020191a:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020191e:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0201922:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201926:	9d95                	subw	a1,a1,a3
ffffffffc0201928:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020192a:	5775                	li	a4,-3
ffffffffc020192c:	17c1                	addi	a5,a5,-16
ffffffffc020192e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201932:	8082                	ret
{
ffffffffc0201934:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201936:	00005697          	auipc	a3,0x5
ffffffffc020193a:	c3a68693          	addi	a3,a3,-966 # ffffffffc0206570 <etext+0xd3c>
ffffffffc020193e:	00005617          	auipc	a2,0x5
ffffffffc0201942:	8da60613          	addi	a2,a2,-1830 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201946:	06c00593          	li	a1,108
ffffffffc020194a:	00005517          	auipc	a0,0x5
ffffffffc020194e:	8e650513          	addi	a0,a0,-1818 # ffffffffc0206230 <etext+0x9fc>
{
ffffffffc0201952:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201954:	af3fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201958 <default_init_memmap>:
{
ffffffffc0201958:	1141                	addi	sp,sp,-16
ffffffffc020195a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020195c:	c9e1                	beqz	a1,ffffffffc0201a2c <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc020195e:	00659713          	slli	a4,a1,0x6
ffffffffc0201962:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201966:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201968:	cf11                	beqz	a4,ffffffffc0201984 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020196a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020196c:	8b05                	andi	a4,a4,1
ffffffffc020196e:	cf59                	beqz	a4,ffffffffc0201a0c <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201970:	0007a823          	sw	zero,16(a5)
ffffffffc0201974:	0007b423          	sd	zero,8(a5)
ffffffffc0201978:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020197c:	04078793          	addi	a5,a5,64
ffffffffc0201980:	fed795e3          	bne	a5,a3,ffffffffc020196a <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201984:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201986:	4789                	li	a5,2
ffffffffc0201988:	00850713          	addi	a4,a0,8
ffffffffc020198c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201990:	00096717          	auipc	a4,0x96
ffffffffc0201994:	bc872703          	lw	a4,-1080(a4) # ffffffffc0297558 <free_area+0x10>
ffffffffc0201998:	00096697          	auipc	a3,0x96
ffffffffc020199c:	bb068693          	addi	a3,a3,-1104 # ffffffffc0297548 <free_area>
    return list->next == list;
ffffffffc02019a0:	669c                	ld	a5,8(a3)
ffffffffc02019a2:	9f2d                	addw	a4,a4,a1
ffffffffc02019a4:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02019a6:	04d78663          	beq	a5,a3,ffffffffc02019f2 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02019aa:	fe878713          	addi	a4,a5,-24
ffffffffc02019ae:	4581                	li	a1,0
ffffffffc02019b0:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02019b4:	00e56a63          	bltu	a0,a4,ffffffffc02019c8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019b8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019ba:	02d70263          	beq	a4,a3,ffffffffc02019de <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019be:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019c4:	fee57ae3          	bgeu	a0,a4,ffffffffc02019b8 <default_init_memmap+0x60>
ffffffffc02019c8:	c199                	beqz	a1,ffffffffc02019ce <default_init_memmap+0x76>
ffffffffc02019ca:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019ce:	6398                	ld	a4,0(a5)
}
ffffffffc02019d0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019d2:	e390                	sd	a2,0(a5)
ffffffffc02019d4:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019d6:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019d8:	f11c                	sd	a5,32(a0)
ffffffffc02019da:	0141                	addi	sp,sp,16
ffffffffc02019dc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019de:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019e2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019e4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02019e6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02019e8:	00d70e63          	beq	a4,a3,ffffffffc0201a04 <default_init_memmap+0xac>
ffffffffc02019ec:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02019ee:	87ba                	mv	a5,a4
ffffffffc02019f0:	bfc1                	j	ffffffffc02019c0 <default_init_memmap+0x68>
}
ffffffffc02019f2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02019f4:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02019f8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019fa:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02019fc:	e398                	sd	a4,0(a5)
ffffffffc02019fe:	e798                	sd	a4,8(a5)
}
ffffffffc0201a00:	0141                	addi	sp,sp,16
ffffffffc0201a02:	8082                	ret
ffffffffc0201a04:	60a2                	ld	ra,8(sp)
ffffffffc0201a06:	e290                	sd	a2,0(a3)
ffffffffc0201a08:	0141                	addi	sp,sp,16
ffffffffc0201a0a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a0c:	00005697          	auipc	a3,0x5
ffffffffc0201a10:	b9468693          	addi	a3,a3,-1132 # ffffffffc02065a0 <etext+0xd6c>
ffffffffc0201a14:	00005617          	auipc	a2,0x5
ffffffffc0201a18:	80460613          	addi	a2,a2,-2044 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201a1c:	04b00593          	li	a1,75
ffffffffc0201a20:	00005517          	auipc	a0,0x5
ffffffffc0201a24:	81050513          	addi	a0,a0,-2032 # ffffffffc0206230 <etext+0x9fc>
ffffffffc0201a28:	a1ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a2c:	00005697          	auipc	a3,0x5
ffffffffc0201a30:	b4468693          	addi	a3,a3,-1212 # ffffffffc0206570 <etext+0xd3c>
ffffffffc0201a34:	00004617          	auipc	a2,0x4
ffffffffc0201a38:	7e460613          	addi	a2,a2,2020 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201a3c:	04700593          	li	a1,71
ffffffffc0201a40:	00004517          	auipc	a0,0x4
ffffffffc0201a44:	7f050513          	addi	a0,a0,2032 # ffffffffc0206230 <etext+0x9fc>
ffffffffc0201a48:	9fffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a4c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a4c:	c531                	beqz	a0,ffffffffc0201a98 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a4e:	e9b9                	bnez	a1,ffffffffc0201aa4 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a50:	100027f3          	csrr	a5,sstatus
ffffffffc0201a54:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a56:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	efb1                	bnez	a5,ffffffffc0201ab4 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a5a:	00095797          	auipc	a5,0x95
ffffffffc0201a5e:	6de7b783          	ld	a5,1758(a5) # ffffffffc0297138 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a62:	873e                	mv	a4,a5
ffffffffc0201a64:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a66:	02a77a63          	bgeu	a4,a0,ffffffffc0201a9a <slob_free+0x4e>
ffffffffc0201a6a:	00f56463          	bltu	a0,a5,ffffffffc0201a72 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a6e:	fef76ae3          	bltu	a4,a5,ffffffffc0201a62 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a72:	4110                	lw	a2,0(a0)
ffffffffc0201a74:	00461693          	slli	a3,a2,0x4
ffffffffc0201a78:	96aa                	add	a3,a3,a0
ffffffffc0201a7a:	0ad78463          	beq	a5,a3,ffffffffc0201b22 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a7e:	4310                	lw	a2,0(a4)
ffffffffc0201a80:	e51c                	sd	a5,8(a0)
ffffffffc0201a82:	00461693          	slli	a3,a2,0x4
ffffffffc0201a86:	96ba                	add	a3,a3,a4
ffffffffc0201a88:	08d50163          	beq	a0,a3,ffffffffc0201b0a <slob_free+0xbe>
ffffffffc0201a8c:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a8e:	00095797          	auipc	a5,0x95
ffffffffc0201a92:	6ae7b523          	sd	a4,1706(a5) # ffffffffc0297138 <slobfree>
    if (flag)
ffffffffc0201a96:	e9a5                	bnez	a1,ffffffffc0201b06 <slob_free+0xba>
ffffffffc0201a98:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a9a:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201a9e:	fcf762e3          	bltu	a4,a5,ffffffffc0201a62 <slob_free+0x16>
ffffffffc0201aa2:	bfc1                	j	ffffffffc0201a72 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201aa4:	25bd                	addiw	a1,a1,15
ffffffffc0201aa6:	8191                	srli	a1,a1,0x4
ffffffffc0201aa8:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aaa:	100027f3          	csrr	a5,sstatus
ffffffffc0201aae:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ab0:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab2:	d7c5                	beqz	a5,ffffffffc0201a5a <slob_free+0xe>
{
ffffffffc0201ab4:	1101                	addi	sp,sp,-32
ffffffffc0201ab6:	e42a                	sd	a0,8(sp)
ffffffffc0201ab8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201aba:	e4bfe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201abe:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ac0:	00095797          	auipc	a5,0x95
ffffffffc0201ac4:	6787b783          	ld	a5,1656(a5) # ffffffffc0297138 <slobfree>
ffffffffc0201ac8:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aca:	873e                	mv	a4,a5
ffffffffc0201acc:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ace:	06a77663          	bgeu	a4,a0,ffffffffc0201b3a <slob_free+0xee>
ffffffffc0201ad2:	00f56463          	bltu	a0,a5,ffffffffc0201ada <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ad6:	fef76ae3          	bltu	a4,a5,ffffffffc0201aca <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201ada:	4110                	lw	a2,0(a0)
ffffffffc0201adc:	00461693          	slli	a3,a2,0x4
ffffffffc0201ae0:	96aa                	add	a3,a3,a0
ffffffffc0201ae2:	06d78363          	beq	a5,a3,ffffffffc0201b48 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201ae6:	4310                	lw	a2,0(a4)
ffffffffc0201ae8:	e51c                	sd	a5,8(a0)
ffffffffc0201aea:	00461693          	slli	a3,a2,0x4
ffffffffc0201aee:	96ba                	add	a3,a3,a4
ffffffffc0201af0:	06d50163          	beq	a0,a3,ffffffffc0201b52 <slob_free+0x106>
ffffffffc0201af4:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201af6:	00095797          	auipc	a5,0x95
ffffffffc0201afa:	64e7b123          	sd	a4,1602(a5) # ffffffffc0297138 <slobfree>
    if (flag)
ffffffffc0201afe:	e1a9                	bnez	a1,ffffffffc0201b40 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b00:	60e2                	ld	ra,24(sp)
ffffffffc0201b02:	6105                	addi	sp,sp,32
ffffffffc0201b04:	8082                	ret
        intr_enable();
ffffffffc0201b06:	df9fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b0a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b0c:	853e                	mv	a0,a5
ffffffffc0201b0e:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b10:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b14:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b16:	00095797          	auipc	a5,0x95
ffffffffc0201b1a:	62e7b123          	sd	a4,1570(a5) # ffffffffc0297138 <slobfree>
    if (flag)
ffffffffc0201b1e:	ddad                	beqz	a1,ffffffffc0201a98 <slob_free+0x4c>
ffffffffc0201b20:	b7dd                	j	ffffffffc0201b06 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b22:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b24:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b26:	9eb1                	addw	a3,a3,a2
ffffffffc0201b28:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b2a:	4310                	lw	a2,0(a4)
ffffffffc0201b2c:	e51c                	sd	a5,8(a0)
ffffffffc0201b2e:	00461693          	slli	a3,a2,0x4
ffffffffc0201b32:	96ba                	add	a3,a3,a4
ffffffffc0201b34:	f4d51ce3          	bne	a0,a3,ffffffffc0201a8c <slob_free+0x40>
ffffffffc0201b38:	bfc9                	j	ffffffffc0201b0a <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b3a:	f8f56ee3          	bltu	a0,a5,ffffffffc0201ad6 <slob_free+0x8a>
ffffffffc0201b3e:	b771                	j	ffffffffc0201aca <slob_free+0x7e>
}
ffffffffc0201b40:	60e2                	ld	ra,24(sp)
ffffffffc0201b42:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b44:	dbbfe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b48:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b4a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b4c:	9eb1                	addw	a3,a3,a2
ffffffffc0201b4e:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b50:	bf59                	j	ffffffffc0201ae6 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b52:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b54:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b56:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b5a:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b5c:	bf61                	j	ffffffffc0201af4 <slob_free+0xa8>

ffffffffc0201b5e <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b5e:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b60:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b62:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b66:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b68:	32a000ef          	jal	ffffffffc0201e92 <alloc_pages>
	if (!page)
ffffffffc0201b6c:	c91d                	beqz	a0,ffffffffc0201ba2 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b6e:	0009a697          	auipc	a3,0x9a
ffffffffc0201b72:	a5a6b683          	ld	a3,-1446(a3) # ffffffffc029b5c8 <pages>
ffffffffc0201b76:	00006797          	auipc	a5,0x6
ffffffffc0201b7a:	e0a7b783          	ld	a5,-502(a5) # ffffffffc0207980 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b7e:	0009a717          	auipc	a4,0x9a
ffffffffc0201b82:	a4273703          	ld	a4,-1470(a4) # ffffffffc029b5c0 <npage>
    return page - pages + nbase;
ffffffffc0201b86:	8d15                	sub	a0,a0,a3
ffffffffc0201b88:	8519                	srai	a0,a0,0x6
ffffffffc0201b8a:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b8c:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b90:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b92:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b94:	00e7fa63          	bgeu	a5,a4,ffffffffc0201ba8 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b98:	0009a797          	auipc	a5,0x9a
ffffffffc0201b9c:	a207b783          	ld	a5,-1504(a5) # ffffffffc029b5b8 <va_pa_offset>
ffffffffc0201ba0:	953e                	add	a0,a0,a5
}
ffffffffc0201ba2:	60a2                	ld	ra,8(sp)
ffffffffc0201ba4:	0141                	addi	sp,sp,16
ffffffffc0201ba6:	8082                	ret
ffffffffc0201ba8:	86aa                	mv	a3,a0
ffffffffc0201baa:	00005617          	auipc	a2,0x5
ffffffffc0201bae:	a1e60613          	addi	a2,a2,-1506 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0201bb2:	07100593          	li	a1,113
ffffffffc0201bb6:	00005517          	auipc	a0,0x5
ffffffffc0201bba:	a3a50513          	addi	a0,a0,-1478 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0201bbe:	889fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bc2 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bc2:	7179                	addi	sp,sp,-48
ffffffffc0201bc4:	f406                	sd	ra,40(sp)
ffffffffc0201bc6:	f022                	sd	s0,32(sp)
ffffffffc0201bc8:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bca:	01050713          	addi	a4,a0,16
ffffffffc0201bce:	6785                	lui	a5,0x1
ffffffffc0201bd0:	0af77e63          	bgeu	a4,a5,ffffffffc0201c8c <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bd4:	00f50413          	addi	s0,a0,15
ffffffffc0201bd8:	8011                	srli	s0,s0,0x4
ffffffffc0201bda:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bdc:	100025f3          	csrr	a1,sstatus
ffffffffc0201be0:	8989                	andi	a1,a1,2
ffffffffc0201be2:	edd1                	bnez	a1,ffffffffc0201c7e <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201be4:	00095497          	auipc	s1,0x95
ffffffffc0201be8:	55448493          	addi	s1,s1,1364 # ffffffffc0297138 <slobfree>
ffffffffc0201bec:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bee:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201bf0:	4314                	lw	a3,0(a4)
ffffffffc0201bf2:	0886da63          	bge	a3,s0,ffffffffc0201c86 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201bf6:	00e60a63          	beq	a2,a4,ffffffffc0201c0a <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bfa:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201bfc:	4394                	lw	a3,0(a5)
ffffffffc0201bfe:	0286d863          	bge	a3,s0,ffffffffc0201c2e <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c02:	6090                	ld	a2,0(s1)
ffffffffc0201c04:	873e                	mv	a4,a5
ffffffffc0201c06:	fee61ae3          	bne	a2,a4,ffffffffc0201bfa <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c0a:	e9b1                	bnez	a1,ffffffffc0201c5e <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c0c:	4501                	li	a0,0
ffffffffc0201c0e:	f51ff0ef          	jal	ffffffffc0201b5e <__slob_get_free_pages.constprop.0>
ffffffffc0201c12:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c14:	c915                	beqz	a0,ffffffffc0201c48 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c16:	6585                	lui	a1,0x1
ffffffffc0201c18:	e35ff0ef          	jal	ffffffffc0201a4c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c1c:	100025f3          	csrr	a1,sstatus
ffffffffc0201c20:	8989                	andi	a1,a1,2
ffffffffc0201c22:	e98d                	bnez	a1,ffffffffc0201c54 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c24:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c26:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c28:	4394                	lw	a3,0(a5)
ffffffffc0201c2a:	fc86cce3          	blt	a3,s0,ffffffffc0201c02 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c2e:	04d40563          	beq	s0,a3,ffffffffc0201c78 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c32:	00441613          	slli	a2,s0,0x4
ffffffffc0201c36:	963e                	add	a2,a2,a5
ffffffffc0201c38:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c3a:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c3c:	9e81                	subw	a3,a3,s0
ffffffffc0201c3e:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c40:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c42:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c44:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c46:	ed99                	bnez	a1,ffffffffc0201c64 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c48:	70a2                	ld	ra,40(sp)
ffffffffc0201c4a:	7402                	ld	s0,32(sp)
ffffffffc0201c4c:	64e2                	ld	s1,24(sp)
ffffffffc0201c4e:	853e                	mv	a0,a5
ffffffffc0201c50:	6145                	addi	sp,sp,48
ffffffffc0201c52:	8082                	ret
        intr_disable();
ffffffffc0201c54:	cb1fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c58:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c5a:	4585                	li	a1,1
ffffffffc0201c5c:	b7e9                	j	ffffffffc0201c26 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c5e:	ca1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c62:	b76d                	j	ffffffffc0201c0c <slob_alloc.constprop.0+0x4a>
ffffffffc0201c64:	e43e                	sd	a5,8(sp)
ffffffffc0201c66:	c99fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c6a:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c6c:	70a2                	ld	ra,40(sp)
ffffffffc0201c6e:	7402                	ld	s0,32(sp)
ffffffffc0201c70:	64e2                	ld	s1,24(sp)
ffffffffc0201c72:	853e                	mv	a0,a5
ffffffffc0201c74:	6145                	addi	sp,sp,48
ffffffffc0201c76:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c78:	6794                	ld	a3,8(a5)
ffffffffc0201c7a:	e714                	sd	a3,8(a4)
ffffffffc0201c7c:	b7e1                	j	ffffffffc0201c44 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c7e:	c87fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c82:	4585                	li	a1,1
ffffffffc0201c84:	b785                	j	ffffffffc0201be4 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c86:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c88:	8732                	mv	a4,a2
ffffffffc0201c8a:	b755                	j	ffffffffc0201c2e <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c8c:	00005697          	auipc	a3,0x5
ffffffffc0201c90:	97468693          	addi	a3,a3,-1676 # ffffffffc0206600 <etext+0xdcc>
ffffffffc0201c94:	00004617          	auipc	a2,0x4
ffffffffc0201c98:	58460613          	addi	a2,a2,1412 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0201c9c:	06300593          	li	a1,99
ffffffffc0201ca0:	00005517          	auipc	a0,0x5
ffffffffc0201ca4:	98050513          	addi	a0,a0,-1664 # ffffffffc0206620 <etext+0xdec>
ffffffffc0201ca8:	f9efe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201cac <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cac:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cae:	00005517          	auipc	a0,0x5
ffffffffc0201cb2:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206638 <etext+0xe04>
{
ffffffffc0201cb6:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cb8:	cdcfe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cbc:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cbe:	00005517          	auipc	a0,0x5
ffffffffc0201cc2:	99250513          	addi	a0,a0,-1646 # ffffffffc0206650 <etext+0xe1c>
}
ffffffffc0201cc6:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cc8:	cccfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ccc <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201ccc:	4501                	li	a0,0
ffffffffc0201cce:	8082                	ret

ffffffffc0201cd0 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cd0:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cd2:	6685                	lui	a3,0x1
{
ffffffffc0201cd4:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cd6:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7bc1>
ffffffffc0201cd8:	04a6f963          	bgeu	a3,a0,ffffffffc0201d2a <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cdc:	e42a                	sd	a0,8(sp)
ffffffffc0201cde:	4561                	li	a0,24
ffffffffc0201ce0:	e822                	sd	s0,16(sp)
ffffffffc0201ce2:	ee1ff0ef          	jal	ffffffffc0201bc2 <slob_alloc.constprop.0>
ffffffffc0201ce6:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ce8:	c541                	beqz	a0,ffffffffc0201d70 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201cea:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201cec:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201cee:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cf0:	00f75763          	bge	a4,a5,ffffffffc0201cfe <kmalloc+0x2e>
ffffffffc0201cf4:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201cf8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cfa:	fef74de3          	blt	a4,a5,ffffffffc0201cf4 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201cfe:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d00:	e5fff0ef          	jal	ffffffffc0201b5e <__slob_get_free_pages.constprop.0>
ffffffffc0201d04:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d06:	cd31                	beqz	a0,ffffffffc0201d62 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d08:	100027f3          	csrr	a5,sstatus
ffffffffc0201d0c:	8b89                	andi	a5,a5,2
ffffffffc0201d0e:	eb85                	bnez	a5,ffffffffc0201d3e <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d10:	0009a797          	auipc	a5,0x9a
ffffffffc0201d14:	8887b783          	ld	a5,-1912(a5) # ffffffffc029b598 <bigblocks>
		bigblocks = bb;
ffffffffc0201d18:	0009a717          	auipc	a4,0x9a
ffffffffc0201d1c:	88873023          	sd	s0,-1920(a4) # ffffffffc029b598 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d20:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d22:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d24:	60e2                	ld	ra,24(sp)
ffffffffc0201d26:	6105                	addi	sp,sp,32
ffffffffc0201d28:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d2a:	0541                	addi	a0,a0,16
ffffffffc0201d2c:	e97ff0ef          	jal	ffffffffc0201bc2 <slob_alloc.constprop.0>
ffffffffc0201d30:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d32:	0541                	addi	a0,a0,16
ffffffffc0201d34:	fbe5                	bnez	a5,ffffffffc0201d24 <kmalloc+0x54>
		return 0;
ffffffffc0201d36:	4501                	li	a0,0
}
ffffffffc0201d38:	60e2                	ld	ra,24(sp)
ffffffffc0201d3a:	6105                	addi	sp,sp,32
ffffffffc0201d3c:	8082                	ret
        intr_disable();
ffffffffc0201d3e:	bc7fe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d42:	0009a797          	auipc	a5,0x9a
ffffffffc0201d46:	8567b783          	ld	a5,-1962(a5) # ffffffffc029b598 <bigblocks>
		bigblocks = bb;
ffffffffc0201d4a:	0009a717          	auipc	a4,0x9a
ffffffffc0201d4e:	84873723          	sd	s0,-1970(a4) # ffffffffc029b598 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d52:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d54:	babfe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d58:	6408                	ld	a0,8(s0)
}
ffffffffc0201d5a:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d5c:	6442                	ld	s0,16(sp)
}
ffffffffc0201d5e:	6105                	addi	sp,sp,32
ffffffffc0201d60:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d62:	8522                	mv	a0,s0
ffffffffc0201d64:	45e1                	li	a1,24
ffffffffc0201d66:	ce7ff0ef          	jal	ffffffffc0201a4c <slob_free>
		return 0;
ffffffffc0201d6a:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d6c:	6442                	ld	s0,16(sp)
ffffffffc0201d6e:	b7e9                	j	ffffffffc0201d38 <kmalloc+0x68>
ffffffffc0201d70:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d72:	4501                	li	a0,0
ffffffffc0201d74:	b7d1                	j	ffffffffc0201d38 <kmalloc+0x68>

ffffffffc0201d76 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d76:	c571                	beqz	a0,ffffffffc0201e42 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d78:	03451793          	slli	a5,a0,0x34
ffffffffc0201d7c:	e3e1                	bnez	a5,ffffffffc0201e3c <kfree+0xc6>
{
ffffffffc0201d7e:	1101                	addi	sp,sp,-32
ffffffffc0201d80:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d82:	100027f3          	csrr	a5,sstatus
ffffffffc0201d86:	8b89                	andi	a5,a5,2
ffffffffc0201d88:	e7c1                	bnez	a5,ffffffffc0201e10 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d8a:	0009a797          	auipc	a5,0x9a
ffffffffc0201d8e:	80e7b783          	ld	a5,-2034(a5) # ffffffffc029b598 <bigblocks>
    return 0;
ffffffffc0201d92:	4581                	li	a1,0
ffffffffc0201d94:	cbad                	beqz	a5,ffffffffc0201e06 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d96:	0009a617          	auipc	a2,0x9a
ffffffffc0201d9a:	80260613          	addi	a2,a2,-2046 # ffffffffc029b598 <bigblocks>
ffffffffc0201d9e:	a021                	j	ffffffffc0201da6 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201da0:	01070613          	addi	a2,a4,16
ffffffffc0201da4:	c3a5                	beqz	a5,ffffffffc0201e04 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201da6:	6794                	ld	a3,8(a5)
ffffffffc0201da8:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201daa:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201dac:	fea69ae3          	bne	a3,a0,ffffffffc0201da0 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201db0:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201db2:	edb5                	bnez	a1,ffffffffc0201e2e <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201db4:	c02007b7          	lui	a5,0xc0200
ffffffffc0201db8:	0af56263          	bltu	a0,a5,ffffffffc0201e5c <kfree+0xe6>
ffffffffc0201dbc:	00099797          	auipc	a5,0x99
ffffffffc0201dc0:	7fc7b783          	ld	a5,2044(a5) # ffffffffc029b5b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201dc4:	00099697          	auipc	a3,0x99
ffffffffc0201dc8:	7fc6b683          	ld	a3,2044(a3) # ffffffffc029b5c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201dcc:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201dce:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dd2:	06d7f963          	bgeu	a5,a3,ffffffffc0201e44 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dd6:	00006617          	auipc	a2,0x6
ffffffffc0201dda:	baa63603          	ld	a2,-1110(a2) # ffffffffc0207980 <nbase>
ffffffffc0201dde:	00099517          	auipc	a0,0x99
ffffffffc0201de2:	7ea53503          	ld	a0,2026(a0) # ffffffffc029b5c8 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201de6:	4314                	lw	a3,0(a4)
ffffffffc0201de8:	8f91                	sub	a5,a5,a2
ffffffffc0201dea:	079a                	slli	a5,a5,0x6
ffffffffc0201dec:	4585                	li	a1,1
ffffffffc0201dee:	953e                	add	a0,a0,a5
ffffffffc0201df0:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201df4:	e03a                	sd	a4,0(sp)
ffffffffc0201df6:	0d6000ef          	jal	ffffffffc0201ecc <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dfa:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201dfc:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dfe:	45e1                	li	a1,24
}
ffffffffc0201e00:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e02:	b1a9                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201e04:	e185                	bnez	a1,ffffffffc0201e24 <kfree+0xae>
}
ffffffffc0201e06:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e08:	1541                	addi	a0,a0,-16
ffffffffc0201e0a:	4581                	li	a1,0
}
ffffffffc0201e0c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e0e:	b93d                	j	ffffffffc0201a4c <slob_free>
        intr_disable();
ffffffffc0201e10:	e02a                	sd	a0,0(sp)
ffffffffc0201e12:	af3fe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e16:	00099797          	auipc	a5,0x99
ffffffffc0201e1a:	7827b783          	ld	a5,1922(a5) # ffffffffc029b598 <bigblocks>
ffffffffc0201e1e:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e20:	4585                	li	a1,1
ffffffffc0201e22:	fbb5                	bnez	a5,ffffffffc0201d96 <kfree+0x20>
ffffffffc0201e24:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e26:	ad9fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e2a:	6502                	ld	a0,0(sp)
ffffffffc0201e2c:	bfe9                	j	ffffffffc0201e06 <kfree+0x90>
ffffffffc0201e2e:	e42a                	sd	a0,8(sp)
ffffffffc0201e30:	e03a                	sd	a4,0(sp)
ffffffffc0201e32:	acdfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e36:	6522                	ld	a0,8(sp)
ffffffffc0201e38:	6702                	ld	a4,0(sp)
ffffffffc0201e3a:	bfad                	j	ffffffffc0201db4 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e3c:	1541                	addi	a0,a0,-16
ffffffffc0201e3e:	4581                	li	a1,0
ffffffffc0201e40:	b131                	j	ffffffffc0201a4c <slob_free>
ffffffffc0201e42:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e44:	00005617          	auipc	a2,0x5
ffffffffc0201e48:	85460613          	addi	a2,a2,-1964 # ffffffffc0206698 <etext+0xe64>
ffffffffc0201e4c:	06900593          	li	a1,105
ffffffffc0201e50:	00004517          	auipc	a0,0x4
ffffffffc0201e54:	7a050513          	addi	a0,a0,1952 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0201e58:	deefe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e5c:	86aa                	mv	a3,a0
ffffffffc0201e5e:	00005617          	auipc	a2,0x5
ffffffffc0201e62:	81260613          	addi	a2,a2,-2030 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0201e66:	07700593          	li	a1,119
ffffffffc0201e6a:	00004517          	auipc	a0,0x4
ffffffffc0201e6e:	78650513          	addi	a0,a0,1926 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0201e72:	dd4fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e76 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e76:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e78:	00005617          	auipc	a2,0x5
ffffffffc0201e7c:	82060613          	addi	a2,a2,-2016 # ffffffffc0206698 <etext+0xe64>
ffffffffc0201e80:	06900593          	li	a1,105
ffffffffc0201e84:	00004517          	auipc	a0,0x4
ffffffffc0201e88:	76c50513          	addi	a0,a0,1900 # ffffffffc02065f0 <etext+0xdbc>
pa2page(uintptr_t pa)
ffffffffc0201e8c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e8e:	db8fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e92 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e92:	100027f3          	csrr	a5,sstatus
ffffffffc0201e96:	8b89                	andi	a5,a5,2
ffffffffc0201e98:	e799                	bnez	a5,ffffffffc0201ea6 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e9a:	00099797          	auipc	a5,0x99
ffffffffc0201e9e:	7067b783          	ld	a5,1798(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201ea2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea4:	8782                	jr	a5
{
ffffffffc0201ea6:	1101                	addi	sp,sp,-32
ffffffffc0201ea8:	ec06                	sd	ra,24(sp)
ffffffffc0201eaa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201eac:	a59fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb0:	00099797          	auipc	a5,0x99
ffffffffc0201eb4:	6f07b783          	ld	a5,1776(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201eb8:	6522                	ld	a0,8(sp)
ffffffffc0201eba:	6f9c                	ld	a5,24(a5)
ffffffffc0201ebc:	9782                	jalr	a5
ffffffffc0201ebe:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ec0:	a3ffe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ec4:	60e2                	ld	ra,24(sp)
ffffffffc0201ec6:	6522                	ld	a0,8(sp)
ffffffffc0201ec8:	6105                	addi	sp,sp,32
ffffffffc0201eca:	8082                	ret

ffffffffc0201ecc <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ecc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed0:	8b89                	andi	a5,a5,2
ffffffffc0201ed2:	e799                	bnez	a5,ffffffffc0201ee0 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ed4:	00099797          	auipc	a5,0x99
ffffffffc0201ed8:	6cc7b783          	ld	a5,1740(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201edc:	739c                	ld	a5,32(a5)
ffffffffc0201ede:	8782                	jr	a5
{
ffffffffc0201ee0:	1101                	addi	sp,sp,-32
ffffffffc0201ee2:	ec06                	sd	ra,24(sp)
ffffffffc0201ee4:	e42e                	sd	a1,8(sp)
ffffffffc0201ee6:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201ee8:	a1dfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201eec:	00099797          	auipc	a5,0x99
ffffffffc0201ef0:	6b47b783          	ld	a5,1716(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201ef4:	65a2                	ld	a1,8(sp)
ffffffffc0201ef6:	6502                	ld	a0,0(sp)
ffffffffc0201ef8:	739c                	ld	a5,32(a5)
ffffffffc0201efa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201efc:	60e2                	ld	ra,24(sp)
ffffffffc0201efe:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f00:	9fffe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f04 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f04:	100027f3          	csrr	a5,sstatus
ffffffffc0201f08:	8b89                	andi	a5,a5,2
ffffffffc0201f0a:	e799                	bnez	a5,ffffffffc0201f18 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f0c:	00099797          	auipc	a5,0x99
ffffffffc0201f10:	6947b783          	ld	a5,1684(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201f14:	779c                	ld	a5,40(a5)
ffffffffc0201f16:	8782                	jr	a5
{
ffffffffc0201f18:	1101                	addi	sp,sp,-32
ffffffffc0201f1a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f1c:	9e9fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f20:	00099797          	auipc	a5,0x99
ffffffffc0201f24:	6807b783          	ld	a5,1664(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201f28:	779c                	ld	a5,40(a5)
ffffffffc0201f2a:	9782                	jalr	a5
ffffffffc0201f2c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f2e:	9d1fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f32:	60e2                	ld	ra,24(sp)
ffffffffc0201f34:	6522                	ld	a0,8(sp)
ffffffffc0201f36:	6105                	addi	sp,sp,32
ffffffffc0201f38:	8082                	ret

ffffffffc0201f3a <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3a:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f3e:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f42:	078e                	slli	a5,a5,0x3
ffffffffc0201f44:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f48:	6314                	ld	a3,0(a4)
{
ffffffffc0201f4a:	7139                	addi	sp,sp,-64
ffffffffc0201f4c:	f822                	sd	s0,48(sp)
ffffffffc0201f4e:	f426                	sd	s1,40(sp)
ffffffffc0201f50:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f52:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f56:	842e                	mv	s0,a1
ffffffffc0201f58:	8832                	mv	a6,a2
ffffffffc0201f5a:	00099497          	auipc	s1,0x99
ffffffffc0201f5e:	66648493          	addi	s1,s1,1638 # ffffffffc029b5c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f62:	ebd1                	bnez	a5,ffffffffc0201ff6 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f64:	16060d63          	beqz	a2,ffffffffc02020de <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f68:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6c:	8b89                	andi	a5,a5,2
ffffffffc0201f6e:	16079e63          	bnez	a5,ffffffffc02020ea <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f72:	00099797          	auipc	a5,0x99
ffffffffc0201f76:	62e7b783          	ld	a5,1582(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0201f7a:	4505                	li	a0,1
ffffffffc0201f7c:	e43a                	sd	a4,8(sp)
ffffffffc0201f7e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f80:	e832                	sd	a2,16(sp)
ffffffffc0201f82:	9782                	jalr	a5
ffffffffc0201f84:	6722                	ld	a4,8(sp)
ffffffffc0201f86:	6842                	ld	a6,16(sp)
ffffffffc0201f88:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f8a:	14078a63          	beqz	a5,ffffffffc02020de <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f8e:	00099517          	auipc	a0,0x99
ffffffffc0201f92:	63a53503          	ld	a0,1594(a0) # ffffffffc029b5c8 <pages>
ffffffffc0201f96:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f9a:	00099497          	auipc	s1,0x99
ffffffffc0201f9e:	62648493          	addi	s1,s1,1574 # ffffffffc029b5c0 <npage>
ffffffffc0201fa2:	40a78533          	sub	a0,a5,a0
ffffffffc0201fa6:	8519                	srai	a0,a0,0x6
ffffffffc0201fa8:	9546                	add	a0,a0,a7
ffffffffc0201faa:	6090                	ld	a2,0(s1)
ffffffffc0201fac:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201fb0:	4585                	li	a1,1
ffffffffc0201fb2:	82b1                	srli	a3,a3,0xc
ffffffffc0201fb4:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fb6:	0532                	slli	a0,a0,0xc
ffffffffc0201fb8:	1ac6f763          	bgeu	a3,a2,ffffffffc0202166 <get_pte+0x22c>
ffffffffc0201fbc:	00099697          	auipc	a3,0x99
ffffffffc0201fc0:	5fc6b683          	ld	a3,1532(a3) # ffffffffc029b5b8 <va_pa_offset>
ffffffffc0201fc4:	6605                	lui	a2,0x1
ffffffffc0201fc6:	4581                	li	a1,0
ffffffffc0201fc8:	9536                	add	a0,a0,a3
ffffffffc0201fca:	ec42                	sd	a6,24(sp)
ffffffffc0201fcc:	e83e                	sd	a5,16(sp)
ffffffffc0201fce:	e43a                	sd	a4,8(sp)
ffffffffc0201fd0:	03b030ef          	jal	ffffffffc020580a <memset>
    return page - pages + nbase;
ffffffffc0201fd4:	00099697          	auipc	a3,0x99
ffffffffc0201fd8:	5f46b683          	ld	a3,1524(a3) # ffffffffc029b5c8 <pages>
ffffffffc0201fdc:	67c2                	ld	a5,16(sp)
ffffffffc0201fde:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fe2:	6722                	ld	a4,8(sp)
ffffffffc0201fe4:	40d786b3          	sub	a3,a5,a3
ffffffffc0201fe8:	8699                	srai	a3,a3,0x6
ffffffffc0201fea:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fec:	06aa                	slli	a3,a3,0xa
ffffffffc0201fee:	6862                	ld	a6,24(sp)
ffffffffc0201ff0:	0116e693          	ori	a3,a3,17
ffffffffc0201ff4:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ff6:	c006f693          	andi	a3,a3,-1024
ffffffffc0201ffa:	6098                	ld	a4,0(s1)
ffffffffc0201ffc:	068a                	slli	a3,a3,0x2
ffffffffc0201ffe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202002:	14e7f663          	bgeu	a5,a4,ffffffffc020214e <get_pte+0x214>
ffffffffc0202006:	00099897          	auipc	a7,0x99
ffffffffc020200a:	5b288893          	addi	a7,a7,1458 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc020200e:	0008b603          	ld	a2,0(a7)
ffffffffc0202012:	01545793          	srli	a5,s0,0x15
ffffffffc0202016:	1ff7f793          	andi	a5,a5,511
ffffffffc020201a:	96b2                	add	a3,a3,a2
ffffffffc020201c:	078e                	slli	a5,a5,0x3
ffffffffc020201e:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202020:	6394                	ld	a3,0(a5)
ffffffffc0202022:	0016f613          	andi	a2,a3,1
ffffffffc0202026:	e659                	bnez	a2,ffffffffc02020b4 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202028:	0a080b63          	beqz	a6,ffffffffc02020de <get_pte+0x1a4>
ffffffffc020202c:	10002773          	csrr	a4,sstatus
ffffffffc0202030:	8b09                	andi	a4,a4,2
ffffffffc0202032:	ef71                	bnez	a4,ffffffffc020210e <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202034:	00099717          	auipc	a4,0x99
ffffffffc0202038:	56c73703          	ld	a4,1388(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc020203c:	4505                	li	a0,1
ffffffffc020203e:	e43e                	sd	a5,8(sp)
ffffffffc0202040:	6f18                	ld	a4,24(a4)
ffffffffc0202042:	9702                	jalr	a4
ffffffffc0202044:	67a2                	ld	a5,8(sp)
ffffffffc0202046:	872a                	mv	a4,a0
ffffffffc0202048:	00099897          	auipc	a7,0x99
ffffffffc020204c:	57088893          	addi	a7,a7,1392 # ffffffffc029b5b8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202050:	c759                	beqz	a4,ffffffffc02020de <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0202052:	00099697          	auipc	a3,0x99
ffffffffc0202056:	5766b683          	ld	a3,1398(a3) # ffffffffc029b5c8 <pages>
ffffffffc020205a:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205e:	608c                	ld	a1,0(s1)
ffffffffc0202060:	40d706b3          	sub	a3,a4,a3
ffffffffc0202064:	8699                	srai	a3,a3,0x6
ffffffffc0202066:	96c2                	add	a3,a3,a6
ffffffffc0202068:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc020206c:	4505                	li	a0,1
ffffffffc020206e:	8231                	srli	a2,a2,0xc
ffffffffc0202070:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202072:	06b2                	slli	a3,a3,0xc
ffffffffc0202074:	10b67663          	bgeu	a2,a1,ffffffffc0202180 <get_pte+0x246>
ffffffffc0202078:	0008b503          	ld	a0,0(a7)
ffffffffc020207c:	6605                	lui	a2,0x1
ffffffffc020207e:	4581                	li	a1,0
ffffffffc0202080:	9536                	add	a0,a0,a3
ffffffffc0202082:	e83a                	sd	a4,16(sp)
ffffffffc0202084:	e43e                	sd	a5,8(sp)
ffffffffc0202086:	784030ef          	jal	ffffffffc020580a <memset>
    return page - pages + nbase;
ffffffffc020208a:	00099697          	auipc	a3,0x99
ffffffffc020208e:	53e6b683          	ld	a3,1342(a3) # ffffffffc029b5c8 <pages>
ffffffffc0202092:	6742                	ld	a4,16(sp)
ffffffffc0202094:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202098:	67a2                	ld	a5,8(sp)
ffffffffc020209a:	40d706b3          	sub	a3,a4,a3
ffffffffc020209e:	8699                	srai	a3,a3,0x6
ffffffffc02020a0:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a2:	06aa                	slli	a3,a3,0xa
ffffffffc02020a4:	0116e693          	ori	a3,a3,17
ffffffffc02020a8:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020aa:	6098                	ld	a4,0(s1)
ffffffffc02020ac:	00099897          	auipc	a7,0x99
ffffffffc02020b0:	50c88893          	addi	a7,a7,1292 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc02020b4:	c006f693          	andi	a3,a3,-1024
ffffffffc02020b8:	068a                	slli	a3,a3,0x2
ffffffffc02020ba:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020be:	06e7fc63          	bgeu	a5,a4,ffffffffc0202136 <get_pte+0x1fc>
ffffffffc02020c2:	0008b783          	ld	a5,0(a7)
ffffffffc02020c6:	8031                	srli	s0,s0,0xc
ffffffffc02020c8:	1ff47413          	andi	s0,s0,511
ffffffffc02020cc:	040e                	slli	s0,s0,0x3
ffffffffc02020ce:	96be                	add	a3,a3,a5
}
ffffffffc02020d0:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d2:	00868533          	add	a0,a3,s0
}
ffffffffc02020d6:	7442                	ld	s0,48(sp)
ffffffffc02020d8:	74a2                	ld	s1,40(sp)
ffffffffc02020da:	6121                	addi	sp,sp,64
ffffffffc02020dc:	8082                	ret
ffffffffc02020de:	70e2                	ld	ra,56(sp)
ffffffffc02020e0:	7442                	ld	s0,48(sp)
ffffffffc02020e2:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc02020e4:	4501                	li	a0,0
}
ffffffffc02020e6:	6121                	addi	sp,sp,64
ffffffffc02020e8:	8082                	ret
        intr_disable();
ffffffffc02020ea:	e83a                	sd	a4,16(sp)
ffffffffc02020ec:	ec32                	sd	a2,24(sp)
ffffffffc02020ee:	817fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020f2:	00099797          	auipc	a5,0x99
ffffffffc02020f6:	4ae7b783          	ld	a5,1198(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc02020fa:	4505                	li	a0,1
ffffffffc02020fc:	6f9c                	ld	a5,24(a5)
ffffffffc02020fe:	9782                	jalr	a5
ffffffffc0202100:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202102:	ffcfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202106:	6862                	ld	a6,24(sp)
ffffffffc0202108:	6742                	ld	a4,16(sp)
ffffffffc020210a:	67a2                	ld	a5,8(sp)
ffffffffc020210c:	bdbd                	j	ffffffffc0201f8a <get_pte+0x50>
        intr_disable();
ffffffffc020210e:	e83e                	sd	a5,16(sp)
ffffffffc0202110:	ff4fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202114:	00099717          	auipc	a4,0x99
ffffffffc0202118:	48c73703          	ld	a4,1164(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc020211c:	4505                	li	a0,1
ffffffffc020211e:	6f18                	ld	a4,24(a4)
ffffffffc0202120:	9702                	jalr	a4
ffffffffc0202122:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202124:	fdafe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202128:	6722                	ld	a4,8(sp)
ffffffffc020212a:	67c2                	ld	a5,16(sp)
ffffffffc020212c:	00099897          	auipc	a7,0x99
ffffffffc0202130:	48c88893          	addi	a7,a7,1164 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc0202134:	bf31                	j	ffffffffc0202050 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202136:	00004617          	auipc	a2,0x4
ffffffffc020213a:	49260613          	addi	a2,a2,1170 # ffffffffc02065c8 <etext+0xd94>
ffffffffc020213e:	0fa00593          	li	a1,250
ffffffffc0202142:	00004517          	auipc	a0,0x4
ffffffffc0202146:	57650513          	addi	a0,a0,1398 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020214a:	afcfe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020214e:	00004617          	auipc	a2,0x4
ffffffffc0202152:	47a60613          	addi	a2,a2,1146 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202156:	0ed00593          	li	a1,237
ffffffffc020215a:	00004517          	auipc	a0,0x4
ffffffffc020215e:	55e50513          	addi	a0,a0,1374 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202162:	ae4fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202166:	86aa                	mv	a3,a0
ffffffffc0202168:	00004617          	auipc	a2,0x4
ffffffffc020216c:	46060613          	addi	a2,a2,1120 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202170:	0e900593          	li	a1,233
ffffffffc0202174:	00004517          	auipc	a0,0x4
ffffffffc0202178:	54450513          	addi	a0,a0,1348 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020217c:	acafe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202180:	00004617          	auipc	a2,0x4
ffffffffc0202184:	44860613          	addi	a2,a2,1096 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202188:	0f700593          	li	a1,247
ffffffffc020218c:	00004517          	auipc	a0,0x4
ffffffffc0202190:	52c50513          	addi	a0,a0,1324 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202194:	ab2fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202198 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202198:	1141                	addi	sp,sp,-16
ffffffffc020219a:	e022                	sd	s0,0(sp)
ffffffffc020219c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020219e:	4601                	li	a2,0
{
ffffffffc02021a0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021a2:	d99ff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep_store != NULL)
ffffffffc02021a6:	c011                	beqz	s0,ffffffffc02021aa <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021a8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021aa:	c511                	beqz	a0,ffffffffc02021b6 <get_page+0x1e>
ffffffffc02021ac:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021ae:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021b0:	0017f713          	andi	a4,a5,1
ffffffffc02021b4:	e709                	bnez	a4,ffffffffc02021be <get_page+0x26>
}
ffffffffc02021b6:	60a2                	ld	ra,8(sp)
ffffffffc02021b8:	6402                	ld	s0,0(sp)
ffffffffc02021ba:	0141                	addi	sp,sp,16
ffffffffc02021bc:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021be:	00099717          	auipc	a4,0x99
ffffffffc02021c2:	40273703          	ld	a4,1026(a4) # ffffffffc029b5c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021c6:	078a                	slli	a5,a5,0x2
ffffffffc02021c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021ca:	00e7ff63          	bgeu	a5,a4,ffffffffc02021e8 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021ce:	00099517          	auipc	a0,0x99
ffffffffc02021d2:	3fa53503          	ld	a0,1018(a0) # ffffffffc029b5c8 <pages>
ffffffffc02021d6:	60a2                	ld	ra,8(sp)
ffffffffc02021d8:	6402                	ld	s0,0(sp)
ffffffffc02021da:	079a                	slli	a5,a5,0x6
ffffffffc02021dc:	fe000737          	lui	a4,0xfe000
ffffffffc02021e0:	97ba                	add	a5,a5,a4
ffffffffc02021e2:	953e                	add	a0,a0,a5
ffffffffc02021e4:	0141                	addi	sp,sp,16
ffffffffc02021e6:	8082                	ret
ffffffffc02021e8:	c8fff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc02021ec <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021ec:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ee:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021f2:	e486                	sd	ra,72(sp)
ffffffffc02021f4:	e0a2                	sd	s0,64(sp)
ffffffffc02021f6:	fc26                	sd	s1,56(sp)
ffffffffc02021f8:	f84a                	sd	s2,48(sp)
ffffffffc02021fa:	f44e                	sd	s3,40(sp)
ffffffffc02021fc:	f052                	sd	s4,32(sp)
ffffffffc02021fe:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202200:	03479713          	slli	a4,a5,0x34
ffffffffc0202204:	ef61                	bnez	a4,ffffffffc02022dc <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202206:	00200a37          	lui	s4,0x200
ffffffffc020220a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020220e:	0145b733          	sltu	a4,a1,s4
ffffffffc0202212:	0017b793          	seqz	a5,a5
ffffffffc0202216:	8fd9                	or	a5,a5,a4
ffffffffc0202218:	842e                	mv	s0,a1
ffffffffc020221a:	84b2                	mv	s1,a2
ffffffffc020221c:	e3e5                	bnez	a5,ffffffffc02022fc <unmap_range+0x110>
ffffffffc020221e:	4785                	li	a5,1
ffffffffc0202220:	07fe                	slli	a5,a5,0x1f
ffffffffc0202222:	0785                	addi	a5,a5,1
ffffffffc0202224:	892a                	mv	s2,a0
ffffffffc0202226:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202228:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc020222c:	0cf67863          	bgeu	a2,a5,ffffffffc02022fc <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202230:	4601                	li	a2,0
ffffffffc0202232:	85a2                	mv	a1,s0
ffffffffc0202234:	854a                	mv	a0,s2
ffffffffc0202236:	d05ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc020223a:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc020223c:	cd31                	beqz	a0,ffffffffc0202298 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc020223e:	6118                	ld	a4,0(a0)
ffffffffc0202240:	ef11                	bnez	a4,ffffffffc020225c <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202242:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0202244:	c019                	beqz	s0,ffffffffc020224a <unmap_range+0x5e>
ffffffffc0202246:	fe9465e3          	bltu	s0,s1,ffffffffc0202230 <unmap_range+0x44>
}
ffffffffc020224a:	60a6                	ld	ra,72(sp)
ffffffffc020224c:	6406                	ld	s0,64(sp)
ffffffffc020224e:	74e2                	ld	s1,56(sp)
ffffffffc0202250:	7942                	ld	s2,48(sp)
ffffffffc0202252:	79a2                	ld	s3,40(sp)
ffffffffc0202254:	7a02                	ld	s4,32(sp)
ffffffffc0202256:	6ae2                	ld	s5,24(sp)
ffffffffc0202258:	6161                	addi	sp,sp,80
ffffffffc020225a:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020225c:	00177693          	andi	a3,a4,1
ffffffffc0202260:	d2ed                	beqz	a3,ffffffffc0202242 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc0202262:	00099697          	auipc	a3,0x99
ffffffffc0202266:	35e6b683          	ld	a3,862(a3) # ffffffffc029b5c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020226a:	070a                	slli	a4,a4,0x2
ffffffffc020226c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020226e:	0ad77763          	bgeu	a4,a3,ffffffffc020231c <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc0202272:	00099517          	auipc	a0,0x99
ffffffffc0202276:	35653503          	ld	a0,854(a0) # ffffffffc029b5c8 <pages>
ffffffffc020227a:	071a                	slli	a4,a4,0x6
ffffffffc020227c:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202280:	9736                	add	a4,a4,a3
ffffffffc0202282:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202284:	4118                	lw	a4,0(a0)
ffffffffc0202286:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd64a0f>
ffffffffc0202288:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020228a:	cb19                	beqz	a4,ffffffffc02022a0 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc020228c:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202290:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202294:	944e                	add	s0,s0,s3
ffffffffc0202296:	b77d                	j	ffffffffc0202244 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202298:	9452                	add	s0,s0,s4
ffffffffc020229a:	01547433          	and	s0,s0,s5
            continue;
ffffffffc020229e:	b75d                	j	ffffffffc0202244 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022a0:	10002773          	csrr	a4,sstatus
ffffffffc02022a4:	8b09                	andi	a4,a4,2
ffffffffc02022a6:	eb19                	bnez	a4,ffffffffc02022bc <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02022a8:	00099717          	auipc	a4,0x99
ffffffffc02022ac:	2f873703          	ld	a4,760(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc02022b0:	4585                	li	a1,1
ffffffffc02022b2:	e03e                	sd	a5,0(sp)
ffffffffc02022b4:	7318                	ld	a4,32(a4)
ffffffffc02022b6:	9702                	jalr	a4
    if (flag)
ffffffffc02022b8:	6782                	ld	a5,0(sp)
ffffffffc02022ba:	bfc9                	j	ffffffffc020228c <unmap_range+0xa0>
        intr_disable();
ffffffffc02022bc:	e43e                	sd	a5,8(sp)
ffffffffc02022be:	e02a                	sd	a0,0(sp)
ffffffffc02022c0:	e44fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022c4:	00099717          	auipc	a4,0x99
ffffffffc02022c8:	2dc73703          	ld	a4,732(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc02022cc:	6502                	ld	a0,0(sp)
ffffffffc02022ce:	4585                	li	a1,1
ffffffffc02022d0:	7318                	ld	a4,32(a4)
ffffffffc02022d2:	9702                	jalr	a4
        intr_enable();
ffffffffc02022d4:	e2afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022d8:	67a2                	ld	a5,8(sp)
ffffffffc02022da:	bf4d                	j	ffffffffc020228c <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022dc:	00004697          	auipc	a3,0x4
ffffffffc02022e0:	3ec68693          	addi	a3,a3,1004 # ffffffffc02066c8 <etext+0xe94>
ffffffffc02022e4:	00004617          	auipc	a2,0x4
ffffffffc02022e8:	f3460613          	addi	a2,a2,-204 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02022ec:	12000593          	li	a1,288
ffffffffc02022f0:	00004517          	auipc	a0,0x4
ffffffffc02022f4:	3c850513          	addi	a0,a0,968 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02022f8:	94efe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022fc:	00004697          	auipc	a3,0x4
ffffffffc0202300:	3fc68693          	addi	a3,a3,1020 # ffffffffc02066f8 <etext+0xec4>
ffffffffc0202304:	00004617          	auipc	a2,0x4
ffffffffc0202308:	f1460613          	addi	a2,a2,-236 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020230c:	12100593          	li	a1,289
ffffffffc0202310:	00004517          	auipc	a0,0x4
ffffffffc0202314:	3a850513          	addi	a0,a0,936 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202318:	92efe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020231c:	b5bff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202320 <exit_range>:
{
ffffffffc0202320:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202322:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202326:	ed06                	sd	ra,152(sp)
ffffffffc0202328:	e922                	sd	s0,144(sp)
ffffffffc020232a:	e526                	sd	s1,136(sp)
ffffffffc020232c:	e14a                	sd	s2,128(sp)
ffffffffc020232e:	fcce                	sd	s3,120(sp)
ffffffffc0202330:	f8d2                	sd	s4,112(sp)
ffffffffc0202332:	f4d6                	sd	s5,104(sp)
ffffffffc0202334:	f0da                	sd	s6,96(sp)
ffffffffc0202336:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202338:	17d2                	slli	a5,a5,0x34
ffffffffc020233a:	22079263          	bnez	a5,ffffffffc020255e <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc020233e:	00200937          	lui	s2,0x200
ffffffffc0202342:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202346:	0125b733          	sltu	a4,a1,s2
ffffffffc020234a:	0017b793          	seqz	a5,a5
ffffffffc020234e:	8fd9                	or	a5,a5,a4
ffffffffc0202350:	26079263          	bnez	a5,ffffffffc02025b4 <exit_range+0x294>
ffffffffc0202354:	4785                	li	a5,1
ffffffffc0202356:	07fe                	slli	a5,a5,0x1f
ffffffffc0202358:	0785                	addi	a5,a5,1
ffffffffc020235a:	24f67d63          	bgeu	a2,a5,ffffffffc02025b4 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020235e:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202362:	ffe007b7          	lui	a5,0xffe00
ffffffffc0202366:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202368:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020236a:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc020236e:	00099a97          	auipc	s5,0x99
ffffffffc0202372:	252a8a93          	addi	s5,s5,594 # ffffffffc029b5c0 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202376:	400009b7          	lui	s3,0x40000
ffffffffc020237a:	a809                	j	ffffffffc020238c <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc020237c:	013487b3          	add	a5,s1,s3
ffffffffc0202380:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202384:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202386:	c3f1                	beqz	a5,ffffffffc020244a <exit_range+0x12a>
ffffffffc0202388:	0cc7f163          	bgeu	a5,a2,ffffffffc020244a <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020238c:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202390:	1ff47413          	andi	s0,s0,511
ffffffffc0202394:	040e                	slli	s0,s0,0x3
ffffffffc0202396:	9452                	add	s0,s0,s4
ffffffffc0202398:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc020239c:	0018f793          	andi	a5,a7,1
ffffffffc02023a0:	dff1                	beqz	a5,ffffffffc020237c <exit_range+0x5c>
ffffffffc02023a2:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023a6:	088a                	slli	a7,a7,0x2
ffffffffc02023a8:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02023ac:	20f8f263          	bgeu	a7,a5,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b0:	fff802b7          	lui	t0,0xfff80
ffffffffc02023b4:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023b8:	000803b7          	lui	t2,0x80
ffffffffc02023bc:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023c0:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023c4:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023c6:	1cf77863          	bgeu	a4,a5,ffffffffc0202596 <exit_range+0x276>
ffffffffc02023ca:	00099f97          	auipc	t6,0x99
ffffffffc02023ce:	1eef8f93          	addi	t6,t6,494 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc02023d2:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023d6:	4e85                	li	t4,1
ffffffffc02023d8:	6b05                	lui	s6,0x1
ffffffffc02023da:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023dc:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023e0:	01585713          	srli	a4,a6,0x15
ffffffffc02023e4:	1ff77713          	andi	a4,a4,511
ffffffffc02023e8:	070e                	slli	a4,a4,0x3
ffffffffc02023ea:	9772                	add	a4,a4,t3
ffffffffc02023ec:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc02023ee:	0017f693          	andi	a3,a5,1
ffffffffc02023f2:	e6bd                	bnez	a3,ffffffffc0202460 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc02023f4:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc02023f6:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023f8:	00080863          	beqz	a6,ffffffffc0202408 <exit_range+0xe8>
ffffffffc02023fc:	879a                	mv	a5,t1
ffffffffc02023fe:	00667363          	bgeu	a2,t1,ffffffffc0202404 <exit_range+0xe4>
ffffffffc0202402:	87b2                	mv	a5,a2
ffffffffc0202404:	fcf86ee3          	bltu	a6,a5,ffffffffc02023e0 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202408:	f60e8ae3          	beqz	t4,ffffffffc020237c <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc020240c:	000ab783          	ld	a5,0(s5)
ffffffffc0202410:	1af8f063          	bgeu	a7,a5,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	00099517          	auipc	a0,0x99
ffffffffc0202418:	1b453503          	ld	a0,436(a0) # ffffffffc029b5c8 <pages>
ffffffffc020241c:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020241e:	100027f3          	csrr	a5,sstatus
ffffffffc0202422:	8b89                	andi	a5,a5,2
ffffffffc0202424:	10079b63          	bnez	a5,ffffffffc020253a <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202428:	00099797          	auipc	a5,0x99
ffffffffc020242c:	1787b783          	ld	a5,376(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0202430:	4585                	li	a1,1
ffffffffc0202432:	e432                	sd	a2,8(sp)
ffffffffc0202434:	739c                	ld	a5,32(a5)
ffffffffc0202436:	9782                	jalr	a5
ffffffffc0202438:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc020243a:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc020243e:	013487b3          	add	a5,s1,s3
ffffffffc0202442:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202446:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202448:	f3a1                	bnez	a5,ffffffffc0202388 <exit_range+0x68>
}
ffffffffc020244a:	60ea                	ld	ra,152(sp)
ffffffffc020244c:	644a                	ld	s0,144(sp)
ffffffffc020244e:	64aa                	ld	s1,136(sp)
ffffffffc0202450:	690a                	ld	s2,128(sp)
ffffffffc0202452:	79e6                	ld	s3,120(sp)
ffffffffc0202454:	7a46                	ld	s4,112(sp)
ffffffffc0202456:	7aa6                	ld	s5,104(sp)
ffffffffc0202458:	7b06                	ld	s6,96(sp)
ffffffffc020245a:	6be6                	ld	s7,88(sp)
ffffffffc020245c:	610d                	addi	sp,sp,160
ffffffffc020245e:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202460:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202464:	078a                	slli	a5,a5,0x2
ffffffffc0202466:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202468:	14a7f463          	bgeu	a5,a0,ffffffffc02025b0 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc020246c:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc020246e:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc0202472:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202476:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc020247a:	10abf263          	bgeu	s7,a0,ffffffffc020257e <exit_range+0x25e>
ffffffffc020247e:	000fb783          	ld	a5,0(t6)
ffffffffc0202482:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202484:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202488:	629c                	ld	a5,0(a3)
ffffffffc020248a:	8b85                	andi	a5,a5,1
ffffffffc020248c:	f7ad                	bnez	a5,ffffffffc02023f6 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020248e:	06a1                	addi	a3,a3,8
ffffffffc0202490:	fea69ce3          	bne	a3,a0,ffffffffc0202488 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc0202494:	00099517          	auipc	a0,0x99
ffffffffc0202498:	13453503          	ld	a0,308(a0) # ffffffffc029b5c8 <pages>
ffffffffc020249c:	952e                	add	a0,a0,a1
ffffffffc020249e:	100027f3          	csrr	a5,sstatus
ffffffffc02024a2:	8b89                	andi	a5,a5,2
ffffffffc02024a4:	e3b9                	bnez	a5,ffffffffc02024ea <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02024a6:	00099797          	auipc	a5,0x99
ffffffffc02024aa:	0fa7b783          	ld	a5,250(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc02024ae:	4585                	li	a1,1
ffffffffc02024b0:	e0b2                	sd	a2,64(sp)
ffffffffc02024b2:	739c                	ld	a5,32(a5)
ffffffffc02024b4:	fc1a                	sd	t1,56(sp)
ffffffffc02024b6:	f846                	sd	a7,48(sp)
ffffffffc02024b8:	f47a                	sd	t5,40(sp)
ffffffffc02024ba:	f072                	sd	t3,32(sp)
ffffffffc02024bc:	ec76                	sd	t4,24(sp)
ffffffffc02024be:	e842                	sd	a6,16(sp)
ffffffffc02024c0:	e43a                	sd	a4,8(sp)
ffffffffc02024c2:	9782                	jalr	a5
    if (flag)
ffffffffc02024c4:	6722                	ld	a4,8(sp)
ffffffffc02024c6:	6842                	ld	a6,16(sp)
ffffffffc02024c8:	6ee2                	ld	t4,24(sp)
ffffffffc02024ca:	7e02                	ld	t3,32(sp)
ffffffffc02024cc:	7f22                	ld	t5,40(sp)
ffffffffc02024ce:	78c2                	ld	a7,48(sp)
ffffffffc02024d0:	7362                	ld	t1,56(sp)
ffffffffc02024d2:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024d4:	fff802b7          	lui	t0,0xfff80
ffffffffc02024d8:	000803b7          	lui	t2,0x80
ffffffffc02024dc:	00099f97          	auipc	t6,0x99
ffffffffc02024e0:	0dcf8f93          	addi	t6,t6,220 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc02024e4:	00073023          	sd	zero,0(a4)
ffffffffc02024e8:	b739                	j	ffffffffc02023f6 <exit_range+0xd6>
        intr_disable();
ffffffffc02024ea:	e4b2                	sd	a2,72(sp)
ffffffffc02024ec:	e09a                	sd	t1,64(sp)
ffffffffc02024ee:	fc46                	sd	a7,56(sp)
ffffffffc02024f0:	f47a                	sd	t5,40(sp)
ffffffffc02024f2:	f072                	sd	t3,32(sp)
ffffffffc02024f4:	ec76                	sd	t4,24(sp)
ffffffffc02024f6:	e842                	sd	a6,16(sp)
ffffffffc02024f8:	e43a                	sd	a4,8(sp)
ffffffffc02024fa:	f82a                	sd	a0,48(sp)
ffffffffc02024fc:	c08fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202500:	00099797          	auipc	a5,0x99
ffffffffc0202504:	0a07b783          	ld	a5,160(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0202508:	7542                	ld	a0,48(sp)
ffffffffc020250a:	4585                	li	a1,1
ffffffffc020250c:	739c                	ld	a5,32(a5)
ffffffffc020250e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202510:	beefe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202514:	6722                	ld	a4,8(sp)
ffffffffc0202516:	6626                	ld	a2,72(sp)
ffffffffc0202518:	6306                	ld	t1,64(sp)
ffffffffc020251a:	78e2                	ld	a7,56(sp)
ffffffffc020251c:	7f22                	ld	t5,40(sp)
ffffffffc020251e:	7e02                	ld	t3,32(sp)
ffffffffc0202520:	6ee2                	ld	t4,24(sp)
ffffffffc0202522:	6842                	ld	a6,16(sp)
ffffffffc0202524:	00099f97          	auipc	t6,0x99
ffffffffc0202528:	094f8f93          	addi	t6,t6,148 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc020252c:	000803b7          	lui	t2,0x80
ffffffffc0202530:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202534:	00073023          	sd	zero,0(a4)
ffffffffc0202538:	bd7d                	j	ffffffffc02023f6 <exit_range+0xd6>
        intr_disable();
ffffffffc020253a:	e832                	sd	a2,16(sp)
ffffffffc020253c:	e42a                	sd	a0,8(sp)
ffffffffc020253e:	bc6fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202542:	00099797          	auipc	a5,0x99
ffffffffc0202546:	05e7b783          	ld	a5,94(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc020254a:	6522                	ld	a0,8(sp)
ffffffffc020254c:	4585                	li	a1,1
ffffffffc020254e:	739c                	ld	a5,32(a5)
ffffffffc0202550:	9782                	jalr	a5
        intr_enable();
ffffffffc0202552:	bacfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202556:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202558:	00043023          	sd	zero,0(s0)
ffffffffc020255c:	b5cd                	j	ffffffffc020243e <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020255e:	00004697          	auipc	a3,0x4
ffffffffc0202562:	16a68693          	addi	a3,a3,362 # ffffffffc02066c8 <etext+0xe94>
ffffffffc0202566:	00004617          	auipc	a2,0x4
ffffffffc020256a:	cb260613          	addi	a2,a2,-846 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020256e:	13500593          	li	a1,309
ffffffffc0202572:	00004517          	auipc	a0,0x4
ffffffffc0202576:	14650513          	addi	a0,a0,326 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020257a:	ecdfd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020257e:	00004617          	auipc	a2,0x4
ffffffffc0202582:	04a60613          	addi	a2,a2,74 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202586:	07100593          	li	a1,113
ffffffffc020258a:	00004517          	auipc	a0,0x4
ffffffffc020258e:	06650513          	addi	a0,a0,102 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0202592:	eb5fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202596:	86f2                	mv	a3,t3
ffffffffc0202598:	00004617          	auipc	a2,0x4
ffffffffc020259c:	03060613          	addi	a2,a2,48 # ffffffffc02065c8 <etext+0xd94>
ffffffffc02025a0:	07100593          	li	a1,113
ffffffffc02025a4:	00004517          	auipc	a0,0x4
ffffffffc02025a8:	04c50513          	addi	a0,a0,76 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02025ac:	e9bfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025b0:	8c7ff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025b4:	00004697          	auipc	a3,0x4
ffffffffc02025b8:	14468693          	addi	a3,a3,324 # ffffffffc02066f8 <etext+0xec4>
ffffffffc02025bc:	00004617          	auipc	a2,0x4
ffffffffc02025c0:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02025c4:	13600593          	li	a1,310
ffffffffc02025c8:	00004517          	auipc	a0,0x4
ffffffffc02025cc:	0f050513          	addi	a0,a0,240 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02025d0:	e77fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025d4 <page_remove>:
{
ffffffffc02025d4:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025d6:	4601                	li	a2,0
{
ffffffffc02025d8:	e822                	sd	s0,16(sp)
ffffffffc02025da:	ec06                	sd	ra,24(sp)
ffffffffc02025dc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025de:	95dff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep != NULL)
ffffffffc02025e2:	c511                	beqz	a0,ffffffffc02025ee <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02025e4:	6118                	ld	a4,0(a0)
ffffffffc02025e6:	87aa                	mv	a5,a0
ffffffffc02025e8:	00177693          	andi	a3,a4,1
ffffffffc02025ec:	e689                	bnez	a3,ffffffffc02025f6 <page_remove+0x22>
}
ffffffffc02025ee:	60e2                	ld	ra,24(sp)
ffffffffc02025f0:	6442                	ld	s0,16(sp)
ffffffffc02025f2:	6105                	addi	sp,sp,32
ffffffffc02025f4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025f6:	00099697          	auipc	a3,0x99
ffffffffc02025fa:	fca6b683          	ld	a3,-54(a3) # ffffffffc029b5c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02025fe:	070a                	slli	a4,a4,0x2
ffffffffc0202600:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202602:	06d77563          	bgeu	a4,a3,ffffffffc020266c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202606:	00099517          	auipc	a0,0x99
ffffffffc020260a:	fc253503          	ld	a0,-62(a0) # ffffffffc029b5c8 <pages>
ffffffffc020260e:	071a                	slli	a4,a4,0x6
ffffffffc0202610:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202614:	9736                	add	a4,a4,a3
ffffffffc0202616:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202618:	4118                	lw	a4,0(a0)
ffffffffc020261a:	377d                	addiw	a4,a4,-1
ffffffffc020261c:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020261e:	cb09                	beqz	a4,ffffffffc0202630 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202620:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202624:	12040073          	sfence.vma	s0
}
ffffffffc0202628:	60e2                	ld	ra,24(sp)
ffffffffc020262a:	6442                	ld	s0,16(sp)
ffffffffc020262c:	6105                	addi	sp,sp,32
ffffffffc020262e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202630:	10002773          	csrr	a4,sstatus
ffffffffc0202634:	8b09                	andi	a4,a4,2
ffffffffc0202636:	eb19                	bnez	a4,ffffffffc020264c <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202638:	00099717          	auipc	a4,0x99
ffffffffc020263c:	f6873703          	ld	a4,-152(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0202640:	4585                	li	a1,1
ffffffffc0202642:	e03e                	sd	a5,0(sp)
ffffffffc0202644:	7318                	ld	a4,32(a4)
ffffffffc0202646:	9702                	jalr	a4
    if (flag)
ffffffffc0202648:	6782                	ld	a5,0(sp)
ffffffffc020264a:	bfd9                	j	ffffffffc0202620 <page_remove+0x4c>
        intr_disable();
ffffffffc020264c:	e43e                	sd	a5,8(sp)
ffffffffc020264e:	e02a                	sd	a0,0(sp)
ffffffffc0202650:	ab4fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202654:	00099717          	auipc	a4,0x99
ffffffffc0202658:	f4c73703          	ld	a4,-180(a4) # ffffffffc029b5a0 <pmm_manager>
ffffffffc020265c:	6502                	ld	a0,0(sp)
ffffffffc020265e:	4585                	li	a1,1
ffffffffc0202660:	7318                	ld	a4,32(a4)
ffffffffc0202662:	9702                	jalr	a4
        intr_enable();
ffffffffc0202664:	a9afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202668:	67a2                	ld	a5,8(sp)
ffffffffc020266a:	bf5d                	j	ffffffffc0202620 <page_remove+0x4c>
ffffffffc020266c:	80bff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202670 <page_insert>:
{
ffffffffc0202670:	7139                	addi	sp,sp,-64
ffffffffc0202672:	f426                	sd	s1,40(sp)
ffffffffc0202674:	84b2                	mv	s1,a2
ffffffffc0202676:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202678:	4605                	li	a2,1
{
ffffffffc020267a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020267c:	85a6                	mv	a1,s1
{
ffffffffc020267e:	fc06                	sd	ra,56(sp)
ffffffffc0202680:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202682:	8b9ff0ef          	jal	ffffffffc0201f3a <get_pte>
    if (ptep == NULL)
ffffffffc0202686:	cd61                	beqz	a0,ffffffffc020275e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202688:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020268a:	611c                	ld	a5,0(a0)
ffffffffc020268c:	66a2                	ld	a3,8(sp)
ffffffffc020268e:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7baf>
ffffffffc0202692:	c010                	sw	a2,0(s0)
ffffffffc0202694:	0017f613          	andi	a2,a5,1
ffffffffc0202698:	872a                	mv	a4,a0
ffffffffc020269a:	e61d                	bnez	a2,ffffffffc02026c8 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020269c:	00099617          	auipc	a2,0x99
ffffffffc02026a0:	f2c63603          	ld	a2,-212(a2) # ffffffffc029b5c8 <pages>
    return page - pages + nbase;
ffffffffc02026a4:	8c11                	sub	s0,s0,a2
ffffffffc02026a6:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026a8:	200007b7          	lui	a5,0x20000
ffffffffc02026ac:	042a                	slli	s0,s0,0xa
ffffffffc02026ae:	943e                	add	s0,s0,a5
ffffffffc02026b0:	8ec1                	or	a3,a3,s0
ffffffffc02026b2:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026b6:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026b8:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026bc:	4501                	li	a0,0
}
ffffffffc02026be:	70e2                	ld	ra,56(sp)
ffffffffc02026c0:	7442                	ld	s0,48(sp)
ffffffffc02026c2:	74a2                	ld	s1,40(sp)
ffffffffc02026c4:	6121                	addi	sp,sp,64
ffffffffc02026c6:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026c8:	00099617          	auipc	a2,0x99
ffffffffc02026cc:	ef863603          	ld	a2,-264(a2) # ffffffffc029b5c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026d0:	078a                	slli	a5,a5,0x2
ffffffffc02026d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026d4:	08c7f763          	bgeu	a5,a2,ffffffffc0202762 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026d8:	00099617          	auipc	a2,0x99
ffffffffc02026dc:	ef063603          	ld	a2,-272(a2) # ffffffffc029b5c8 <pages>
ffffffffc02026e0:	fe000537          	lui	a0,0xfe000
ffffffffc02026e4:	079a                	slli	a5,a5,0x6
ffffffffc02026e6:	97aa                	add	a5,a5,a0
ffffffffc02026e8:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02026ec:	00a40963          	beq	s0,a0,ffffffffc02026fe <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02026f0:	411c                	lw	a5,0(a0)
ffffffffc02026f2:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e47>
ffffffffc02026f4:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026f6:	c791                	beqz	a5,ffffffffc0202702 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026f8:	12048073          	sfence.vma	s1
}
ffffffffc02026fc:	b765                	j	ffffffffc02026a4 <page_insert+0x34>
ffffffffc02026fe:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202700:	b755                	j	ffffffffc02026a4 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202702:	100027f3          	csrr	a5,sstatus
ffffffffc0202706:	8b89                	andi	a5,a5,2
ffffffffc0202708:	e39d                	bnez	a5,ffffffffc020272e <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020270a:	00099797          	auipc	a5,0x99
ffffffffc020270e:	e967b783          	ld	a5,-362(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0202712:	4585                	li	a1,1
ffffffffc0202714:	e83a                	sd	a4,16(sp)
ffffffffc0202716:	739c                	ld	a5,32(a5)
ffffffffc0202718:	e436                	sd	a3,8(sp)
ffffffffc020271a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020271c:	00099617          	auipc	a2,0x99
ffffffffc0202720:	eac63603          	ld	a2,-340(a2) # ffffffffc029b5c8 <pages>
ffffffffc0202724:	66a2                	ld	a3,8(sp)
ffffffffc0202726:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202728:	12048073          	sfence.vma	s1
ffffffffc020272c:	bfa5                	j	ffffffffc02026a4 <page_insert+0x34>
        intr_disable();
ffffffffc020272e:	ec3a                	sd	a4,24(sp)
ffffffffc0202730:	e836                	sd	a3,16(sp)
ffffffffc0202732:	e42a                	sd	a0,8(sp)
ffffffffc0202734:	9d0fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202738:	00099797          	auipc	a5,0x99
ffffffffc020273c:	e687b783          	ld	a5,-408(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0202740:	6522                	ld	a0,8(sp)
ffffffffc0202742:	4585                	li	a1,1
ffffffffc0202744:	739c                	ld	a5,32(a5)
ffffffffc0202746:	9782                	jalr	a5
        intr_enable();
ffffffffc0202748:	9b6fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020274c:	00099617          	auipc	a2,0x99
ffffffffc0202750:	e7c63603          	ld	a2,-388(a2) # ffffffffc029b5c8 <pages>
ffffffffc0202754:	6762                	ld	a4,24(sp)
ffffffffc0202756:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202758:	12048073          	sfence.vma	s1
ffffffffc020275c:	b7a1                	j	ffffffffc02026a4 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020275e:	5571                	li	a0,-4
ffffffffc0202760:	bfb9                	j	ffffffffc02026be <page_insert+0x4e>
ffffffffc0202762:	f14ff0ef          	jal	ffffffffc0201e76 <pa2page.part.0>

ffffffffc0202766 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202766:	00005797          	auipc	a5,0x5
ffffffffc020276a:	ec278793          	addi	a5,a5,-318 # ffffffffc0207628 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020276e:	638c                	ld	a1,0(a5)
{
ffffffffc0202770:	7159                	addi	sp,sp,-112
ffffffffc0202772:	f486                	sd	ra,104(sp)
ffffffffc0202774:	e8ca                	sd	s2,80(sp)
ffffffffc0202776:	e4ce                	sd	s3,72(sp)
ffffffffc0202778:	f85a                	sd	s6,48(sp)
ffffffffc020277a:	f0a2                	sd	s0,96(sp)
ffffffffc020277c:	eca6                	sd	s1,88(sp)
ffffffffc020277e:	e0d2                	sd	s4,64(sp)
ffffffffc0202780:	fc56                	sd	s5,56(sp)
ffffffffc0202782:	f45e                	sd	s7,40(sp)
ffffffffc0202784:	f062                	sd	s8,32(sp)
ffffffffc0202786:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202788:	00099b17          	auipc	s6,0x99
ffffffffc020278c:	e18b0b13          	addi	s6,s6,-488 # ffffffffc029b5a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202790:	00004517          	auipc	a0,0x4
ffffffffc0202794:	f8050513          	addi	a0,a0,-128 # ffffffffc0206710 <etext+0xedc>
    pmm_manager = &default_pmm_manager;
ffffffffc0202798:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020279c:	9f9fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027a0:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027a4:	00099997          	auipc	s3,0x99
ffffffffc02027a8:	e1498993          	addi	s3,s3,-492 # ffffffffc029b5b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027ac:	679c                	ld	a5,8(a5)
ffffffffc02027ae:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b0:	57f5                	li	a5,-3
ffffffffc02027b2:	07fa                	slli	a5,a5,0x1e
ffffffffc02027b4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027b8:	932fe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027bc:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027be:	936fe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027c2:	70050e63          	beqz	a0,ffffffffc0202ede <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027c6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027c8:	00004517          	auipc	a0,0x4
ffffffffc02027cc:	f8050513          	addi	a0,a0,-128 # ffffffffc0206748 <etext+0xf14>
ffffffffc02027d0:	9c5fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027d4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027d8:	864a                	mv	a2,s2
ffffffffc02027da:	85a6                	mv	a1,s1
ffffffffc02027dc:	fff40693          	addi	a3,s0,-1
ffffffffc02027e0:	00004517          	auipc	a0,0x4
ffffffffc02027e4:	f8050513          	addi	a0,a0,-128 # ffffffffc0206760 <etext+0xf2c>
ffffffffc02027e8:	9adfd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02027ec:	c80007b7          	lui	a5,0xc8000
ffffffffc02027f0:	8522                	mv	a0,s0
ffffffffc02027f2:	5287ed63          	bltu	a5,s0,ffffffffc0202d2c <pmm_init+0x5c6>
ffffffffc02027f6:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027f8:	0009a617          	auipc	a2,0x9a
ffffffffc02027fc:	df760613          	addi	a2,a2,-521 # ffffffffc029c5ef <end+0xfff>
ffffffffc0202800:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202802:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202804:	00099b97          	auipc	s7,0x99
ffffffffc0202808:	dc4b8b93          	addi	s7,s7,-572 # ffffffffc029b5c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020280c:	00099497          	auipc	s1,0x99
ffffffffc0202810:	db448493          	addi	s1,s1,-588 # ffffffffc029b5c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202814:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202818:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020281a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020281e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202820:	02f50763          	beq	a0,a5,ffffffffc020284e <pmm_init+0xe8>
ffffffffc0202824:	4701                	li	a4,0
ffffffffc0202826:	4585                	li	a1,1
ffffffffc0202828:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020282c:	00671793          	slli	a5,a4,0x6
ffffffffc0202830:	97b2                	add	a5,a5,a2
ffffffffc0202832:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e50>
ffffffffc0202834:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202838:	6088                	ld	a0,0(s1)
ffffffffc020283a:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020283c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202840:	00d507b3          	add	a5,a0,a3
ffffffffc0202844:	fef764e3          	bltu	a4,a5,ffffffffc020282c <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202848:	079a                	slli	a5,a5,0x6
ffffffffc020284a:	00f606b3          	add	a3,a2,a5
ffffffffc020284e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202852:	16f6eee3          	bltu	a3,a5,ffffffffc02031ce <pmm_init+0xa68>
ffffffffc0202856:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020285a:	77fd                	lui	a5,0xfffff
ffffffffc020285c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020285e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202860:	4e86ed63          	bltu	a3,s0,ffffffffc0202d5a <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202864:	00004517          	auipc	a0,0x4
ffffffffc0202868:	f2450513          	addi	a0,a0,-220 # ffffffffc0206788 <etext+0xf54>
ffffffffc020286c:	929fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202870:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202874:	00099917          	auipc	s2,0x99
ffffffffc0202878:	d3c90913          	addi	s2,s2,-708 # ffffffffc029b5b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020287c:	7b9c                	ld	a5,48(a5)
ffffffffc020287e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202880:	00004517          	auipc	a0,0x4
ffffffffc0202884:	f2050513          	addi	a0,a0,-224 # ffffffffc02067a0 <etext+0xf6c>
ffffffffc0202888:	90dfd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020288c:	00007697          	auipc	a3,0x7
ffffffffc0202890:	77468693          	addi	a3,a3,1908 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202894:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202898:	c02007b7          	lui	a5,0xc0200
ffffffffc020289c:	2af6eee3          	bltu	a3,a5,ffffffffc0203358 <pmm_init+0xbf2>
ffffffffc02028a0:	0009b783          	ld	a5,0(s3)
ffffffffc02028a4:	8e9d                	sub	a3,a3,a5
ffffffffc02028a6:	00099797          	auipc	a5,0x99
ffffffffc02028aa:	d0d7b123          	sd	a3,-766(a5) # ffffffffc029b5a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ae:	100027f3          	csrr	a5,sstatus
ffffffffc02028b2:	8b89                	andi	a5,a5,2
ffffffffc02028b4:	48079963          	bnez	a5,ffffffffc0202d46 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028b8:	000b3783          	ld	a5,0(s6)
ffffffffc02028bc:	779c                	ld	a5,40(a5)
ffffffffc02028be:	9782                	jalr	a5
ffffffffc02028c0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028c2:	6098                	ld	a4,0(s1)
ffffffffc02028c4:	c80007b7          	lui	a5,0xc8000
ffffffffc02028c8:	83b1                	srli	a5,a5,0xc
ffffffffc02028ca:	66e7e663          	bltu	a5,a4,ffffffffc0202f36 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028ce:	00093503          	ld	a0,0(s2)
ffffffffc02028d2:	64050263          	beqz	a0,ffffffffc0202f16 <pmm_init+0x7b0>
ffffffffc02028d6:	03451793          	slli	a5,a0,0x34
ffffffffc02028da:	62079e63          	bnez	a5,ffffffffc0202f16 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028de:	4601                	li	a2,0
ffffffffc02028e0:	4581                	li	a1,0
ffffffffc02028e2:	8b7ff0ef          	jal	ffffffffc0202198 <get_page>
ffffffffc02028e6:	240519e3          	bnez	a0,ffffffffc0203338 <pmm_init+0xbd2>
ffffffffc02028ea:	100027f3          	csrr	a5,sstatus
ffffffffc02028ee:	8b89                	andi	a5,a5,2
ffffffffc02028f0:	44079063          	bnez	a5,ffffffffc0202d30 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028f4:	000b3783          	ld	a5,0(s6)
ffffffffc02028f8:	4505                	li	a0,1
ffffffffc02028fa:	6f9c                	ld	a5,24(a5)
ffffffffc02028fc:	9782                	jalr	a5
ffffffffc02028fe:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202900:	00093503          	ld	a0,0(s2)
ffffffffc0202904:	4681                	li	a3,0
ffffffffc0202906:	4601                	li	a2,0
ffffffffc0202908:	85d2                	mv	a1,s4
ffffffffc020290a:	d67ff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc020290e:	280511e3          	bnez	a0,ffffffffc0203390 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202912:	00093503          	ld	a0,0(s2)
ffffffffc0202916:	4601                	li	a2,0
ffffffffc0202918:	4581                	li	a1,0
ffffffffc020291a:	e20ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc020291e:	240509e3          	beqz	a0,ffffffffc0203370 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202922:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202924:	0017f713          	andi	a4,a5,1
ffffffffc0202928:	58070f63          	beqz	a4,ffffffffc0202ec6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020292c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020292e:	078a                	slli	a5,a5,0x2
ffffffffc0202930:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202932:	58e7f863          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202936:	000bb683          	ld	a3,0(s7)
ffffffffc020293a:	079a                	slli	a5,a5,0x6
ffffffffc020293c:	fe000637          	lui	a2,0xfe000
ffffffffc0202940:	97b2                	add	a5,a5,a2
ffffffffc0202942:	97b6                	add	a5,a5,a3
ffffffffc0202944:	14fa1ae3          	bne	s4,a5,ffffffffc0203298 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202948:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e48>
ffffffffc020294c:	4785                	li	a5,1
ffffffffc020294e:	12f695e3          	bne	a3,a5,ffffffffc0203278 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202952:	00093503          	ld	a0,0(s2)
ffffffffc0202956:	77fd                	lui	a5,0xfffff
ffffffffc0202958:	6114                	ld	a3,0(a0)
ffffffffc020295a:	068a                	slli	a3,a3,0x2
ffffffffc020295c:	8efd                	and	a3,a3,a5
ffffffffc020295e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202962:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203260 <pmm_init+0xafa>
ffffffffc0202966:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020296a:	96e2                	add	a3,a3,s8
ffffffffc020296c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202970:	0a8a                	slli	s5,s5,0x2
ffffffffc0202972:	00fafab3          	and	s5,s5,a5
ffffffffc0202976:	00cad793          	srli	a5,s5,0xc
ffffffffc020297a:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0203246 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020297e:	4601                	li	a2,0
ffffffffc0202980:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202982:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202984:	db6ff0ef          	jal	ffffffffc0201f3a <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202988:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020298a:	05851ee3          	bne	a0,s8,ffffffffc02031e6 <pmm_init+0xa80>
ffffffffc020298e:	100027f3          	csrr	a5,sstatus
ffffffffc0202992:	8b89                	andi	a5,a5,2
ffffffffc0202994:	3e079b63          	bnez	a5,ffffffffc0202d8a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202998:	000b3783          	ld	a5,0(s6)
ffffffffc020299c:	4505                	li	a0,1
ffffffffc020299e:	6f9c                	ld	a5,24(a5)
ffffffffc02029a0:	9782                	jalr	a5
ffffffffc02029a2:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	46d1                	li	a3,20
ffffffffc02029aa:	6605                	lui	a2,0x1
ffffffffc02029ac:	85e2                	mv	a1,s8
ffffffffc02029ae:	cc3ff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc02029b2:	06051ae3          	bnez	a0,ffffffffc0203226 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029b6:	00093503          	ld	a0,0(s2)
ffffffffc02029ba:	4601                	li	a2,0
ffffffffc02029bc:	6585                	lui	a1,0x1
ffffffffc02029be:	d7cff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc02029c2:	040502e3          	beqz	a0,ffffffffc0203206 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029c6:	611c                	ld	a5,0(a0)
ffffffffc02029c8:	0107f713          	andi	a4,a5,16
ffffffffc02029cc:	7e070163          	beqz	a4,ffffffffc02031ae <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029d0:	8b91                	andi	a5,a5,4
ffffffffc02029d2:	7a078e63          	beqz	a5,ffffffffc020318e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029d6:	00093503          	ld	a0,0(s2)
ffffffffc02029da:	611c                	ld	a5,0(a0)
ffffffffc02029dc:	8bc1                	andi	a5,a5,16
ffffffffc02029de:	78078863          	beqz	a5,ffffffffc020316e <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029e2:	000c2703          	lw	a4,0(s8)
ffffffffc02029e6:	4785                	li	a5,1
ffffffffc02029e8:	76f71363          	bne	a4,a5,ffffffffc020314e <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029ec:	4681                	li	a3,0
ffffffffc02029ee:	6605                	lui	a2,0x1
ffffffffc02029f0:	85d2                	mv	a1,s4
ffffffffc02029f2:	c7fff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc02029f6:	72051c63          	bnez	a0,ffffffffc020312e <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02029fa:	000a2703          	lw	a4,0(s4)
ffffffffc02029fe:	4789                	li	a5,2
ffffffffc0202a00:	70f71763          	bne	a4,a5,ffffffffc020310e <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a04:	000c2783          	lw	a5,0(s8)
ffffffffc0202a08:	6e079363          	bnez	a5,ffffffffc02030ee <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a0c:	00093503          	ld	a0,0(s2)
ffffffffc0202a10:	4601                	li	a2,0
ffffffffc0202a12:	6585                	lui	a1,0x1
ffffffffc0202a14:	d26ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0202a18:	6a050b63          	beqz	a0,ffffffffc02030ce <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a1c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a1e:	00177793          	andi	a5,a4,1
ffffffffc0202a22:	4a078263          	beqz	a5,ffffffffc0202ec6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a26:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a28:	00271793          	slli	a5,a4,0x2
ffffffffc0202a2c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a2e:	48d7fa63          	bgeu	a5,a3,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a32:	000bb683          	ld	a3,0(s7)
ffffffffc0202a36:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a3a:	97d6                	add	a5,a5,s5
ffffffffc0202a3c:	079a                	slli	a5,a5,0x6
ffffffffc0202a3e:	97b6                	add	a5,a5,a3
ffffffffc0202a40:	66fa1763          	bne	s4,a5,ffffffffc02030ae <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a44:	8b41                	andi	a4,a4,16
ffffffffc0202a46:	64071463          	bnez	a4,ffffffffc020308e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a4a:	00093503          	ld	a0,0(s2)
ffffffffc0202a4e:	4581                	li	a1,0
ffffffffc0202a50:	b85ff0ef          	jal	ffffffffc02025d4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a54:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a58:	4785                	li	a5,1
ffffffffc0202a5a:	60fc9a63          	bne	s9,a5,ffffffffc020306e <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a5e:	000c2783          	lw	a5,0(s8)
ffffffffc0202a62:	5e079663          	bnez	a5,ffffffffc020304e <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a66:	00093503          	ld	a0,0(s2)
ffffffffc0202a6a:	6585                	lui	a1,0x1
ffffffffc0202a6c:	b69ff0ef          	jal	ffffffffc02025d4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a70:	000a2783          	lw	a5,0(s4)
ffffffffc0202a74:	52079d63          	bnez	a5,ffffffffc0202fae <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a78:	000c2783          	lw	a5,0(s8)
ffffffffc0202a7c:	50079963          	bnez	a5,ffffffffc0202f8e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a80:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a86:	000a3783          	ld	a5,0(s4)
ffffffffc0202a8a:	078a                	slli	a5,a5,0x2
ffffffffc0202a8c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a8e:	42e7fa63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a92:	000bb503          	ld	a0,0(s7)
ffffffffc0202a96:	97d6                	add	a5,a5,s5
ffffffffc0202a98:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202a9a:	00f506b3          	add	a3,a0,a5
ffffffffc0202a9e:	4294                	lw	a3,0(a3)
ffffffffc0202aa0:	4d969763          	bne	a3,s9,ffffffffc0202f6e <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202aa4:	8799                	srai	a5,a5,0x6
ffffffffc0202aa6:	00080637          	lui	a2,0x80
ffffffffc0202aaa:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202aac:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab0:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ab4:	0009b783          	ld	a5,0(s3)
ffffffffc0202ab8:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aba:	639c                	ld	a5,0(a5)
ffffffffc0202abc:	078a                	slli	a5,a5,0x2
ffffffffc0202abe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ac0:	40e7f163          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ac4:	8f91                	sub	a5,a5,a2
ffffffffc0202ac6:	079a                	slli	a5,a5,0x6
ffffffffc0202ac8:	953e                	add	a0,a0,a5
ffffffffc0202aca:	100027f3          	csrr	a5,sstatus
ffffffffc0202ace:	8b89                	andi	a5,a5,2
ffffffffc0202ad0:	30079863          	bnez	a5,ffffffffc0202de0 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202ad4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ad8:	4585                	li	a1,1
ffffffffc0202ada:	739c                	ld	a5,32(a5)
ffffffffc0202adc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ade:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202ae2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ae4:	078a                	slli	a5,a5,0x2
ffffffffc0202ae6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ae8:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aec:	000bb503          	ld	a0,0(s7)
ffffffffc0202af0:	fe000737          	lui	a4,0xfe000
ffffffffc0202af4:	079a                	slli	a5,a5,0x6
ffffffffc0202af6:	97ba                	add	a5,a5,a4
ffffffffc0202af8:	953e                	add	a0,a0,a5
ffffffffc0202afa:	100027f3          	csrr	a5,sstatus
ffffffffc0202afe:	8b89                	andi	a5,a5,2
ffffffffc0202b00:	2c079463          	bnez	a5,ffffffffc0202dc8 <pmm_init+0x662>
ffffffffc0202b04:	000b3783          	ld	a5,0(s6)
ffffffffc0202b08:	4585                	li	a1,1
ffffffffc0202b0a:	739c                	ld	a5,32(a5)
ffffffffc0202b0c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b0e:	00093783          	ld	a5,0(s2)
ffffffffc0202b12:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63a10>
    asm volatile("sfence.vma");
ffffffffc0202b16:	12000073          	sfence.vma
ffffffffc0202b1a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b1e:	8b89                	andi	a5,a5,2
ffffffffc0202b20:	28079a63          	bnez	a5,ffffffffc0202db4 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b24:	000b3783          	ld	a5,0(s6)
ffffffffc0202b28:	779c                	ld	a5,40(a5)
ffffffffc0202b2a:	9782                	jalr	a5
ffffffffc0202b2c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b2e:	4d441063          	bne	s0,s4,ffffffffc0202fee <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b32:	00004517          	auipc	a0,0x4
ffffffffc0202b36:	fbe50513          	addi	a0,a0,-66 # ffffffffc0206af0 <etext+0x12bc>
ffffffffc0202b3a:	e5afd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b42:	8b89                	andi	a5,a5,2
ffffffffc0202b44:	24079e63          	bnez	a5,ffffffffc0202da0 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b48:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4c:	779c                	ld	a5,40(a5)
ffffffffc0202b4e:	9782                	jalr	a5
ffffffffc0202b50:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b52:	609c                	ld	a5,0(s1)
ffffffffc0202b54:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b58:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b5a:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b5e:	6a85                	lui	s5,0x1
ffffffffc0202b60:	02e47c63          	bgeu	s0,a4,ffffffffc0202b98 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b64:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b68:	30f77063          	bgeu	a4,a5,ffffffffc0202e68 <pmm_init+0x702>
ffffffffc0202b6c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b70:	00093503          	ld	a0,0(s2)
ffffffffc0202b74:	4601                	li	a2,0
ffffffffc0202b76:	95a2                	add	a1,a1,s0
ffffffffc0202b78:	bc2ff0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0202b7c:	32050363          	beqz	a0,ffffffffc0202ea2 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b80:	611c                	ld	a5,0(a0)
ffffffffc0202b82:	078a                	slli	a5,a5,0x2
ffffffffc0202b84:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b88:	2e879d63          	bne	a5,s0,ffffffffc0202e82 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b8c:	609c                	ld	a5,0(s1)
ffffffffc0202b8e:	9456                	add	s0,s0,s5
ffffffffc0202b90:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b94:	fce468e3          	bltu	s0,a4,ffffffffc0202b64 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b98:	00093783          	ld	a5,0(s2)
ffffffffc0202b9c:	639c                	ld	a5,0(a5)
ffffffffc0202b9e:	42079863          	bnez	a5,ffffffffc0202fce <pmm_init+0x868>
ffffffffc0202ba2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba6:	8b89                	andi	a5,a5,2
ffffffffc0202ba8:	24079863          	bnez	a5,ffffffffc0202df8 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bac:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb0:	4505                	li	a0,1
ffffffffc0202bb2:	6f9c                	ld	a5,24(a5)
ffffffffc0202bb4:	9782                	jalr	a5
ffffffffc0202bb6:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bb8:	00093503          	ld	a0,0(s2)
ffffffffc0202bbc:	4699                	li	a3,6
ffffffffc0202bbe:	10000613          	li	a2,256
ffffffffc0202bc2:	85a2                	mv	a1,s0
ffffffffc0202bc4:	aadff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc0202bc8:	46051363          	bnez	a0,ffffffffc020302e <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202bcc:	4018                	lw	a4,0(s0)
ffffffffc0202bce:	4785                	li	a5,1
ffffffffc0202bd0:	42f71f63          	bne	a4,a5,ffffffffc020300e <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	6605                	lui	a2,0x1
ffffffffc0202bda:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202bde:	4699                	li	a3,6
ffffffffc0202be0:	85a2                	mv	a1,s0
ffffffffc0202be2:	a8fff0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc0202be6:	72051963          	bnez	a0,ffffffffc0203318 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202bea:	4018                	lw	a4,0(s0)
ffffffffc0202bec:	4789                	li	a5,2
ffffffffc0202bee:	70f71563          	bne	a4,a5,ffffffffc02032f8 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bf2:	00004597          	auipc	a1,0x4
ffffffffc0202bf6:	04658593          	addi	a1,a1,70 # ffffffffc0206c38 <etext+0x1404>
ffffffffc0202bfa:	10000513          	li	a0,256
ffffffffc0202bfe:	38d020ef          	jal	ffffffffc020578a <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c02:	6585                	lui	a1,0x1
ffffffffc0202c04:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202c08:	10000513          	li	a0,256
ffffffffc0202c0c:	391020ef          	jal	ffffffffc020579c <strcmp>
ffffffffc0202c10:	6c051463          	bnez	a0,ffffffffc02032d8 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c14:	000bb683          	ld	a3,0(s7)
ffffffffc0202c18:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c1c:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c1e:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c22:	8699                	srai	a3,a3,0x6
ffffffffc0202c24:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c26:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c2a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c2e:	32e7f463          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c32:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c36:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c3a:	97b6                	add	a5,a5,a3
ffffffffc0202c3c:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f48>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c40:	317020ef          	jal	ffffffffc0205756 <strlen>
ffffffffc0202c44:	66051a63          	bnez	a0,ffffffffc02032b8 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c48:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c4c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4e:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63a10>
ffffffffc0202c52:	078a                	slli	a5,a5,0x2
ffffffffc0202c54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	26e7f663          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c5a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c5e:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f56 <pmm_init+0x7f0>
ffffffffc0202c62:	0009b783          	ld	a5,0(s3)
ffffffffc0202c66:	00f689b3          	add	s3,a3,a5
ffffffffc0202c6a:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6e:	8b89                	andi	a5,a5,2
ffffffffc0202c70:	1e079163          	bnez	a5,ffffffffc0202e52 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c74:	000b3783          	ld	a5,0(s6)
ffffffffc0202c78:	8522                	mv	a0,s0
ffffffffc0202c7a:	4585                	li	a1,1
ffffffffc0202c7c:	739c                	ld	a5,32(a5)
ffffffffc0202c7e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c80:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c86:	078a                	slli	a5,a5,0x2
ffffffffc0202c88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c8a:	22e7fc63          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c8e:	000bb503          	ld	a0,0(s7)
ffffffffc0202c92:	fe000737          	lui	a4,0xfe000
ffffffffc0202c96:	079a                	slli	a5,a5,0x6
ffffffffc0202c98:	97ba                	add	a5,a5,a4
ffffffffc0202c9a:	953e                	add	a0,a0,a5
ffffffffc0202c9c:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca0:	8b89                	andi	a5,a5,2
ffffffffc0202ca2:	18079c63          	bnez	a5,ffffffffc0202e3a <pmm_init+0x6d4>
ffffffffc0202ca6:	000b3783          	ld	a5,0(s6)
ffffffffc0202caa:	4585                	li	a1,1
ffffffffc0202cac:	739c                	ld	a5,32(a5)
ffffffffc0202cae:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cb4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb6:	078a                	slli	a5,a5,0x2
ffffffffc0202cb8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cba:	20e7f463          	bgeu	a5,a4,ffffffffc0202ec2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cbe:	000bb503          	ld	a0,0(s7)
ffffffffc0202cc2:	fe000737          	lui	a4,0xfe000
ffffffffc0202cc6:	079a                	slli	a5,a5,0x6
ffffffffc0202cc8:	97ba                	add	a5,a5,a4
ffffffffc0202cca:	953e                	add	a0,a0,a5
ffffffffc0202ccc:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd0:	8b89                	andi	a5,a5,2
ffffffffc0202cd2:	14079863          	bnez	a5,ffffffffc0202e22 <pmm_init+0x6bc>
ffffffffc0202cd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cda:	4585                	li	a1,1
ffffffffc0202cdc:	739c                	ld	a5,32(a5)
ffffffffc0202cde:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ce0:	00093783          	ld	a5,0(s2)
ffffffffc0202ce4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ce8:	12000073          	sfence.vma
ffffffffc0202cec:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf0:	8b89                	andi	a5,a5,2
ffffffffc0202cf2:	10079e63          	bnez	a5,ffffffffc0202e0e <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfa:	779c                	ld	a5,40(a5)
ffffffffc0202cfc:	9782                	jalr	a5
ffffffffc0202cfe:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d00:	1e8c1b63          	bne	s8,s0,ffffffffc0202ef6 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d04:	00004517          	auipc	a0,0x4
ffffffffc0202d08:	fac50513          	addi	a0,a0,-84 # ffffffffc0206cb0 <etext+0x147c>
ffffffffc0202d0c:	c88fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d10:	7406                	ld	s0,96(sp)
ffffffffc0202d12:	70a6                	ld	ra,104(sp)
ffffffffc0202d14:	64e6                	ld	s1,88(sp)
ffffffffc0202d16:	6946                	ld	s2,80(sp)
ffffffffc0202d18:	69a6                	ld	s3,72(sp)
ffffffffc0202d1a:	6a06                	ld	s4,64(sp)
ffffffffc0202d1c:	7ae2                	ld	s5,56(sp)
ffffffffc0202d1e:	7b42                	ld	s6,48(sp)
ffffffffc0202d20:	7ba2                	ld	s7,40(sp)
ffffffffc0202d22:	7c02                	ld	s8,32(sp)
ffffffffc0202d24:	6ce2                	ld	s9,24(sp)
ffffffffc0202d26:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d28:	f85fe06f          	j	ffffffffc0201cac <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d2c:	853e                	mv	a0,a5
ffffffffc0202d2e:	b4e1                	j	ffffffffc02027f6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d30:	bd5fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d34:	000b3783          	ld	a5,0(s6)
ffffffffc0202d38:	4505                	li	a0,1
ffffffffc0202d3a:	6f9c                	ld	a5,24(a5)
ffffffffc0202d3c:	9782                	jalr	a5
ffffffffc0202d3e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d40:	bbffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d44:	be75                	j	ffffffffc0202900 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d46:	bbffd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d4a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d4e:	779c                	ld	a5,40(a5)
ffffffffc0202d50:	9782                	jalr	a5
ffffffffc0202d52:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d54:	babfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d58:	b6ad                	j	ffffffffc02028c2 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d5a:	6705                	lui	a4,0x1
ffffffffc0202d5c:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc0202d5e:	96ba                	add	a3,a3,a4
ffffffffc0202d60:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d62:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d66:	14a77e63          	bgeu	a4,a0,ffffffffc0202ec2 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d6a:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d6e:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d70:	071a                	slli	a4,a4,0x6
ffffffffc0202d72:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d76:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d78:	6a9c                	ld	a5,16(a3)
ffffffffc0202d7a:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d7e:	00e60533          	add	a0,a2,a4
ffffffffc0202d82:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d84:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d88:	bcf1                	j	ffffffffc0202864 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d8a:	b7bfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d92:	4505                	li	a0,1
ffffffffc0202d94:	6f9c                	ld	a5,24(a5)
ffffffffc0202d96:	9782                	jalr	a5
ffffffffc0202d98:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d9a:	b65fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d9e:	b119                	j	ffffffffc02029a4 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202da0:	b65fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202da4:	000b3783          	ld	a5,0(s6)
ffffffffc0202da8:	779c                	ld	a5,40(a5)
ffffffffc0202daa:	9782                	jalr	a5
ffffffffc0202dac:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dae:	b51fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202db2:	b345                	j	ffffffffc0202b52 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202db4:	b51fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202db8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dbc:	779c                	ld	a5,40(a5)
ffffffffc0202dbe:	9782                	jalr	a5
ffffffffc0202dc0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc2:	b3dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dc6:	b3a5                	j	ffffffffc0202b2e <pmm_init+0x3c8>
ffffffffc0202dc8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dca:	b3bfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dce:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd2:	6522                	ld	a0,8(sp)
ffffffffc0202dd4:	4585                	li	a1,1
ffffffffc0202dd6:	739c                	ld	a5,32(a5)
ffffffffc0202dd8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dda:	b25fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dde:	bb05                	j	ffffffffc0202b0e <pmm_init+0x3a8>
ffffffffc0202de0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202de2:	b23fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202de6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dea:	6522                	ld	a0,8(sp)
ffffffffc0202dec:	4585                	li	a1,1
ffffffffc0202dee:	739c                	ld	a5,32(a5)
ffffffffc0202df0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202df2:	b0dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202df6:	b1e5                	j	ffffffffc0202ade <pmm_init+0x378>
        intr_disable();
ffffffffc0202df8:	b0dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dfc:	000b3783          	ld	a5,0(s6)
ffffffffc0202e00:	4505                	li	a0,1
ffffffffc0202e02:	6f9c                	ld	a5,24(a5)
ffffffffc0202e04:	9782                	jalr	a5
ffffffffc0202e06:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e08:	af7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e0c:	b375                	j	ffffffffc0202bb8 <pmm_init+0x452>
        intr_disable();
ffffffffc0202e0e:	af7fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e12:	000b3783          	ld	a5,0(s6)
ffffffffc0202e16:	779c                	ld	a5,40(a5)
ffffffffc0202e18:	9782                	jalr	a5
ffffffffc0202e1a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e1c:	ae3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e20:	b5c5                	j	ffffffffc0202d00 <pmm_init+0x59a>
ffffffffc0202e22:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e24:	ae1fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e28:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2c:	6522                	ld	a0,8(sp)
ffffffffc0202e2e:	4585                	li	a1,1
ffffffffc0202e30:	739c                	ld	a5,32(a5)
ffffffffc0202e32:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e34:	acbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e38:	b565                	j	ffffffffc0202ce0 <pmm_init+0x57a>
ffffffffc0202e3a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e3c:	ac9fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e40:	000b3783          	ld	a5,0(s6)
ffffffffc0202e44:	6522                	ld	a0,8(sp)
ffffffffc0202e46:	4585                	li	a1,1
ffffffffc0202e48:	739c                	ld	a5,32(a5)
ffffffffc0202e4a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e4c:	ab3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e50:	b585                	j	ffffffffc0202cb0 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e52:	ab3fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e56:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5a:	8522                	mv	a0,s0
ffffffffc0202e5c:	4585                	li	a1,1
ffffffffc0202e5e:	739c                	ld	a5,32(a5)
ffffffffc0202e60:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e62:	a9dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e66:	bd29                	j	ffffffffc0202c80 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e68:	86a2                	mv	a3,s0
ffffffffc0202e6a:	00003617          	auipc	a2,0x3
ffffffffc0202e6e:	75e60613          	addi	a2,a2,1886 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202e72:	25c00593          	li	a1,604
ffffffffc0202e76:	00004517          	auipc	a0,0x4
ffffffffc0202e7a:	84250513          	addi	a0,a0,-1982 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202e7e:	dc8fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e82:	00004697          	auipc	a3,0x4
ffffffffc0202e86:	cce68693          	addi	a3,a3,-818 # ffffffffc0206b50 <etext+0x131c>
ffffffffc0202e8a:	00003617          	auipc	a2,0x3
ffffffffc0202e8e:	38e60613          	addi	a2,a2,910 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202e92:	25d00593          	li	a1,605
ffffffffc0202e96:	00004517          	auipc	a0,0x4
ffffffffc0202e9a:	82250513          	addi	a0,a0,-2014 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202e9e:	da8fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ea2:	00004697          	auipc	a3,0x4
ffffffffc0202ea6:	c6e68693          	addi	a3,a3,-914 # ffffffffc0206b10 <etext+0x12dc>
ffffffffc0202eaa:	00003617          	auipc	a2,0x3
ffffffffc0202eae:	36e60613          	addi	a2,a2,878 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202eb2:	25c00593          	li	a1,604
ffffffffc0202eb6:	00004517          	auipc	a0,0x4
ffffffffc0202eba:	80250513          	addi	a0,a0,-2046 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202ebe:	d88fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202ec2:	fb5fe0ef          	jal	ffffffffc0201e76 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202ec6:	00004617          	auipc	a2,0x4
ffffffffc0202eca:	9ea60613          	addi	a2,a2,-1558 # ffffffffc02068b0 <etext+0x107c>
ffffffffc0202ece:	07f00593          	li	a1,127
ffffffffc0202ed2:	00003517          	auipc	a0,0x3
ffffffffc0202ed6:	71e50513          	addi	a0,a0,1822 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0202eda:	d6cfd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202ede:	00004617          	auipc	a2,0x4
ffffffffc0202ee2:	84a60613          	addi	a2,a2,-1974 # ffffffffc0206728 <etext+0xef4>
ffffffffc0202ee6:	06500593          	li	a1,101
ffffffffc0202eea:	00003517          	auipc	a0,0x3
ffffffffc0202eee:	7ce50513          	addi	a0,a0,1998 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202ef2:	d54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ef6:	00004697          	auipc	a3,0x4
ffffffffc0202efa:	bd268693          	addi	a3,a3,-1070 # ffffffffc0206ac8 <etext+0x1294>
ffffffffc0202efe:	00003617          	auipc	a2,0x3
ffffffffc0202f02:	31a60613          	addi	a2,a2,794 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202f06:	27700593          	li	a1,631
ffffffffc0202f0a:	00003517          	auipc	a0,0x3
ffffffffc0202f0e:	7ae50513          	addi	a0,a0,1966 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202f12:	d34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f16:	00004697          	auipc	a3,0x4
ffffffffc0202f1a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc02067e0 <etext+0xfac>
ffffffffc0202f1e:	00003617          	auipc	a2,0x3
ffffffffc0202f22:	2fa60613          	addi	a2,a2,762 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202f26:	21e00593          	li	a1,542
ffffffffc0202f2a:	00003517          	auipc	a0,0x3
ffffffffc0202f2e:	78e50513          	addi	a0,a0,1934 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202f32:	d14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f36:	00004697          	auipc	a3,0x4
ffffffffc0202f3a:	88a68693          	addi	a3,a3,-1910 # ffffffffc02067c0 <etext+0xf8c>
ffffffffc0202f3e:	00003617          	auipc	a2,0x3
ffffffffc0202f42:	2da60613          	addi	a2,a2,730 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202f46:	21d00593          	li	a1,541
ffffffffc0202f4a:	00003517          	auipc	a0,0x3
ffffffffc0202f4e:	76e50513          	addi	a0,a0,1902 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202f52:	cf4fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f56:	00003617          	auipc	a2,0x3
ffffffffc0202f5a:	67260613          	addi	a2,a2,1650 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0202f5e:	07100593          	li	a1,113
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	68e50513          	addi	a0,a0,1678 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0202f6a:	cdcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f6e:	00004697          	auipc	a3,0x4
ffffffffc0202f72:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0206a98 <etext+0x1264>
ffffffffc0202f76:	00003617          	auipc	a2,0x3
ffffffffc0202f7a:	2a260613          	addi	a2,a2,674 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202f7e:	24500593          	li	a1,581
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	73650513          	addi	a0,a0,1846 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202f8a:	cbcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f8e:	00004697          	auipc	a3,0x4
ffffffffc0202f92:	ac268693          	addi	a3,a3,-1342 # ffffffffc0206a50 <etext+0x121c>
ffffffffc0202f96:	00003617          	auipc	a2,0x3
ffffffffc0202f9a:	28260613          	addi	a2,a2,642 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202f9e:	24300593          	li	a1,579
ffffffffc0202fa2:	00003517          	auipc	a0,0x3
ffffffffc0202fa6:	71650513          	addi	a0,a0,1814 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202faa:	c9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fae:	00004697          	auipc	a3,0x4
ffffffffc0202fb2:	ad268693          	addi	a3,a3,-1326 # ffffffffc0206a80 <etext+0x124c>
ffffffffc0202fb6:	00003617          	auipc	a2,0x3
ffffffffc0202fba:	26260613          	addi	a2,a2,610 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202fbe:	24200593          	li	a1,578
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	6f650513          	addi	a0,a0,1782 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202fca:	c7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fce:	00004697          	auipc	a3,0x4
ffffffffc0202fd2:	b9a68693          	addi	a3,a3,-1126 # ffffffffc0206b68 <etext+0x1334>
ffffffffc0202fd6:	00003617          	auipc	a2,0x3
ffffffffc0202fda:	24260613          	addi	a2,a2,578 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202fde:	26000593          	li	a1,608
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	6d650513          	addi	a0,a0,1750 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0202fea:	c5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fee:	00004697          	auipc	a3,0x4
ffffffffc0202ff2:	ada68693          	addi	a3,a3,-1318 # ffffffffc0206ac8 <etext+0x1294>
ffffffffc0202ff6:	00003617          	auipc	a2,0x3
ffffffffc0202ffa:	22260613          	addi	a2,a2,546 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0202ffe:	24d00593          	li	a1,589
ffffffffc0203002:	00003517          	auipc	a0,0x3
ffffffffc0203006:	6b650513          	addi	a0,a0,1718 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020300a:	c3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020300e:	00004697          	auipc	a3,0x4
ffffffffc0203012:	bb268693          	addi	a3,a3,-1102 # ffffffffc0206bc0 <etext+0x138c>
ffffffffc0203016:	00003617          	auipc	a2,0x3
ffffffffc020301a:	20260613          	addi	a2,a2,514 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020301e:	26500593          	li	a1,613
ffffffffc0203022:	00003517          	auipc	a0,0x3
ffffffffc0203026:	69650513          	addi	a0,a0,1686 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020302a:	c1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020302e:	00004697          	auipc	a3,0x4
ffffffffc0203032:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206b80 <etext+0x134c>
ffffffffc0203036:	00003617          	auipc	a2,0x3
ffffffffc020303a:	1e260613          	addi	a2,a2,482 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020303e:	26400593          	li	a1,612
ffffffffc0203042:	00003517          	auipc	a0,0x3
ffffffffc0203046:	67650513          	addi	a0,a0,1654 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020304a:	bfcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020304e:	00004697          	auipc	a3,0x4
ffffffffc0203052:	a0268693          	addi	a3,a3,-1534 # ffffffffc0206a50 <etext+0x121c>
ffffffffc0203056:	00003617          	auipc	a2,0x3
ffffffffc020305a:	1c260613          	addi	a2,a2,450 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020305e:	23f00593          	li	a1,575
ffffffffc0203062:	00003517          	auipc	a0,0x3
ffffffffc0203066:	65650513          	addi	a0,a0,1622 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020306a:	bdcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020306e:	00004697          	auipc	a3,0x4
ffffffffc0203072:	88268693          	addi	a3,a3,-1918 # ffffffffc02068f0 <etext+0x10bc>
ffffffffc0203076:	00003617          	auipc	a2,0x3
ffffffffc020307a:	1a260613          	addi	a2,a2,418 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020307e:	23e00593          	li	a1,574
ffffffffc0203082:	00003517          	auipc	a0,0x3
ffffffffc0203086:	63650513          	addi	a0,a0,1590 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020308a:	bbcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020308e:	00004697          	auipc	a3,0x4
ffffffffc0203092:	9da68693          	addi	a3,a3,-1574 # ffffffffc0206a68 <etext+0x1234>
ffffffffc0203096:	00003617          	auipc	a2,0x3
ffffffffc020309a:	18260613          	addi	a2,a2,386 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020309e:	23b00593          	li	a1,571
ffffffffc02030a2:	00003517          	auipc	a0,0x3
ffffffffc02030a6:	61650513          	addi	a0,a0,1558 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02030aa:	b9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030ae:	00004697          	auipc	a3,0x4
ffffffffc02030b2:	82a68693          	addi	a3,a3,-2006 # ffffffffc02068d8 <etext+0x10a4>
ffffffffc02030b6:	00003617          	auipc	a2,0x3
ffffffffc02030ba:	16260613          	addi	a2,a2,354 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02030be:	23a00593          	li	a1,570
ffffffffc02030c2:	00003517          	auipc	a0,0x3
ffffffffc02030c6:	5f650513          	addi	a0,a0,1526 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02030ca:	b7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030ce:	00004697          	auipc	a3,0x4
ffffffffc02030d2:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0206978 <etext+0x1144>
ffffffffc02030d6:	00003617          	auipc	a2,0x3
ffffffffc02030da:	14260613          	addi	a2,a2,322 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02030de:	23900593          	li	a1,569
ffffffffc02030e2:	00003517          	auipc	a0,0x3
ffffffffc02030e6:	5d650513          	addi	a0,a0,1494 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02030ea:	b5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030ee:	00004697          	auipc	a3,0x4
ffffffffc02030f2:	96268693          	addi	a3,a3,-1694 # ffffffffc0206a50 <etext+0x121c>
ffffffffc02030f6:	00003617          	auipc	a2,0x3
ffffffffc02030fa:	12260613          	addi	a2,a2,290 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02030fe:	23800593          	li	a1,568
ffffffffc0203102:	00003517          	auipc	a0,0x3
ffffffffc0203106:	5b650513          	addi	a0,a0,1462 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020310a:	b3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020310e:	00004697          	auipc	a3,0x4
ffffffffc0203112:	92a68693          	addi	a3,a3,-1750 # ffffffffc0206a38 <etext+0x1204>
ffffffffc0203116:	00003617          	auipc	a2,0x3
ffffffffc020311a:	10260613          	addi	a2,a2,258 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020311e:	23700593          	li	a1,567
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	59650513          	addi	a0,a0,1430 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020312a:	b1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020312e:	00004697          	auipc	a3,0x4
ffffffffc0203132:	8da68693          	addi	a3,a3,-1830 # ffffffffc0206a08 <etext+0x11d4>
ffffffffc0203136:	00003617          	auipc	a2,0x3
ffffffffc020313a:	0e260613          	addi	a2,a2,226 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020313e:	23600593          	li	a1,566
ffffffffc0203142:	00003517          	auipc	a0,0x3
ffffffffc0203146:	57650513          	addi	a0,a0,1398 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020314a:	afcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020314e:	00004697          	auipc	a3,0x4
ffffffffc0203152:	8a268693          	addi	a3,a3,-1886 # ffffffffc02069f0 <etext+0x11bc>
ffffffffc0203156:	00003617          	auipc	a2,0x3
ffffffffc020315a:	0c260613          	addi	a2,a2,194 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020315e:	23400593          	li	a1,564
ffffffffc0203162:	00003517          	auipc	a0,0x3
ffffffffc0203166:	55650513          	addi	a0,a0,1366 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020316a:	adcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020316e:	00004697          	auipc	a3,0x4
ffffffffc0203172:	86268693          	addi	a3,a3,-1950 # ffffffffc02069d0 <etext+0x119c>
ffffffffc0203176:	00003617          	auipc	a2,0x3
ffffffffc020317a:	0a260613          	addi	a2,a2,162 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020317e:	23300593          	li	a1,563
ffffffffc0203182:	00003517          	auipc	a0,0x3
ffffffffc0203186:	53650513          	addi	a0,a0,1334 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020318a:	abcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020318e:	00004697          	auipc	a3,0x4
ffffffffc0203192:	83268693          	addi	a3,a3,-1998 # ffffffffc02069c0 <etext+0x118c>
ffffffffc0203196:	00003617          	auipc	a2,0x3
ffffffffc020319a:	08260613          	addi	a2,a2,130 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020319e:	23200593          	li	a1,562
ffffffffc02031a2:	00003517          	auipc	a0,0x3
ffffffffc02031a6:	51650513          	addi	a0,a0,1302 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02031aa:	a9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031ae:	00004697          	auipc	a3,0x4
ffffffffc02031b2:	80268693          	addi	a3,a3,-2046 # ffffffffc02069b0 <etext+0x117c>
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	06260613          	addi	a2,a2,98 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02031be:	23100593          	li	a1,561
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	4f650513          	addi	a0,a0,1270 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02031ca:	a7cfd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031ce:	00003617          	auipc	a2,0x3
ffffffffc02031d2:	4a260613          	addi	a2,a2,1186 # ffffffffc0206670 <etext+0xe3c>
ffffffffc02031d6:	08100593          	li	a1,129
ffffffffc02031da:	00003517          	auipc	a0,0x3
ffffffffc02031de:	4de50513          	addi	a0,a0,1246 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02031e2:	a64fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02031e6:	00003697          	auipc	a3,0x3
ffffffffc02031ea:	72268693          	addi	a3,a3,1826 # ffffffffc0206908 <etext+0x10d4>
ffffffffc02031ee:	00003617          	auipc	a2,0x3
ffffffffc02031f2:	02a60613          	addi	a2,a2,42 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02031f6:	22c00593          	li	a1,556
ffffffffc02031fa:	00003517          	auipc	a0,0x3
ffffffffc02031fe:	4be50513          	addi	a0,a0,1214 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203202:	a44fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203206:	00003697          	auipc	a3,0x3
ffffffffc020320a:	77268693          	addi	a3,a3,1906 # ffffffffc0206978 <etext+0x1144>
ffffffffc020320e:	00003617          	auipc	a2,0x3
ffffffffc0203212:	00a60613          	addi	a2,a2,10 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203216:	23000593          	li	a1,560
ffffffffc020321a:	00003517          	auipc	a0,0x3
ffffffffc020321e:	49e50513          	addi	a0,a0,1182 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203222:	a24fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203226:	00003697          	auipc	a3,0x3
ffffffffc020322a:	71268693          	addi	a3,a3,1810 # ffffffffc0206938 <etext+0x1104>
ffffffffc020322e:	00003617          	auipc	a2,0x3
ffffffffc0203232:	fea60613          	addi	a2,a2,-22 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203236:	22f00593          	li	a1,559
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	47e50513          	addi	a0,a0,1150 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203242:	a04fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203246:	86d6                	mv	a3,s5
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	38060613          	addi	a2,a2,896 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0203250:	22b00593          	li	a1,555
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	46450513          	addi	a0,a0,1124 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020325c:	9eafd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203260:	00003617          	auipc	a2,0x3
ffffffffc0203264:	36860613          	addi	a2,a2,872 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0203268:	22a00593          	li	a1,554
ffffffffc020326c:	00003517          	auipc	a0,0x3
ffffffffc0203270:	44c50513          	addi	a0,a0,1100 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203274:	9d2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203278:	00003697          	auipc	a3,0x3
ffffffffc020327c:	67868693          	addi	a3,a3,1656 # ffffffffc02068f0 <etext+0x10bc>
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	f9860613          	addi	a2,a2,-104 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203288:	22800593          	li	a1,552
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	42c50513          	addi	a0,a0,1068 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203294:	9b2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203298:	00003697          	auipc	a3,0x3
ffffffffc020329c:	64068693          	addi	a3,a3,1600 # ffffffffc02068d8 <etext+0x10a4>
ffffffffc02032a0:	00003617          	auipc	a2,0x3
ffffffffc02032a4:	f7860613          	addi	a2,a2,-136 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02032a8:	22700593          	li	a1,551
ffffffffc02032ac:	00003517          	auipc	a0,0x3
ffffffffc02032b0:	40c50513          	addi	a0,a0,1036 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02032b4:	992fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032b8:	00004697          	auipc	a3,0x4
ffffffffc02032bc:	9d068693          	addi	a3,a3,-1584 # ffffffffc0206c88 <etext+0x1454>
ffffffffc02032c0:	00003617          	auipc	a2,0x3
ffffffffc02032c4:	f5860613          	addi	a2,a2,-168 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02032c8:	26e00593          	li	a1,622
ffffffffc02032cc:	00003517          	auipc	a0,0x3
ffffffffc02032d0:	3ec50513          	addi	a0,a0,1004 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02032d4:	972fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032d8:	00004697          	auipc	a3,0x4
ffffffffc02032dc:	97868693          	addi	a3,a3,-1672 # ffffffffc0206c50 <etext+0x141c>
ffffffffc02032e0:	00003617          	auipc	a2,0x3
ffffffffc02032e4:	f3860613          	addi	a2,a2,-200 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02032e8:	26b00593          	li	a1,619
ffffffffc02032ec:	00003517          	auipc	a0,0x3
ffffffffc02032f0:	3cc50513          	addi	a0,a0,972 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02032f4:	952fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032f8:	00004697          	auipc	a3,0x4
ffffffffc02032fc:	92868693          	addi	a3,a3,-1752 # ffffffffc0206c20 <etext+0x13ec>
ffffffffc0203300:	00003617          	auipc	a2,0x3
ffffffffc0203304:	f1860613          	addi	a2,a2,-232 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203308:	26700593          	li	a1,615
ffffffffc020330c:	00003517          	auipc	a0,0x3
ffffffffc0203310:	3ac50513          	addi	a0,a0,940 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203314:	932fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203318:	00004697          	auipc	a3,0x4
ffffffffc020331c:	8c068693          	addi	a3,a3,-1856 # ffffffffc0206bd8 <etext+0x13a4>
ffffffffc0203320:	00003617          	auipc	a2,0x3
ffffffffc0203324:	ef860613          	addi	a2,a2,-264 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203328:	26600593          	li	a1,614
ffffffffc020332c:	00003517          	auipc	a0,0x3
ffffffffc0203330:	38c50513          	addi	a0,a0,908 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203334:	912fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203338:	00003697          	auipc	a3,0x3
ffffffffc020333c:	4e868693          	addi	a3,a3,1256 # ffffffffc0206820 <etext+0xfec>
ffffffffc0203340:	00003617          	auipc	a2,0x3
ffffffffc0203344:	ed860613          	addi	a2,a2,-296 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203348:	21f00593          	li	a1,543
ffffffffc020334c:	00003517          	auipc	a0,0x3
ffffffffc0203350:	36c50513          	addi	a0,a0,876 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203354:	8f2fd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203358:	00003617          	auipc	a2,0x3
ffffffffc020335c:	31860613          	addi	a2,a2,792 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0203360:	0c900593          	li	a1,201
ffffffffc0203364:	00003517          	auipc	a0,0x3
ffffffffc0203368:	35450513          	addi	a0,a0,852 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020336c:	8dafd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203370:	00003697          	auipc	a3,0x3
ffffffffc0203374:	51068693          	addi	a3,a3,1296 # ffffffffc0206880 <etext+0x104c>
ffffffffc0203378:	00003617          	auipc	a2,0x3
ffffffffc020337c:	ea060613          	addi	a2,a2,-352 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203380:	22600593          	li	a1,550
ffffffffc0203384:	00003517          	auipc	a0,0x3
ffffffffc0203388:	33450513          	addi	a0,a0,820 # ffffffffc02066b8 <etext+0xe84>
ffffffffc020338c:	8bafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203390:	00003697          	auipc	a3,0x3
ffffffffc0203394:	4c068693          	addi	a3,a3,1216 # ffffffffc0206850 <etext+0x101c>
ffffffffc0203398:	00003617          	auipc	a2,0x3
ffffffffc020339c:	e8060613          	addi	a2,a2,-384 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02033a0:	22300593          	li	a1,547
ffffffffc02033a4:	00003517          	auipc	a0,0x3
ffffffffc02033a8:	31450513          	addi	a0,a0,788 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02033ac:	89afd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02033b0 <copy_range>:
{
ffffffffc02033b0:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033b2:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033b6:	e43a                	sd	a4,8(sp)
ffffffffc02033b8:	fc86                	sd	ra,120(sp)
ffffffffc02033ba:	f8a2                	sd	s0,112(sp)
ffffffffc02033bc:	f4a6                	sd	s1,104(sp)
ffffffffc02033be:	f0ca                	sd	s2,96(sp)
ffffffffc02033c0:	ecce                	sd	s3,88(sp)
ffffffffc02033c2:	e8d2                	sd	s4,80(sp)
ffffffffc02033c4:	e4d6                	sd	s5,72(sp)
ffffffffc02033c6:	e0da                	sd	s6,64(sp)
ffffffffc02033c8:	fc5e                	sd	s7,56(sp)
ffffffffc02033ca:	f862                	sd	s8,48(sp)
ffffffffc02033cc:	f466                	sd	s9,40(sp)
ffffffffc02033ce:	f06a                	sd	s10,32(sp)
ffffffffc02033d0:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033d2:	03479713          	slli	a4,a5,0x34
ffffffffc02033d6:	26071163          	bnez	a4,ffffffffc0203638 <copy_range+0x288>
    assert(USER_ACCESS(start, end));
ffffffffc02033da:	002007b7          	lui	a5,0x200
ffffffffc02033de:	00d63733          	sltu	a4,a2,a3
ffffffffc02033e2:	00f637b3          	sltu	a5,a2,a5
ffffffffc02033e6:	00173713          	seqz	a4,a4
ffffffffc02033ea:	8fd9                	or	a5,a5,a4
ffffffffc02033ec:	8432                	mv	s0,a2
ffffffffc02033ee:	8936                	mv	s2,a3
ffffffffc02033f0:	22079463          	bnez	a5,ffffffffc0203618 <copy_range+0x268>
ffffffffc02033f4:	4785                	li	a5,1
ffffffffc02033f6:	07fe                	slli	a5,a5,0x1f
ffffffffc02033f8:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc02033fa:	20f6ff63          	bgeu	a3,a5,ffffffffc0203618 <copy_range+0x268>
ffffffffc02033fe:	5bfd                	li	s7,-1
ffffffffc0203400:	8a2a                	mv	s4,a0
ffffffffc0203402:	84ae                	mv	s1,a1
ffffffffc0203404:	6985                	lui	s3,0x1
ffffffffc0203406:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage)
ffffffffc020340a:	00098b17          	auipc	s6,0x98
ffffffffc020340e:	1b6b0b13          	addi	s6,s6,438 # ffffffffc029b5c0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203412:	00098a97          	auipc	s5,0x98
ffffffffc0203416:	1b6a8a93          	addi	s5,s5,438 # ffffffffc029b5c8 <pages>
ffffffffc020341a:	fff80c37          	lui	s8,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020341e:	4601                	li	a2,0
ffffffffc0203420:	85a2                	mv	a1,s0
ffffffffc0203422:	8526                	mv	a0,s1
ffffffffc0203424:	b17fe0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0203428:	8d2a                	mv	s10,a0
        if (ptep == NULL)
ffffffffc020342a:	c545                	beqz	a0,ffffffffc02034d2 <copy_range+0x122>
        if (*ptep & PTE_V)
ffffffffc020342c:	611c                	ld	a5,0(a0)
ffffffffc020342e:	8b85                	andi	a5,a5,1
ffffffffc0203430:	e78d                	bnez	a5,ffffffffc020345a <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203432:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0203434:	c019                	beqz	s0,ffffffffc020343a <copy_range+0x8a>
ffffffffc0203436:	ff2464e3          	bltu	s0,s2,ffffffffc020341e <copy_range+0x6e>
    return 0;
ffffffffc020343a:	4501                	li	a0,0
}
ffffffffc020343c:	70e6                	ld	ra,120(sp)
ffffffffc020343e:	7446                	ld	s0,112(sp)
ffffffffc0203440:	74a6                	ld	s1,104(sp)
ffffffffc0203442:	7906                	ld	s2,96(sp)
ffffffffc0203444:	69e6                	ld	s3,88(sp)
ffffffffc0203446:	6a46                	ld	s4,80(sp)
ffffffffc0203448:	6aa6                	ld	s5,72(sp)
ffffffffc020344a:	6b06                	ld	s6,64(sp)
ffffffffc020344c:	7be2                	ld	s7,56(sp)
ffffffffc020344e:	7c42                	ld	s8,48(sp)
ffffffffc0203450:	7ca2                	ld	s9,40(sp)
ffffffffc0203452:	7d02                	ld	s10,32(sp)
ffffffffc0203454:	6de2                	ld	s11,24(sp)
ffffffffc0203456:	6109                	addi	sp,sp,128
ffffffffc0203458:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020345a:	4605                	li	a2,1
ffffffffc020345c:	85a2                	mv	a1,s0
ffffffffc020345e:	8552                	mv	a0,s4
ffffffffc0203460:	adbfe0ef          	jal	ffffffffc0201f3a <get_pte>
ffffffffc0203464:	10050663          	beqz	a0,ffffffffc0203570 <copy_range+0x1c0>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203468:	000d3d83          	ld	s11,0(s10)
    if (!(pte & PTE_V))
ffffffffc020346c:	001df793          	andi	a5,s11,1
ffffffffc0203470:	12078e63          	beqz	a5,ffffffffc02035ac <copy_range+0x1fc>
    if (PPN(pa) >= npage)
ffffffffc0203474:	000b3703          	ld	a4,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203478:	002d9793          	slli	a5,s11,0x2
ffffffffc020347c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020347e:	10e7fb63          	bgeu	a5,a4,ffffffffc0203594 <copy_range+0x1e4>
    return &pages[PPN(pa) - nbase];
ffffffffc0203482:	000abd03          	ld	s10,0(s5)
ffffffffc0203486:	97e2                	add	a5,a5,s8
ffffffffc0203488:	079a                	slli	a5,a5,0x6
ffffffffc020348a:	9d3e                	add	s10,s10,a5
            assert(page != NULL);
ffffffffc020348c:	0e0d0463          	beqz	s10,ffffffffc0203574 <copy_range+0x1c4>
            if(share)
ffffffffc0203490:	67a2                	ld	a5,8(sp)
ffffffffc0203492:	c7b9                	beqz	a5,ffffffffc02034e0 <copy_range+0x130>
                page_insert(from, page, start, perm & ~PTE_W);
ffffffffc0203494:	01bdf693          	andi	a3,s11,27
ffffffffc0203498:	8622                	mv	a2,s0
ffffffffc020349a:	85ea                	mv	a1,s10
ffffffffc020349c:	8526                	mv	a0,s1
ffffffffc020349e:	9d2ff0ef          	jal	ffffffffc0202670 <page_insert>
                ret = page_insert(to, page, start, perm & ~PTE_W);
ffffffffc02034a2:	01bdf693          	andi	a3,s11,27
ffffffffc02034a6:	8622                	mv	a2,s0
ffffffffc02034a8:	85ea                	mv	a1,s10
ffffffffc02034aa:	8552                	mv	a0,s4
ffffffffc02034ac:	9c4ff0ef          	jal	ffffffffc0202670 <page_insert>
            assert(ret == 0);
ffffffffc02034b0:	d149                	beqz	a0,ffffffffc0203432 <copy_range+0x82>
ffffffffc02034b2:	00004697          	auipc	a3,0x4
ffffffffc02034b6:	83e68693          	addi	a3,a3,-1986 # ffffffffc0206cf0 <etext+0x14bc>
ffffffffc02034ba:	00003617          	auipc	a2,0x3
ffffffffc02034be:	d5e60613          	addi	a2,a2,-674 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02034c2:	1bb00593          	li	a1,443
ffffffffc02034c6:	00003517          	auipc	a0,0x3
ffffffffc02034ca:	1f250513          	addi	a0,a0,498 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02034ce:	f79fc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034d2:	002007b7          	lui	a5,0x200
ffffffffc02034d6:	97a2                	add	a5,a5,s0
ffffffffc02034d8:	ffe00437          	lui	s0,0xffe00
ffffffffc02034dc:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc02034de:	bf99                	j	ffffffffc0203434 <copy_range+0x84>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034e0:	100027f3          	csrr	a5,sstatus
ffffffffc02034e4:	8b89                	andi	a5,a5,2
ffffffffc02034e6:	eba5                	bnez	a5,ffffffffc0203556 <copy_range+0x1a6>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034e8:	00098797          	auipc	a5,0x98
ffffffffc02034ec:	0b87b783          	ld	a5,184(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc02034f0:	4505                	li	a0,1
ffffffffc02034f2:	6f9c                	ld	a5,24(a5)
ffffffffc02034f4:	9782                	jalr	a5
ffffffffc02034f6:	8caa                	mv	s9,a0
                assert(npage != NULL);
ffffffffc02034f8:	100c8063          	beqz	s9,ffffffffc02035f8 <copy_range+0x248>
    return page - pages + nbase;
ffffffffc02034fc:	000ab783          	ld	a5,0(s5)
ffffffffc0203500:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc0203504:	000b3683          	ld	a3,0(s6)
    return page - pages + nbase;
ffffffffc0203508:	40fd0d33          	sub	s10,s10,a5
ffffffffc020350c:	406d5d13          	srai	s10,s10,0x6
ffffffffc0203510:	9d32                	add	s10,s10,a2
    return KADDR(page2pa(page));
ffffffffc0203512:	017d75b3          	and	a1,s10,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0203516:	0d32                	slli	s10,s10,0xc
    return KADDR(page2pa(page));
ffffffffc0203518:	0cd5f363          	bgeu	a1,a3,ffffffffc02035de <copy_range+0x22e>
    return page - pages + nbase;
ffffffffc020351c:	40fc87b3          	sub	a5,s9,a5
ffffffffc0203520:	8799                	srai	a5,a5,0x6
ffffffffc0203522:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc0203524:	0177f633          	and	a2,a5,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0203528:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020352a:	08d67d63          	bgeu	a2,a3,ffffffffc02035c4 <copy_range+0x214>
ffffffffc020352e:	00098517          	auipc	a0,0x98
ffffffffc0203532:	08a53503          	ld	a0,138(a0) # ffffffffc029b5b8 <va_pa_offset>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203536:	6605                	lui	a2,0x1
ffffffffc0203538:	00ad05b3          	add	a1,s10,a0
ffffffffc020353c:	953e                	add	a0,a0,a5
ffffffffc020353e:	2de020ef          	jal	ffffffffc020581c <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc0203542:	01fdf693          	andi	a3,s11,31
ffffffffc0203546:	85e6                	mv	a1,s9
ffffffffc0203548:	8622                	mv	a2,s0
ffffffffc020354a:	8552                	mv	a0,s4
ffffffffc020354c:	924ff0ef          	jal	ffffffffc0202670 <page_insert>
            assert(ret == 0);
ffffffffc0203550:	ee0501e3          	beqz	a0,ffffffffc0203432 <copy_range+0x82>
ffffffffc0203554:	bfb9                	j	ffffffffc02034b2 <copy_range+0x102>
        intr_disable();
ffffffffc0203556:	baefd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020355a:	00098797          	auipc	a5,0x98
ffffffffc020355e:	0467b783          	ld	a5,70(a5) # ffffffffc029b5a0 <pmm_manager>
ffffffffc0203562:	4505                	li	a0,1
ffffffffc0203564:	6f9c                	ld	a5,24(a5)
ffffffffc0203566:	9782                	jalr	a5
ffffffffc0203568:	8caa                	mv	s9,a0
        intr_enable();
ffffffffc020356a:	b94fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020356e:	b769                	j	ffffffffc02034f8 <copy_range+0x148>
                return -E_NO_MEM;
ffffffffc0203570:	5571                	li	a0,-4
ffffffffc0203572:	b5e9                	j	ffffffffc020343c <copy_range+0x8c>
            assert(page != NULL);
ffffffffc0203574:	00003697          	auipc	a3,0x3
ffffffffc0203578:	75c68693          	addi	a3,a3,1884 # ffffffffc0206cd0 <etext+0x149c>
ffffffffc020357c:	00003617          	auipc	a2,0x3
ffffffffc0203580:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203584:	19400593          	li	a1,404
ffffffffc0203588:	00003517          	auipc	a0,0x3
ffffffffc020358c:	13050513          	addi	a0,a0,304 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203590:	eb7fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203594:	00003617          	auipc	a2,0x3
ffffffffc0203598:	10460613          	addi	a2,a2,260 # ffffffffc0206698 <etext+0xe64>
ffffffffc020359c:	06900593          	li	a1,105
ffffffffc02035a0:	00003517          	auipc	a0,0x3
ffffffffc02035a4:	05050513          	addi	a0,a0,80 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02035a8:	e9ffc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035ac:	00003617          	auipc	a2,0x3
ffffffffc02035b0:	30460613          	addi	a2,a2,772 # ffffffffc02068b0 <etext+0x107c>
ffffffffc02035b4:	07f00593          	li	a1,127
ffffffffc02035b8:	00003517          	auipc	a0,0x3
ffffffffc02035bc:	03850513          	addi	a0,a0,56 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02035c0:	e87fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02035c4:	86be                	mv	a3,a5
ffffffffc02035c6:	00003617          	auipc	a2,0x3
ffffffffc02035ca:	00260613          	addi	a2,a2,2 # ffffffffc02065c8 <etext+0xd94>
ffffffffc02035ce:	07100593          	li	a1,113
ffffffffc02035d2:	00003517          	auipc	a0,0x3
ffffffffc02035d6:	01e50513          	addi	a0,a0,30 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02035da:	e6dfc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02035de:	86ea                	mv	a3,s10
ffffffffc02035e0:	00003617          	auipc	a2,0x3
ffffffffc02035e4:	fe860613          	addi	a2,a2,-24 # ffffffffc02065c8 <etext+0xd94>
ffffffffc02035e8:	07100593          	li	a1,113
ffffffffc02035ec:	00003517          	auipc	a0,0x3
ffffffffc02035f0:	00450513          	addi	a0,a0,4 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02035f4:	e53fc0ef          	jal	ffffffffc0200446 <__panic>
                assert(npage != NULL);
ffffffffc02035f8:	00003697          	auipc	a3,0x3
ffffffffc02035fc:	6e868693          	addi	a3,a3,1768 # ffffffffc0206ce0 <etext+0x14ac>
ffffffffc0203600:	00003617          	auipc	a2,0x3
ffffffffc0203604:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203608:	1b200593          	li	a1,434
ffffffffc020360c:	00003517          	auipc	a0,0x3
ffffffffc0203610:	0ac50513          	addi	a0,a0,172 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203614:	e33fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203618:	00003697          	auipc	a3,0x3
ffffffffc020361c:	0e068693          	addi	a3,a3,224 # ffffffffc02066f8 <etext+0xec4>
ffffffffc0203620:	00003617          	auipc	a2,0x3
ffffffffc0203624:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203628:	17c00593          	li	a1,380
ffffffffc020362c:	00003517          	auipc	a0,0x3
ffffffffc0203630:	08c50513          	addi	a0,a0,140 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203634:	e13fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203638:	00003697          	auipc	a3,0x3
ffffffffc020363c:	09068693          	addi	a3,a3,144 # ffffffffc02066c8 <etext+0xe94>
ffffffffc0203640:	00003617          	auipc	a2,0x3
ffffffffc0203644:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203648:	17b00593          	li	a1,379
ffffffffc020364c:	00003517          	auipc	a0,0x3
ffffffffc0203650:	06c50513          	addi	a0,a0,108 # ffffffffc02066b8 <etext+0xe84>
ffffffffc0203654:	df3fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203658 <pgdir_alloc_page>:
{
ffffffffc0203658:	7139                	addi	sp,sp,-64
ffffffffc020365a:	f426                	sd	s1,40(sp)
ffffffffc020365c:	f04a                	sd	s2,32(sp)
ffffffffc020365e:	ec4e                	sd	s3,24(sp)
ffffffffc0203660:	fc06                	sd	ra,56(sp)
ffffffffc0203662:	f822                	sd	s0,48(sp)
ffffffffc0203664:	892a                	mv	s2,a0
ffffffffc0203666:	84ae                	mv	s1,a1
ffffffffc0203668:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020366a:	100027f3          	csrr	a5,sstatus
ffffffffc020366e:	8b89                	andi	a5,a5,2
ffffffffc0203670:	ebb5                	bnez	a5,ffffffffc02036e4 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203672:	00098417          	auipc	s0,0x98
ffffffffc0203676:	f2e40413          	addi	s0,s0,-210 # ffffffffc029b5a0 <pmm_manager>
ffffffffc020367a:	601c                	ld	a5,0(s0)
ffffffffc020367c:	4505                	li	a0,1
ffffffffc020367e:	6f9c                	ld	a5,24(a5)
ffffffffc0203680:	9782                	jalr	a5
ffffffffc0203682:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203684:	c5b9                	beqz	a1,ffffffffc02036d2 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203686:	86ce                	mv	a3,s3
ffffffffc0203688:	854a                	mv	a0,s2
ffffffffc020368a:	8626                	mv	a2,s1
ffffffffc020368c:	e42e                	sd	a1,8(sp)
ffffffffc020368e:	fe3fe0ef          	jal	ffffffffc0202670 <page_insert>
ffffffffc0203692:	65a2                	ld	a1,8(sp)
ffffffffc0203694:	e515                	bnez	a0,ffffffffc02036c0 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203696:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc0203698:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc020369a:	4785                	li	a5,1
ffffffffc020369c:	02f70c63          	beq	a4,a5,ffffffffc02036d4 <pgdir_alloc_page+0x7c>
ffffffffc02036a0:	00003697          	auipc	a3,0x3
ffffffffc02036a4:	66068693          	addi	a3,a3,1632 # ffffffffc0206d00 <etext+0x14cc>
ffffffffc02036a8:	00003617          	auipc	a2,0x3
ffffffffc02036ac:	b7060613          	addi	a2,a2,-1168 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02036b0:	20400593          	li	a1,516
ffffffffc02036b4:	00003517          	auipc	a0,0x3
ffffffffc02036b8:	00450513          	addi	a0,a0,4 # ffffffffc02066b8 <etext+0xe84>
ffffffffc02036bc:	d8bfc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02036c0:	100027f3          	csrr	a5,sstatus
ffffffffc02036c4:	8b89                	andi	a5,a5,2
ffffffffc02036c6:	ef95                	bnez	a5,ffffffffc0203702 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc02036c8:	601c                	ld	a5,0(s0)
ffffffffc02036ca:	852e                	mv	a0,a1
ffffffffc02036cc:	4585                	li	a1,1
ffffffffc02036ce:	739c                	ld	a5,32(a5)
ffffffffc02036d0:	9782                	jalr	a5
            return NULL;
ffffffffc02036d2:	4581                	li	a1,0
}
ffffffffc02036d4:	70e2                	ld	ra,56(sp)
ffffffffc02036d6:	7442                	ld	s0,48(sp)
ffffffffc02036d8:	74a2                	ld	s1,40(sp)
ffffffffc02036da:	7902                	ld	s2,32(sp)
ffffffffc02036dc:	69e2                	ld	s3,24(sp)
ffffffffc02036de:	852e                	mv	a0,a1
ffffffffc02036e0:	6121                	addi	sp,sp,64
ffffffffc02036e2:	8082                	ret
        intr_disable();
ffffffffc02036e4:	a20fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036e8:	00098417          	auipc	s0,0x98
ffffffffc02036ec:	eb840413          	addi	s0,s0,-328 # ffffffffc029b5a0 <pmm_manager>
ffffffffc02036f0:	601c                	ld	a5,0(s0)
ffffffffc02036f2:	4505                	li	a0,1
ffffffffc02036f4:	6f9c                	ld	a5,24(a5)
ffffffffc02036f6:	9782                	jalr	a5
ffffffffc02036f8:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02036fa:	a04fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036fe:	65a2                	ld	a1,8(sp)
ffffffffc0203700:	b751                	j	ffffffffc0203684 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc0203702:	a02fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203706:	601c                	ld	a5,0(s0)
ffffffffc0203708:	6522                	ld	a0,8(sp)
ffffffffc020370a:	4585                	li	a1,1
ffffffffc020370c:	739c                	ld	a5,32(a5)
ffffffffc020370e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203710:	9eefd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203714:	bf7d                	j	ffffffffc02036d2 <pgdir_alloc_page+0x7a>

ffffffffc0203716 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203716:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203718:	00003697          	auipc	a3,0x3
ffffffffc020371c:	60068693          	addi	a3,a3,1536 # ffffffffc0206d18 <etext+0x14e4>
ffffffffc0203720:	00003617          	auipc	a2,0x3
ffffffffc0203724:	af860613          	addi	a2,a2,-1288 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203728:	07400593          	li	a1,116
ffffffffc020372c:	00003517          	auipc	a0,0x3
ffffffffc0203730:	60c50513          	addi	a0,a0,1548 # ffffffffc0206d38 <etext+0x1504>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203734:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203736:	d11fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020373a <mm_create>:
{
ffffffffc020373a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020373c:	04000513          	li	a0,64
{
ffffffffc0203740:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203742:	d8efe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (mm != NULL)
ffffffffc0203746:	cd19                	beqz	a0,ffffffffc0203764 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203748:	e508                	sd	a0,8(a0)
ffffffffc020374a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020374c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203750:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203754:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203758:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020375c:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203760:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203764:	60a2                	ld	ra,8(sp)
ffffffffc0203766:	0141                	addi	sp,sp,16
ffffffffc0203768:	8082                	ret

ffffffffc020376a <find_vma>:
    if (mm != NULL)
ffffffffc020376a:	c505                	beqz	a0,ffffffffc0203792 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc020376c:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020376e:	c781                	beqz	a5,ffffffffc0203776 <find_vma+0xc>
ffffffffc0203770:	6798                	ld	a4,8(a5)
ffffffffc0203772:	02e5f363          	bgeu	a1,a4,ffffffffc0203798 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203776:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203778:	00f50d63          	beq	a0,a5,ffffffffc0203792 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020377c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203780:	00e5e663          	bltu	a1,a4,ffffffffc020378c <find_vma+0x22>
ffffffffc0203784:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203788:	00e5ee63          	bltu	a1,a4,ffffffffc02037a4 <find_vma+0x3a>
ffffffffc020378c:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020378e:	fef517e3          	bne	a0,a5,ffffffffc020377c <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203792:	4781                	li	a5,0
}
ffffffffc0203794:	853e                	mv	a0,a5
ffffffffc0203796:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203798:	6b98                	ld	a4,16(a5)
ffffffffc020379a:	fce5fee3          	bgeu	a1,a4,ffffffffc0203776 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020379e:	e91c                	sd	a5,16(a0)
}
ffffffffc02037a0:	853e                	mv	a0,a5
ffffffffc02037a2:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037a4:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037a6:	e91c                	sd	a5,16(a0)
ffffffffc02037a8:	bfe5                	j	ffffffffc02037a0 <find_vma+0x36>

ffffffffc02037aa <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037aa:	6590                	ld	a2,8(a1)
ffffffffc02037ac:	0105b803          	ld	a6,16(a1)
{
ffffffffc02037b0:	1141                	addi	sp,sp,-16
ffffffffc02037b2:	e406                	sd	ra,8(sp)
ffffffffc02037b4:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037b6:	01066763          	bltu	a2,a6,ffffffffc02037c4 <insert_vma_struct+0x1a>
ffffffffc02037ba:	a8b9                	j	ffffffffc0203818 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02037bc:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037c0:	04e66763          	bltu	a2,a4,ffffffffc020380e <insert_vma_struct+0x64>
ffffffffc02037c4:	86be                	mv	a3,a5
ffffffffc02037c6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02037c8:	fef51ae3          	bne	a0,a5,ffffffffc02037bc <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02037cc:	02a68463          	beq	a3,a0,ffffffffc02037f4 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02037d0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037d4:	fe86b883          	ld	a7,-24(a3)
ffffffffc02037d8:	08e8f063          	bgeu	a7,a4,ffffffffc0203858 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037dc:	04e66e63          	bltu	a2,a4,ffffffffc0203838 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02037e0:	00f50a63          	beq	a0,a5,ffffffffc02037f4 <insert_vma_struct+0x4a>
ffffffffc02037e4:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037e8:	05076863          	bltu	a4,a6,ffffffffc0203838 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037ec:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037f0:	02c77263          	bgeu	a4,a2,ffffffffc0203814 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02037f4:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02037f6:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02037f8:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02037fc:	e390                	sd	a2,0(a5)
ffffffffc02037fe:	e690                	sd	a2,8(a3)
}
ffffffffc0203800:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203802:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203804:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203806:	2705                	addiw	a4,a4,1
ffffffffc0203808:	d118                	sw	a4,32(a0)
}
ffffffffc020380a:	0141                	addi	sp,sp,16
ffffffffc020380c:	8082                	ret
    if (le_prev != list)
ffffffffc020380e:	fca691e3          	bne	a3,a0,ffffffffc02037d0 <insert_vma_struct+0x26>
ffffffffc0203812:	bfd9                	j	ffffffffc02037e8 <insert_vma_struct+0x3e>
ffffffffc0203814:	f03ff0ef          	jal	ffffffffc0203716 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203818:	00003697          	auipc	a3,0x3
ffffffffc020381c:	53068693          	addi	a3,a3,1328 # ffffffffc0206d48 <etext+0x1514>
ffffffffc0203820:	00003617          	auipc	a2,0x3
ffffffffc0203824:	9f860613          	addi	a2,a2,-1544 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203828:	07a00593          	li	a1,122
ffffffffc020382c:	00003517          	auipc	a0,0x3
ffffffffc0203830:	50c50513          	addi	a0,a0,1292 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203834:	c13fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203838:	00003697          	auipc	a3,0x3
ffffffffc020383c:	55068693          	addi	a3,a3,1360 # ffffffffc0206d88 <etext+0x1554>
ffffffffc0203840:	00003617          	auipc	a2,0x3
ffffffffc0203844:	9d860613          	addi	a2,a2,-1576 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203848:	07300593          	li	a1,115
ffffffffc020384c:	00003517          	auipc	a0,0x3
ffffffffc0203850:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203854:	bf3fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203858:	00003697          	auipc	a3,0x3
ffffffffc020385c:	51068693          	addi	a3,a3,1296 # ffffffffc0206d68 <etext+0x1534>
ffffffffc0203860:	00003617          	auipc	a2,0x3
ffffffffc0203864:	9b860613          	addi	a2,a2,-1608 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203868:	07200593          	li	a1,114
ffffffffc020386c:	00003517          	auipc	a0,0x3
ffffffffc0203870:	4cc50513          	addi	a0,a0,1228 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203874:	bd3fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203878 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203878:	591c                	lw	a5,48(a0)
{
ffffffffc020387a:	1141                	addi	sp,sp,-16
ffffffffc020387c:	e406                	sd	ra,8(sp)
ffffffffc020387e:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203880:	e78d                	bnez	a5,ffffffffc02038aa <mm_destroy+0x32>
ffffffffc0203882:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203884:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203886:	00a40c63          	beq	s0,a0,ffffffffc020389e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020388a:	6118                	ld	a4,0(a0)
ffffffffc020388c:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020388e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203890:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203892:	e398                	sd	a4,0(a5)
ffffffffc0203894:	ce2fe0ef          	jal	ffffffffc0201d76 <kfree>
    return listelm->next;
ffffffffc0203898:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020389a:	fea418e3          	bne	s0,a0,ffffffffc020388a <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020389e:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038a0:	6402                	ld	s0,0(sp)
ffffffffc02038a2:	60a2                	ld	ra,8(sp)
ffffffffc02038a4:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038a6:	cd0fe06f          	j	ffffffffc0201d76 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038aa:	00003697          	auipc	a3,0x3
ffffffffc02038ae:	4fe68693          	addi	a3,a3,1278 # ffffffffc0206da8 <etext+0x1574>
ffffffffc02038b2:	00003617          	auipc	a2,0x3
ffffffffc02038b6:	96660613          	addi	a2,a2,-1690 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02038ba:	09e00593          	li	a1,158
ffffffffc02038be:	00003517          	auipc	a0,0x3
ffffffffc02038c2:	47a50513          	addi	a0,a0,1146 # ffffffffc0206d38 <etext+0x1504>
ffffffffc02038c6:	b81fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02038ca <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038ca:	6785                	lui	a5,0x1
ffffffffc02038cc:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc02038ce:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc02038d0:	4785                	li	a5,1
{
ffffffffc02038d2:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038d4:	962e                	add	a2,a2,a1
ffffffffc02038d6:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc02038d8:	07fe                	slli	a5,a5,0x1f
{
ffffffffc02038da:	f822                	sd	s0,48(sp)
ffffffffc02038dc:	f426                	sd	s1,40(sp)
ffffffffc02038de:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038e2:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038e6:	0785                	addi	a5,a5,1
ffffffffc02038e8:	0084b633          	sltu	a2,s1,s0
ffffffffc02038ec:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038f0:	00163613          	seqz	a2,a2
ffffffffc02038f4:	0017b793          	seqz	a5,a5
{
ffffffffc02038f8:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02038fa:	8fd1                	or	a5,a5,a2
ffffffffc02038fc:	ebbd                	bnez	a5,ffffffffc0203972 <mm_map+0xa8>
ffffffffc02038fe:	002007b7          	lui	a5,0x200
ffffffffc0203902:	06f4e863          	bltu	s1,a5,ffffffffc0203972 <mm_map+0xa8>
ffffffffc0203906:	f04a                	sd	s2,32(sp)
ffffffffc0203908:	ec4e                	sd	s3,24(sp)
ffffffffc020390a:	e852                	sd	s4,16(sp)
ffffffffc020390c:	892a                	mv	s2,a0
ffffffffc020390e:	89ba                	mv	s3,a4
ffffffffc0203910:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203912:	c135                	beqz	a0,ffffffffc0203976 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203914:	85a6                	mv	a1,s1
ffffffffc0203916:	e55ff0ef          	jal	ffffffffc020376a <find_vma>
ffffffffc020391a:	c501                	beqz	a0,ffffffffc0203922 <mm_map+0x58>
ffffffffc020391c:	651c                	ld	a5,8(a0)
ffffffffc020391e:	0487e763          	bltu	a5,s0,ffffffffc020396c <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203922:	03000513          	li	a0,48
ffffffffc0203926:	baafe0ef          	jal	ffffffffc0201cd0 <kmalloc>
ffffffffc020392a:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020392c:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020392e:	c59d                	beqz	a1,ffffffffc020395c <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc0203930:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc0203932:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203934:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203938:	854a                	mv	a0,s2
ffffffffc020393a:	e42e                	sd	a1,8(sp)
ffffffffc020393c:	e6fff0ef          	jal	ffffffffc02037aa <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc0203940:	65a2                	ld	a1,8(sp)
ffffffffc0203942:	00098463          	beqz	s3,ffffffffc020394a <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203946:	00b9b023          	sd	a1,0(s3) # 1000 <_binary_obj___user_softint_out_size-0x7bb0>
ffffffffc020394a:	7902                	ld	s2,32(sp)
ffffffffc020394c:	69e2                	ld	s3,24(sp)
ffffffffc020394e:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc0203950:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203952:	70e2                	ld	ra,56(sp)
ffffffffc0203954:	7442                	ld	s0,48(sp)
ffffffffc0203956:	74a2                	ld	s1,40(sp)
ffffffffc0203958:	6121                	addi	sp,sp,64
ffffffffc020395a:	8082                	ret
ffffffffc020395c:	70e2                	ld	ra,56(sp)
ffffffffc020395e:	7442                	ld	s0,48(sp)
ffffffffc0203960:	7902                	ld	s2,32(sp)
ffffffffc0203962:	69e2                	ld	s3,24(sp)
ffffffffc0203964:	6a42                	ld	s4,16(sp)
ffffffffc0203966:	74a2                	ld	s1,40(sp)
ffffffffc0203968:	6121                	addi	sp,sp,64
ffffffffc020396a:	8082                	ret
ffffffffc020396c:	7902                	ld	s2,32(sp)
ffffffffc020396e:	69e2                	ld	s3,24(sp)
ffffffffc0203970:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203972:	5575                	li	a0,-3
ffffffffc0203974:	bff9                	j	ffffffffc0203952 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203976:	00003697          	auipc	a3,0x3
ffffffffc020397a:	44a68693          	addi	a3,a3,1098 # ffffffffc0206dc0 <etext+0x158c>
ffffffffc020397e:	00003617          	auipc	a2,0x3
ffffffffc0203982:	89a60613          	addi	a2,a2,-1894 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203986:	0b300593          	li	a1,179
ffffffffc020398a:	00003517          	auipc	a0,0x3
ffffffffc020398e:	3ae50513          	addi	a0,a0,942 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203992:	ab5fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203996 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203996:	7139                	addi	sp,sp,-64
ffffffffc0203998:	fc06                	sd	ra,56(sp)
ffffffffc020399a:	f822                	sd	s0,48(sp)
ffffffffc020399c:	f426                	sd	s1,40(sp)
ffffffffc020399e:	f04a                	sd	s2,32(sp)
ffffffffc02039a0:	ec4e                	sd	s3,24(sp)
ffffffffc02039a2:	e852                	sd	s4,16(sp)
ffffffffc02039a4:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039a6:	c525                	beqz	a0,ffffffffc0203a0e <dup_mmap+0x78>
ffffffffc02039a8:	892a                	mv	s2,a0
ffffffffc02039aa:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039ac:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039ae:	c1a5                	beqz	a1,ffffffffc0203a0e <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02039b0:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02039b2:	04848c63          	beq	s1,s0,ffffffffc0203a0a <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039b6:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02039ba:	fe843a83          	ld	s5,-24(s0)
ffffffffc02039be:	ff043a03          	ld	s4,-16(s0)
ffffffffc02039c2:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039c6:	b0afe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc02039ca:	c515                	beqz	a0,ffffffffc02039f6 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039cc:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02039ce:	01553423          	sd	s5,8(a0)
ffffffffc02039d2:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039d6:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc02039da:	854a                	mv	a0,s2
ffffffffc02039dc:	dcfff0ef          	jal	ffffffffc02037aa <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039e0:	ff043683          	ld	a3,-16(s0)
ffffffffc02039e4:	fe843603          	ld	a2,-24(s0)
ffffffffc02039e8:	6c8c                	ld	a1,24(s1)
ffffffffc02039ea:	01893503          	ld	a0,24(s2)
ffffffffc02039ee:	4701                	li	a4,0
ffffffffc02039f0:	9c1ff0ef          	jal	ffffffffc02033b0 <copy_range>
ffffffffc02039f4:	dd55                	beqz	a0,ffffffffc02039b0 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02039f6:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02039f8:	70e2                	ld	ra,56(sp)
ffffffffc02039fa:	7442                	ld	s0,48(sp)
ffffffffc02039fc:	74a2                	ld	s1,40(sp)
ffffffffc02039fe:	7902                	ld	s2,32(sp)
ffffffffc0203a00:	69e2                	ld	s3,24(sp)
ffffffffc0203a02:	6a42                	ld	s4,16(sp)
ffffffffc0203a04:	6aa2                	ld	s5,8(sp)
ffffffffc0203a06:	6121                	addi	sp,sp,64
ffffffffc0203a08:	8082                	ret
    return 0;
ffffffffc0203a0a:	4501                	li	a0,0
ffffffffc0203a0c:	b7f5                	j	ffffffffc02039f8 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203a0e:	00003697          	auipc	a3,0x3
ffffffffc0203a12:	3c268693          	addi	a3,a3,962 # ffffffffc0206dd0 <etext+0x159c>
ffffffffc0203a16:	00003617          	auipc	a2,0x3
ffffffffc0203a1a:	80260613          	addi	a2,a2,-2046 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203a1e:	0cf00593          	li	a1,207
ffffffffc0203a22:	00003517          	auipc	a0,0x3
ffffffffc0203a26:	31650513          	addi	a0,a0,790 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203a2a:	a1dfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a2e <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a2e:	1101                	addi	sp,sp,-32
ffffffffc0203a30:	ec06                	sd	ra,24(sp)
ffffffffc0203a32:	e822                	sd	s0,16(sp)
ffffffffc0203a34:	e426                	sd	s1,8(sp)
ffffffffc0203a36:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a38:	c531                	beqz	a0,ffffffffc0203a84 <exit_mmap+0x56>
ffffffffc0203a3a:	591c                	lw	a5,48(a0)
ffffffffc0203a3c:	84aa                	mv	s1,a0
ffffffffc0203a3e:	e3b9                	bnez	a5,ffffffffc0203a84 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a40:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a42:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a46:	02850663          	beq	a0,s0,ffffffffc0203a72 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a4a:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a4e:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a52:	854a                	mv	a0,s2
ffffffffc0203a54:	f98fe0ef          	jal	ffffffffc02021ec <unmap_range>
ffffffffc0203a58:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a5a:	fe8498e3          	bne	s1,s0,ffffffffc0203a4a <exit_mmap+0x1c>
ffffffffc0203a5e:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a60:	00848c63          	beq	s1,s0,ffffffffc0203a78 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a64:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a68:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a6c:	854a                	mv	a0,s2
ffffffffc0203a6e:	8b3fe0ef          	jal	ffffffffc0202320 <exit_range>
ffffffffc0203a72:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a74:	fe8498e3          	bne	s1,s0,ffffffffc0203a64 <exit_mmap+0x36>
    }
}
ffffffffc0203a78:	60e2                	ld	ra,24(sp)
ffffffffc0203a7a:	6442                	ld	s0,16(sp)
ffffffffc0203a7c:	64a2                	ld	s1,8(sp)
ffffffffc0203a7e:	6902                	ld	s2,0(sp)
ffffffffc0203a80:	6105                	addi	sp,sp,32
ffffffffc0203a82:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a84:	00003697          	auipc	a3,0x3
ffffffffc0203a88:	36c68693          	addi	a3,a3,876 # ffffffffc0206df0 <etext+0x15bc>
ffffffffc0203a8c:	00002617          	auipc	a2,0x2
ffffffffc0203a90:	78c60613          	addi	a2,a2,1932 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203a94:	0e800593          	li	a1,232
ffffffffc0203a98:	00003517          	auipc	a0,0x3
ffffffffc0203a9c:	2a050513          	addi	a0,a0,672 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203aa0:	9a7fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203aa4 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203aa4:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203aa6:	04000513          	li	a0,64
{
ffffffffc0203aaa:	f406                	sd	ra,40(sp)
ffffffffc0203aac:	f022                	sd	s0,32(sp)
ffffffffc0203aae:	ec26                	sd	s1,24(sp)
ffffffffc0203ab0:	e84a                	sd	s2,16(sp)
ffffffffc0203ab2:	e44e                	sd	s3,8(sp)
ffffffffc0203ab4:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ab6:	a1afe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (mm != NULL)
ffffffffc0203aba:	16050c63          	beqz	a0,ffffffffc0203c32 <vmm_init+0x18e>
ffffffffc0203abe:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203ac0:	e508                	sd	a0,8(a0)
ffffffffc0203ac2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203ac4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203ac8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203acc:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203ad0:	02053423          	sd	zero,40(a0)
ffffffffc0203ad4:	02052823          	sw	zero,48(a0)
ffffffffc0203ad8:	02053c23          	sd	zero,56(a0)
ffffffffc0203adc:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ae0:	03000513          	li	a0,48
ffffffffc0203ae4:	9ecfe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc0203ae8:	12050563          	beqz	a0,ffffffffc0203c12 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203aec:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203af0:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203af2:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203af6:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203af8:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203afa:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203afc:	8522                	mv	a0,s0
ffffffffc0203afe:	cadff0ef          	jal	ffffffffc02037aa <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b02:	fcf9                	bnez	s1,ffffffffc0203ae0 <vmm_init+0x3c>
ffffffffc0203b04:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b08:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b0c:	03000513          	li	a0,48
ffffffffc0203b10:	9c0fe0ef          	jal	ffffffffc0201cd0 <kmalloc>
    if (vma != NULL)
ffffffffc0203b14:	12050f63          	beqz	a0,ffffffffc0203c52 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203b18:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203b1c:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b1e:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203b22:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b24:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b26:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203b28:	8522                	mv	a0,s0
ffffffffc0203b2a:	c81ff0ef          	jal	ffffffffc02037aa <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b2e:	fd249fe3          	bne	s1,s2,ffffffffc0203b0c <vmm_init+0x68>
    return listelm->next;
ffffffffc0203b32:	641c                	ld	a5,8(s0)
ffffffffc0203b34:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203b36:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203b3a:	1ef40c63          	beq	s0,a5,ffffffffc0203d32 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b3e:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e30>
ffffffffc0203b42:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b46:	12d61663          	bne	a2,a3,ffffffffc0203c72 <vmm_init+0x1ce>
ffffffffc0203b4a:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b4e:	12e69263          	bne	a3,a4,ffffffffc0203c72 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b52:	0715                	addi	a4,a4,5
ffffffffc0203b54:	679c                	ld	a5,8(a5)
ffffffffc0203b56:	feb712e3          	bne	a4,a1,ffffffffc0203b3a <vmm_init+0x96>
ffffffffc0203b5a:	491d                	li	s2,7
ffffffffc0203b5c:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b5e:	85a6                	mv	a1,s1
ffffffffc0203b60:	8522                	mv	a0,s0
ffffffffc0203b62:	c09ff0ef          	jal	ffffffffc020376a <find_vma>
ffffffffc0203b66:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b68:	20050563          	beqz	a0,ffffffffc0203d72 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b6c:	00148593          	addi	a1,s1,1
ffffffffc0203b70:	8522                	mv	a0,s0
ffffffffc0203b72:	bf9ff0ef          	jal	ffffffffc020376a <find_vma>
ffffffffc0203b76:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b78:	1c050d63          	beqz	a0,ffffffffc0203d52 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b7c:	85ca                	mv	a1,s2
ffffffffc0203b7e:	8522                	mv	a0,s0
ffffffffc0203b80:	bebff0ef          	jal	ffffffffc020376a <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b84:	18051763          	bnez	a0,ffffffffc0203d12 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b88:	00348593          	addi	a1,s1,3
ffffffffc0203b8c:	8522                	mv	a0,s0
ffffffffc0203b8e:	bddff0ef          	jal	ffffffffc020376a <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b92:	16051063          	bnez	a0,ffffffffc0203cf2 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b96:	00448593          	addi	a1,s1,4
ffffffffc0203b9a:	8522                	mv	a0,s0
ffffffffc0203b9c:	bcfff0ef          	jal	ffffffffc020376a <find_vma>
        assert(vma5 == NULL);
ffffffffc0203ba0:	12051963          	bnez	a0,ffffffffc0203cd2 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203ba4:	008a3783          	ld	a5,8(s4)
ffffffffc0203ba8:	10979563          	bne	a5,s1,ffffffffc0203cb2 <vmm_init+0x20e>
ffffffffc0203bac:	010a3783          	ld	a5,16(s4)
ffffffffc0203bb0:	11279163          	bne	a5,s2,ffffffffc0203cb2 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203bb4:	0089b783          	ld	a5,8(s3)
ffffffffc0203bb8:	0c979d63          	bne	a5,s1,ffffffffc0203c92 <vmm_init+0x1ee>
ffffffffc0203bbc:	0109b783          	ld	a5,16(s3)
ffffffffc0203bc0:	0d279963          	bne	a5,s2,ffffffffc0203c92 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bc4:	0495                	addi	s1,s1,5
ffffffffc0203bc6:	1f900793          	li	a5,505
ffffffffc0203bca:	0915                	addi	s2,s2,5
ffffffffc0203bcc:	f8f499e3          	bne	s1,a5,ffffffffc0203b5e <vmm_init+0xba>
ffffffffc0203bd0:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203bd2:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203bd4:	85a6                	mv	a1,s1
ffffffffc0203bd6:	8522                	mv	a0,s0
ffffffffc0203bd8:	b93ff0ef          	jal	ffffffffc020376a <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203bdc:	1a051b63          	bnez	a0,ffffffffc0203d92 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203be0:	14fd                	addi	s1,s1,-1
ffffffffc0203be2:	ff2499e3          	bne	s1,s2,ffffffffc0203bd4 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203be6:	8522                	mv	a0,s0
ffffffffc0203be8:	c91ff0ef          	jal	ffffffffc0203878 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bec:	00003517          	auipc	a0,0x3
ffffffffc0203bf0:	37450513          	addi	a0,a0,884 # ffffffffc0206f60 <etext+0x172c>
ffffffffc0203bf4:	da0fc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203bf8:	7402                	ld	s0,32(sp)
ffffffffc0203bfa:	70a2                	ld	ra,40(sp)
ffffffffc0203bfc:	64e2                	ld	s1,24(sp)
ffffffffc0203bfe:	6942                	ld	s2,16(sp)
ffffffffc0203c00:	69a2                	ld	s3,8(sp)
ffffffffc0203c02:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c04:	00003517          	auipc	a0,0x3
ffffffffc0203c08:	37c50513          	addi	a0,a0,892 # ffffffffc0206f80 <etext+0x174c>
}
ffffffffc0203c0c:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c0e:	d86fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203c12:	00003697          	auipc	a3,0x3
ffffffffc0203c16:	1fe68693          	addi	a3,a3,510 # ffffffffc0206e10 <etext+0x15dc>
ffffffffc0203c1a:	00002617          	auipc	a2,0x2
ffffffffc0203c1e:	5fe60613          	addi	a2,a2,1534 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203c22:	12c00593          	li	a1,300
ffffffffc0203c26:	00003517          	auipc	a0,0x3
ffffffffc0203c2a:	11250513          	addi	a0,a0,274 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203c2e:	819fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203c32:	00003697          	auipc	a3,0x3
ffffffffc0203c36:	18e68693          	addi	a3,a3,398 # ffffffffc0206dc0 <etext+0x158c>
ffffffffc0203c3a:	00002617          	auipc	a2,0x2
ffffffffc0203c3e:	5de60613          	addi	a2,a2,1502 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203c42:	12400593          	li	a1,292
ffffffffc0203c46:	00003517          	auipc	a0,0x3
ffffffffc0203c4a:	0f250513          	addi	a0,a0,242 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203c4e:	ff8fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c52:	00003697          	auipc	a3,0x3
ffffffffc0203c56:	1be68693          	addi	a3,a3,446 # ffffffffc0206e10 <etext+0x15dc>
ffffffffc0203c5a:	00002617          	auipc	a2,0x2
ffffffffc0203c5e:	5be60613          	addi	a2,a2,1470 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203c62:	13300593          	li	a1,307
ffffffffc0203c66:	00003517          	auipc	a0,0x3
ffffffffc0203c6a:	0d250513          	addi	a0,a0,210 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203c6e:	fd8fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c72:	00003697          	auipc	a3,0x3
ffffffffc0203c76:	1c668693          	addi	a3,a3,454 # ffffffffc0206e38 <etext+0x1604>
ffffffffc0203c7a:	00002617          	auipc	a2,0x2
ffffffffc0203c7e:	59e60613          	addi	a2,a2,1438 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203c82:	13d00593          	li	a1,317
ffffffffc0203c86:	00003517          	auipc	a0,0x3
ffffffffc0203c8a:	0b250513          	addi	a0,a0,178 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203c8e:	fb8fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c92:	00003697          	auipc	a3,0x3
ffffffffc0203c96:	25e68693          	addi	a3,a3,606 # ffffffffc0206ef0 <etext+0x16bc>
ffffffffc0203c9a:	00002617          	auipc	a2,0x2
ffffffffc0203c9e:	57e60613          	addi	a2,a2,1406 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203ca2:	14f00593          	li	a1,335
ffffffffc0203ca6:	00003517          	auipc	a0,0x3
ffffffffc0203caa:	09250513          	addi	a0,a0,146 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203cae:	f98fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cb2:	00003697          	auipc	a3,0x3
ffffffffc0203cb6:	20e68693          	addi	a3,a3,526 # ffffffffc0206ec0 <etext+0x168c>
ffffffffc0203cba:	00002617          	auipc	a2,0x2
ffffffffc0203cbe:	55e60613          	addi	a2,a2,1374 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203cc2:	14e00593          	li	a1,334
ffffffffc0203cc6:	00003517          	auipc	a0,0x3
ffffffffc0203cca:	07250513          	addi	a0,a0,114 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203cce:	f78fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203cd2:	00003697          	auipc	a3,0x3
ffffffffc0203cd6:	1de68693          	addi	a3,a3,478 # ffffffffc0206eb0 <etext+0x167c>
ffffffffc0203cda:	00002617          	auipc	a2,0x2
ffffffffc0203cde:	53e60613          	addi	a2,a2,1342 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203ce2:	14c00593          	li	a1,332
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	05250513          	addi	a0,a0,82 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203cee:	f58fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203cf2:	00003697          	auipc	a3,0x3
ffffffffc0203cf6:	1ae68693          	addi	a3,a3,430 # ffffffffc0206ea0 <etext+0x166c>
ffffffffc0203cfa:	00002617          	auipc	a2,0x2
ffffffffc0203cfe:	51e60613          	addi	a2,a2,1310 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203d02:	14a00593          	li	a1,330
ffffffffc0203d06:	00003517          	auipc	a0,0x3
ffffffffc0203d0a:	03250513          	addi	a0,a0,50 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203d0e:	f38fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203d12:	00003697          	auipc	a3,0x3
ffffffffc0203d16:	17e68693          	addi	a3,a3,382 # ffffffffc0206e90 <etext+0x165c>
ffffffffc0203d1a:	00002617          	auipc	a2,0x2
ffffffffc0203d1e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203d22:	14800593          	li	a1,328
ffffffffc0203d26:	00003517          	auipc	a0,0x3
ffffffffc0203d2a:	01250513          	addi	a0,a0,18 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203d2e:	f18fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d32:	00003697          	auipc	a3,0x3
ffffffffc0203d36:	0ee68693          	addi	a3,a3,238 # ffffffffc0206e20 <etext+0x15ec>
ffffffffc0203d3a:	00002617          	auipc	a2,0x2
ffffffffc0203d3e:	4de60613          	addi	a2,a2,1246 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203d42:	13b00593          	li	a1,315
ffffffffc0203d46:	00003517          	auipc	a0,0x3
ffffffffc0203d4a:	ff250513          	addi	a0,a0,-14 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203d4e:	ef8fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d52:	00003697          	auipc	a3,0x3
ffffffffc0203d56:	12e68693          	addi	a3,a3,302 # ffffffffc0206e80 <etext+0x164c>
ffffffffc0203d5a:	00002617          	auipc	a2,0x2
ffffffffc0203d5e:	4be60613          	addi	a2,a2,1214 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203d62:	14600593          	li	a1,326
ffffffffc0203d66:	00003517          	auipc	a0,0x3
ffffffffc0203d6a:	fd250513          	addi	a0,a0,-46 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203d6e:	ed8fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d72:	00003697          	auipc	a3,0x3
ffffffffc0203d76:	0fe68693          	addi	a3,a3,254 # ffffffffc0206e70 <etext+0x163c>
ffffffffc0203d7a:	00002617          	auipc	a2,0x2
ffffffffc0203d7e:	49e60613          	addi	a2,a2,1182 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203d82:	14400593          	li	a1,324
ffffffffc0203d86:	00003517          	auipc	a0,0x3
ffffffffc0203d8a:	fb250513          	addi	a0,a0,-78 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203d8e:	eb8fc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d92:	6914                	ld	a3,16(a0)
ffffffffc0203d94:	6510                	ld	a2,8(a0)
ffffffffc0203d96:	0004859b          	sext.w	a1,s1
ffffffffc0203d9a:	00003517          	auipc	a0,0x3
ffffffffc0203d9e:	18650513          	addi	a0,a0,390 # ffffffffc0206f20 <etext+0x16ec>
ffffffffc0203da2:	bf2fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203da6:	00003697          	auipc	a3,0x3
ffffffffc0203daa:	1a268693          	addi	a3,a3,418 # ffffffffc0206f48 <etext+0x1714>
ffffffffc0203dae:	00002617          	auipc	a2,0x2
ffffffffc0203db2:	46a60613          	addi	a2,a2,1130 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0203db6:	15900593          	li	a1,345
ffffffffc0203dba:	00003517          	auipc	a0,0x3
ffffffffc0203dbe:	f7e50513          	addi	a0,a0,-130 # ffffffffc0206d38 <etext+0x1504>
ffffffffc0203dc2:	e84fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203dc6 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203dc6:	7179                	addi	sp,sp,-48
ffffffffc0203dc8:	f022                	sd	s0,32(sp)
ffffffffc0203dca:	f406                	sd	ra,40(sp)
ffffffffc0203dcc:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203dce:	c52d                	beqz	a0,ffffffffc0203e38 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203dd0:	002007b7          	lui	a5,0x200
ffffffffc0203dd4:	04f5ed63          	bltu	a1,a5,ffffffffc0203e2e <user_mem_check+0x68>
ffffffffc0203dd8:	ec26                	sd	s1,24(sp)
ffffffffc0203dda:	00c584b3          	add	s1,a1,a2
ffffffffc0203dde:	0695ff63          	bgeu	a1,s1,ffffffffc0203e5c <user_mem_check+0x96>
ffffffffc0203de2:	4785                	li	a5,1
ffffffffc0203de4:	07fe                	slli	a5,a5,0x1f
ffffffffc0203de6:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc0203de8:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e5c <user_mem_check+0x96>
ffffffffc0203dec:	e84a                	sd	s2,16(sp)
ffffffffc0203dee:	e44e                	sd	s3,8(sp)
ffffffffc0203df0:	8936                	mv	s2,a3
ffffffffc0203df2:	89aa                	mv	s3,a0
ffffffffc0203df4:	a829                	j	ffffffffc0203e0e <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203df6:	6685                	lui	a3,0x1
ffffffffc0203df8:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dfa:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dfe:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e00:	c685                	beqz	a3,ffffffffc0203e28 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e02:	c399                	beqz	a5,ffffffffc0203e08 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e04:	02e46263          	bltu	s0,a4,ffffffffc0203e28 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e08:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e0a:	04947b63          	bgeu	s0,s1,ffffffffc0203e60 <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e0e:	85a2                	mv	a1,s0
ffffffffc0203e10:	854e                	mv	a0,s3
ffffffffc0203e12:	959ff0ef          	jal	ffffffffc020376a <find_vma>
ffffffffc0203e16:	c909                	beqz	a0,ffffffffc0203e28 <user_mem_check+0x62>
ffffffffc0203e18:	6518                	ld	a4,8(a0)
ffffffffc0203e1a:	00e46763          	bltu	s0,a4,ffffffffc0203e28 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e1e:	4d1c                	lw	a5,24(a0)
ffffffffc0203e20:	fc091be3          	bnez	s2,ffffffffc0203df6 <user_mem_check+0x30>
ffffffffc0203e24:	8b85                	andi	a5,a5,1
ffffffffc0203e26:	f3ed                	bnez	a5,ffffffffc0203e08 <user_mem_check+0x42>
ffffffffc0203e28:	64e2                	ld	s1,24(sp)
ffffffffc0203e2a:	6942                	ld	s2,16(sp)
ffffffffc0203e2c:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203e2e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e30:	70a2                	ld	ra,40(sp)
ffffffffc0203e32:	7402                	ld	s0,32(sp)
ffffffffc0203e34:	6145                	addi	sp,sp,48
ffffffffc0203e36:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e38:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e3c:	fef5eae3          	bltu	a1,a5,ffffffffc0203e30 <user_mem_check+0x6a>
ffffffffc0203e40:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e44:	962e                	add	a2,a2,a1
ffffffffc0203e46:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64a11>
ffffffffc0203e48:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e4c:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e50:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e52:	00867533          	and	a0,a2,s0
ffffffffc0203e56:	7402                	ld	s0,32(sp)
ffffffffc0203e58:	6145                	addi	sp,sp,48
ffffffffc0203e5a:	8082                	ret
ffffffffc0203e5c:	64e2                	ld	s1,24(sp)
ffffffffc0203e5e:	bfc1                	j	ffffffffc0203e2e <user_mem_check+0x68>
ffffffffc0203e60:	64e2                	ld	s1,24(sp)
ffffffffc0203e62:	6942                	ld	s2,16(sp)
ffffffffc0203e64:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e66:	4505                	li	a0,1
ffffffffc0203e68:	b7e1                	j	ffffffffc0203e30 <user_mem_check+0x6a>

ffffffffc0203e6a <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e6a:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e6c:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e6e:	63e000ef          	jal	ffffffffc02044ac <do_exit>

ffffffffc0203e72 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e72:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e74:	10800513          	li	a0,264
{
ffffffffc0203e78:	e022                	sd	s0,0(sp)
ffffffffc0203e7a:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e7c:	e55fd0ef          	jal	ffffffffc0201cd0 <kmalloc>
ffffffffc0203e80:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e82:	cd21                	beqz	a0,ffffffffc0203eda <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203e84:	57fd                	li	a5,-1
ffffffffc0203e86:	1782                	slli	a5,a5,0x20
ffffffffc0203e88:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203e8a:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203e8e:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203e92:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203e96:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203e9a:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203e9e:	07000613          	li	a2,112
ffffffffc0203ea2:	4581                	li	a1,0
ffffffffc0203ea4:	03050513          	addi	a0,a0,48
ffffffffc0203ea8:	163010ef          	jal	ffffffffc020580a <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203eac:	00097797          	auipc	a5,0x97
ffffffffc0203eb0:	6fc7b783          	ld	a5,1788(a5) # ffffffffc029b5a8 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203eb4:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc0203eb8:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203ebc:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203ebe:	0b440513          	addi	a0,s0,180
ffffffffc0203ec2:	4641                	li	a2,16
ffffffffc0203ec4:	4581                	li	a1,0
ffffffffc0203ec6:	145010ef          	jal	ffffffffc020580a <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->exit_code = 0;
ffffffffc0203eca:	0e043423          	sd	zero,232(s0)
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203ece:	0e043823          	sd	zero,240(s0)
ffffffffc0203ed2:	0e043c23          	sd	zero,248(s0)
ffffffffc0203ed6:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0203eda:	60a2                	ld	ra,8(sp)
ffffffffc0203edc:	8522                	mv	a0,s0
ffffffffc0203ede:	6402                	ld	s0,0(sp)
ffffffffc0203ee0:	0141                	addi	sp,sp,16
ffffffffc0203ee2:	8082                	ret

ffffffffc0203ee4 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203ee4:	00097797          	auipc	a5,0x97
ffffffffc0203ee8:	6f47b783          	ld	a5,1780(a5) # ffffffffc029b5d8 <current>
ffffffffc0203eec:	73c8                	ld	a0,160(a5)
ffffffffc0203eee:	fc9fc06f          	j	ffffffffc0200eb6 <forkrets>

ffffffffc0203ef2 <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
ffffffffc0203ef2:	00097797          	auipc	a5,0x97
ffffffffc0203ef6:	6e67b783          	ld	a5,1766(a5) # ffffffffc029b5d8 <current>
{
ffffffffc0203efa:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(exit);
ffffffffc0203efc:	00003617          	auipc	a2,0x3
ffffffffc0203f00:	09c60613          	addi	a2,a2,156 # ffffffffc0206f98 <etext+0x1764>
ffffffffc0203f04:	43cc                	lw	a1,4(a5)
ffffffffc0203f06:	00003517          	auipc	a0,0x3
ffffffffc0203f0a:	09a50513          	addi	a0,a0,154 # ffffffffc0206fa0 <etext+0x176c>
{
ffffffffc0203f0e:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(exit);
ffffffffc0203f10:	a84fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203f14:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203f18:	2a478793          	addi	a5,a5,676 # a1b8 <_binary_obj___user_exit_out_size>
ffffffffc0203f1c:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203f1e:	00003517          	auipc	a0,0x3
ffffffffc0203f22:	07a50513          	addi	a0,a0,122 # ffffffffc0206f98 <etext+0x1764>
ffffffffc0203f26:	00023797          	auipc	a5,0x23
ffffffffc0203f2a:	4b278793          	addi	a5,a5,1202 # ffffffffc02273d8 <_binary_obj___user_exit_out_start>
ffffffffc0203f2e:	f03e                	sd	a5,32(sp)
ffffffffc0203f30:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203f32:	e802                	sd	zero,16(sp)
ffffffffc0203f34:	023010ef          	jal	ffffffffc0205756 <strlen>
ffffffffc0203f38:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203f3a:	4511                	li	a0,4
ffffffffc0203f3c:	55a2                	lw	a1,40(sp)
ffffffffc0203f3e:	4662                	lw	a2,24(sp)
ffffffffc0203f40:	5682                	lw	a3,32(sp)
ffffffffc0203f42:	4722                	lw	a4,8(sp)
ffffffffc0203f44:	48a9                	li	a7,10
ffffffffc0203f46:	9002                	ebreak
ffffffffc0203f48:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f4a:	65c2                	ld	a1,16(sp)
ffffffffc0203f4c:	00003517          	auipc	a0,0x3
ffffffffc0203f50:	07c50513          	addi	a0,a0,124 # ffffffffc0206fc8 <etext+0x1794>
ffffffffc0203f54:	a40fc0ef          	jal	ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f58:	00003617          	auipc	a2,0x3
ffffffffc0203f5c:	08060613          	addi	a2,a2,128 # ffffffffc0206fd8 <etext+0x17a4>
ffffffffc0203f60:	3c400593          	li	a1,964
ffffffffc0203f64:	00003517          	auipc	a0,0x3
ffffffffc0203f68:	09450513          	addi	a0,a0,148 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0203f6c:	cdafc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f70 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f70:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f72:	1141                	addi	sp,sp,-16
ffffffffc0203f74:	e406                	sd	ra,8(sp)
ffffffffc0203f76:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f7a:	02f6ee63          	bltu	a3,a5,ffffffffc0203fb6 <put_pgdir+0x46>
ffffffffc0203f7e:	00097717          	auipc	a4,0x97
ffffffffc0203f82:	63a73703          	ld	a4,1594(a4) # ffffffffc029b5b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f86:	00097797          	auipc	a5,0x97
ffffffffc0203f8a:	63a7b783          	ld	a5,1594(a5) # ffffffffc029b5c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f8e:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f90:	82b1                	srli	a3,a3,0xc
ffffffffc0203f92:	02f6fe63          	bgeu	a3,a5,ffffffffc0203fce <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f96:	00004797          	auipc	a5,0x4
ffffffffc0203f9a:	9ea7b783          	ld	a5,-1558(a5) # ffffffffc0207980 <nbase>
ffffffffc0203f9e:	00097517          	auipc	a0,0x97
ffffffffc0203fa2:	62a53503          	ld	a0,1578(a0) # ffffffffc029b5c8 <pages>
}
ffffffffc0203fa6:	60a2                	ld	ra,8(sp)
ffffffffc0203fa8:	8e9d                	sub	a3,a3,a5
ffffffffc0203faa:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203fac:	4585                	li	a1,1
ffffffffc0203fae:	9536                	add	a0,a0,a3
}
ffffffffc0203fb0:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203fb2:	f1bfd06f          	j	ffffffffc0201ecc <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203fb6:	00002617          	auipc	a2,0x2
ffffffffc0203fba:	6ba60613          	addi	a2,a2,1722 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0203fbe:	07700593          	li	a1,119
ffffffffc0203fc2:	00002517          	auipc	a0,0x2
ffffffffc0203fc6:	62e50513          	addi	a0,a0,1582 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0203fca:	c7cfc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203fce:	00002617          	auipc	a2,0x2
ffffffffc0203fd2:	6ca60613          	addi	a2,a2,1738 # ffffffffc0206698 <etext+0xe64>
ffffffffc0203fd6:	06900593          	li	a1,105
ffffffffc0203fda:	00002517          	auipc	a0,0x2
ffffffffc0203fde:	61650513          	addi	a0,a0,1558 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0203fe2:	c64fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fe6 <proc_run>:
    if (proc != current)
ffffffffc0203fe6:	00097697          	auipc	a3,0x97
ffffffffc0203fea:	5f268693          	addi	a3,a3,1522 # ffffffffc029b5d8 <current>
ffffffffc0203fee:	6298                	ld	a4,0(a3)
ffffffffc0203ff0:	06a70363          	beq	a4,a0,ffffffffc0204056 <proc_run+0x70>
{
ffffffffc0203ff4:	1101                	addi	sp,sp,-32
ffffffffc0203ff6:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203ff8:	100027f3          	csrr	a5,sstatus
ffffffffc0203ffc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203ffe:	4801                	li	a6,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204000:	eb9d                	bnez	a5,ffffffffc0204036 <proc_run+0x50>
        proc->runs++; // 更新进程相关状态
ffffffffc0204002:	4510                	lw	a2,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204004:	755c                	ld	a5,168(a0)
        current=proc; // 切换进程
ffffffffc0204006:	e288                	sd	a0,0(a3)
ffffffffc0204008:	56fd                	li	a3,-1
        proc->runs++; // 更新进程相关状态
ffffffffc020400a:	2605                	addiw	a2,a2,1
ffffffffc020400c:	16fe                	slli	a3,a3,0x3f
ffffffffc020400e:	83b1                	srli	a5,a5,0xc
ffffffffc0204010:	e442                	sd	a6,8(sp)
        current->need_resched = 0; // 不需要调度
ffffffffc0204012:	00053c23          	sd	zero,24(a0)
        proc->runs++; // 更新进程相关状态
ffffffffc0204016:	c510                	sw	a2,8(a0)
ffffffffc0204018:	8fd5                	or	a5,a5,a3
ffffffffc020401a:	18079073          	csrw	satp,a5
        switch_to(&old->context,&proc->context); // 上下文切换
ffffffffc020401e:	03050593          	addi	a1,a0,48
ffffffffc0204022:	03070513          	addi	a0,a4,48
ffffffffc0204026:	0e8010ef          	jal	ffffffffc020510e <switch_to>
    if (flag)
ffffffffc020402a:	6822                	ld	a6,8(sp)
ffffffffc020402c:	02081163          	bnez	a6,ffffffffc020404e <proc_run+0x68>
}
ffffffffc0204030:	60e2                	ld	ra,24(sp)
ffffffffc0204032:	6105                	addi	sp,sp,32
ffffffffc0204034:	8082                	ret
ffffffffc0204036:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204038:	8cdfc0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc == current) {
ffffffffc020403c:	00097697          	auipc	a3,0x97
ffffffffc0204040:	59c68693          	addi	a3,a3,1436 # ffffffffc029b5d8 <current>
ffffffffc0204044:	6298                	ld	a4,0(a3)
ffffffffc0204046:	6522                	ld	a0,8(sp)
        return 1;
ffffffffc0204048:	4805                	li	a6,1
ffffffffc020404a:	fae51ce3          	bne	a0,a4,ffffffffc0204002 <proc_run+0x1c>
}
ffffffffc020404e:	60e2                	ld	ra,24(sp)
ffffffffc0204050:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204052:	8adfc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0204056:	8082                	ret

ffffffffc0204058 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0204058:	00097797          	auipc	a5,0x97
ffffffffc020405c:	5787a783          	lw	a5,1400(a5) # ffffffffc029b5d0 <nr_process>
{
ffffffffc0204060:	7159                	addi	sp,sp,-112
ffffffffc0204062:	e4ce                	sd	s3,72(sp)
ffffffffc0204064:	f486                	sd	ra,104(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204066:	6985                	lui	s3,0x1
ffffffffc0204068:	3737db63          	bge	a5,s3,ffffffffc02043de <do_fork+0x386>
ffffffffc020406c:	f0a2                	sd	s0,96(sp)
ffffffffc020406e:	eca6                	sd	s1,88(sp)
ffffffffc0204070:	e8ca                	sd	s2,80(sp)
ffffffffc0204072:	e86a                	sd	s10,16(sp)
ffffffffc0204074:	892e                	mv	s2,a1
ffffffffc0204076:	84b2                	mv	s1,a2
ffffffffc0204078:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL)
ffffffffc020407a:	df9ff0ef          	jal	ffffffffc0203e72 <alloc_proc>
ffffffffc020407e:	842a                	mv	s0,a0
ffffffffc0204080:	2e050c63          	beqz	a0,ffffffffc0204378 <do_fork+0x320>
ffffffffc0204084:	f45e                	sd	s7,40(sp)
    proc->parent = current;
ffffffffc0204086:	00097b97          	auipc	s7,0x97
ffffffffc020408a:	552b8b93          	addi	s7,s7,1362 # ffffffffc029b5d8 <current>
ffffffffc020408e:	000bb783          	ld	a5,0(s7)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204092:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204094:	f01c                	sd	a5,32(s0)
    current->wait_state = 0; // 确保父进程的wait_state为0 //////////+++
ffffffffc0204096:	0e07a623          	sw	zero,236(a5)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020409a:	df9fd0ef          	jal	ffffffffc0201e92 <alloc_pages>
    if (page != NULL)
ffffffffc020409e:	2c050963          	beqz	a0,ffffffffc0204370 <do_fork+0x318>
ffffffffc02040a2:	e0d2                	sd	s4,64(sp)
    return page - pages + nbase;
ffffffffc02040a4:	00097a17          	auipc	s4,0x97
ffffffffc02040a8:	524a0a13          	addi	s4,s4,1316 # ffffffffc029b5c8 <pages>
ffffffffc02040ac:	000a3783          	ld	a5,0(s4)
ffffffffc02040b0:	fc56                	sd	s5,56(sp)
ffffffffc02040b2:	00004a97          	auipc	s5,0x4
ffffffffc02040b6:	8cea8a93          	addi	s5,s5,-1842 # ffffffffc0207980 <nbase>
ffffffffc02040ba:	000ab703          	ld	a4,0(s5)
ffffffffc02040be:	40f506b3          	sub	a3,a0,a5
ffffffffc02040c2:	f85a                	sd	s6,48(sp)
    return KADDR(page2pa(page));
ffffffffc02040c4:	00097b17          	auipc	s6,0x97
ffffffffc02040c8:	4fcb0b13          	addi	s6,s6,1276 # ffffffffc029b5c0 <npage>
ffffffffc02040cc:	ec66                	sd	s9,24(sp)
    return page - pages + nbase;
ffffffffc02040ce:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02040d0:	5cfd                	li	s9,-1
ffffffffc02040d2:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc02040d6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02040d8:	00ccdc93          	srli	s9,s9,0xc
ffffffffc02040dc:	0196f633          	and	a2,a3,s9
ffffffffc02040e0:	f062                	sd	s8,32(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02040e2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040e4:	32f67763          	bgeu	a2,a5,ffffffffc0204412 <do_fork+0x3ba>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02040e8:	000bb603          	ld	a2,0(s7)
ffffffffc02040ec:	00097b97          	auipc	s7,0x97
ffffffffc02040f0:	4ccb8b93          	addi	s7,s7,1228 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc02040f4:	000bb783          	ld	a5,0(s7)
ffffffffc02040f8:	02863c03          	ld	s8,40(a2)
ffffffffc02040fc:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040fe:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204100:	020c0863          	beqz	s8,ffffffffc0204130 <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc0204104:	100d7793          	andi	a5,s10,256
ffffffffc0204108:	18078863          	beqz	a5,ffffffffc0204298 <do_fork+0x240>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020410c:	030c2703          	lw	a4,48(s8) # fffffffffff80030 <end+0x3fce4a40>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204110:	018c3783          	ld	a5,24(s8)
ffffffffc0204114:	c02006b7          	lui	a3,0xc0200
ffffffffc0204118:	2705                	addiw	a4,a4,1
ffffffffc020411a:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc020411e:	03843423          	sd	s8,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204122:	30d7e463          	bltu	a5,a3,ffffffffc020442a <do_fork+0x3d2>
ffffffffc0204126:	000bb703          	ld	a4,0(s7)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020412a:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020412c:	8f99                	sub	a5,a5,a4
ffffffffc020412e:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204130:	6789                	lui	a5,0x2
ffffffffc0204132:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cd0>
ffffffffc0204136:	96be                	add	a3,a3,a5
ffffffffc0204138:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020413a:	87b6                	mv	a5,a3
ffffffffc020413c:	12048713          	addi	a4,s1,288
ffffffffc0204140:	6890                	ld	a2,16(s1)
ffffffffc0204142:	6088                	ld	a0,0(s1)
ffffffffc0204144:	648c                	ld	a1,8(s1)
ffffffffc0204146:	eb90                	sd	a2,16(a5)
ffffffffc0204148:	e388                	sd	a0,0(a5)
ffffffffc020414a:	e78c                	sd	a1,8(a5)
ffffffffc020414c:	6c90                	ld	a2,24(s1)
ffffffffc020414e:	02048493          	addi	s1,s1,32
ffffffffc0204152:	02078793          	addi	a5,a5,32
ffffffffc0204156:	fec7bc23          	sd	a2,-8(a5)
ffffffffc020415a:	fee493e3          	bne	s1,a4,ffffffffc0204140 <do_fork+0xe8>
    proc->tf->gpr.a0 = 0;
ffffffffc020415e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204162:	22090163          	beqz	s2,ffffffffc0204384 <do_fork+0x32c>
ffffffffc0204166:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020416a:	00000797          	auipc	a5,0x0
ffffffffc020416e:	d7a78793          	addi	a5,a5,-646 # ffffffffc0203ee4 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204172:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204174:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204176:	100027f3          	csrr	a5,sstatus
ffffffffc020417a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020417c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020417e:	22079263          	bnez	a5,ffffffffc02043a2 <do_fork+0x34a>
    if (++last_pid >= MAX_PID)
ffffffffc0204182:	00093517          	auipc	a0,0x93
ffffffffc0204186:	fc252503          	lw	a0,-62(a0) # ffffffffc0297144 <last_pid.1>
ffffffffc020418a:	6789                	lui	a5,0x2
ffffffffc020418c:	2505                	addiw	a0,a0,1
ffffffffc020418e:	00093717          	auipc	a4,0x93
ffffffffc0204192:	faa72b23          	sw	a0,-74(a4) # ffffffffc0297144 <last_pid.1>
ffffffffc0204196:	22f55563          	bge	a0,a5,ffffffffc02043c0 <do_fork+0x368>
    if (last_pid >= next_safe)
ffffffffc020419a:	00093797          	auipc	a5,0x93
ffffffffc020419e:	fa67a783          	lw	a5,-90(a5) # ffffffffc0297140 <next_safe.0>
ffffffffc02041a2:	00097497          	auipc	s1,0x97
ffffffffc02041a6:	3be48493          	addi	s1,s1,958 # ffffffffc029b560 <proc_list>
ffffffffc02041aa:	06f54563          	blt	a0,a5,ffffffffc0204214 <do_fork+0x1bc>
ffffffffc02041ae:	00097497          	auipc	s1,0x97
ffffffffc02041b2:	3b248493          	addi	s1,s1,946 # ffffffffc029b560 <proc_list>
ffffffffc02041b6:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc02041ba:	6789                	lui	a5,0x2
ffffffffc02041bc:	00093717          	auipc	a4,0x93
ffffffffc02041c0:	f8f72223          	sw	a5,-124(a4) # ffffffffc0297140 <next_safe.0>
ffffffffc02041c4:	86aa                	mv	a3,a0
ffffffffc02041c6:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02041c8:	04988063          	beq	a7,s1,ffffffffc0204208 <do_fork+0x1b0>
ffffffffc02041cc:	882e                	mv	a6,a1
ffffffffc02041ce:	87c6                	mv	a5,a7
ffffffffc02041d0:	6609                	lui	a2,0x2
ffffffffc02041d2:	a811                	j	ffffffffc02041e6 <do_fork+0x18e>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041d4:	00e6d663          	bge	a3,a4,ffffffffc02041e0 <do_fork+0x188>
ffffffffc02041d8:	00c75463          	bge	a4,a2,ffffffffc02041e0 <do_fork+0x188>
                next_safe = proc->pid;
ffffffffc02041dc:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041de:	4805                	li	a6,1
ffffffffc02041e0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041e2:	00978d63          	beq	a5,s1,ffffffffc02041fc <do_fork+0x1a4>
            if (proc->pid == last_pid)
ffffffffc02041e6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c74>
ffffffffc02041ea:	fed715e3          	bne	a4,a3,ffffffffc02041d4 <do_fork+0x17c>
                if (++last_pid >= next_safe)
ffffffffc02041ee:	2685                	addiw	a3,a3,1
ffffffffc02041f0:	1ec6d163          	bge	a3,a2,ffffffffc02043d2 <do_fork+0x37a>
ffffffffc02041f4:	679c                	ld	a5,8(a5)
ffffffffc02041f6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041f8:	fe9797e3          	bne	a5,s1,ffffffffc02041e6 <do_fork+0x18e>
ffffffffc02041fc:	00080663          	beqz	a6,ffffffffc0204208 <do_fork+0x1b0>
ffffffffc0204200:	00093797          	auipc	a5,0x93
ffffffffc0204204:	f4c7a023          	sw	a2,-192(a5) # ffffffffc0297140 <next_safe.0>
ffffffffc0204208:	c591                	beqz	a1,ffffffffc0204214 <do_fork+0x1bc>
ffffffffc020420a:	00093797          	auipc	a5,0x93
ffffffffc020420e:	f2d7ad23          	sw	a3,-198(a5) # ffffffffc0297144 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204212:	8536                	mv	a0,a3
        proc->pid = get_pid();
ffffffffc0204214:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204216:	45a9                	li	a1,10
ffffffffc0204218:	15c010ef          	jal	ffffffffc0205374 <hash32>
ffffffffc020421c:	02051793          	slli	a5,a0,0x20
ffffffffc0204220:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204224:	00093797          	auipc	a5,0x93
ffffffffc0204228:	33c78793          	addi	a5,a5,828 # ffffffffc0297560 <hash_list>
ffffffffc020422c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020422e:	6518                	ld	a4,8(a0)
ffffffffc0204230:	0d840793          	addi	a5,s0,216
ffffffffc0204234:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204236:	e31c                	sd	a5,0(a4)
ffffffffc0204238:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc020423a:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020423c:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204240:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204242:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204244:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204246:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020424a:	7b74                	ld	a3,240(a4)
ffffffffc020424c:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020424e:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204250:	e464                	sd	s1,200(s0)
ffffffffc0204252:	10d43023          	sd	a3,256(s0)
ffffffffc0204256:	c299                	beqz	a3,ffffffffc020425c <do_fork+0x204>
        proc->optr->yptr = proc;
ffffffffc0204258:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc020425a:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020425c:	00097797          	auipc	a5,0x97
ffffffffc0204260:	3747a783          	lw	a5,884(a5) # ffffffffc029b5d0 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204264:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204266:	2785                	addiw	a5,a5,1
ffffffffc0204268:	00097717          	auipc	a4,0x97
ffffffffc020426c:	36f72423          	sw	a5,872(a4) # ffffffffc029b5d0 <nr_process>
    if (flag)
ffffffffc0204270:	14091e63          	bnez	s2,ffffffffc02043cc <do_fork+0x374>
    wakeup_proc(proc);
ffffffffc0204274:	8522                	mv	a0,s0
ffffffffc0204276:	703000ef          	jal	ffffffffc0205178 <wakeup_proc>
    ret = proc->pid;
ffffffffc020427a:	4048                	lw	a0,4(s0)
ffffffffc020427c:	64e6                	ld	s1,88(sp)
ffffffffc020427e:	7406                	ld	s0,96(sp)
ffffffffc0204280:	6946                	ld	s2,80(sp)
ffffffffc0204282:	6a06                	ld	s4,64(sp)
ffffffffc0204284:	7ae2                	ld	s5,56(sp)
ffffffffc0204286:	7b42                	ld	s6,48(sp)
ffffffffc0204288:	7ba2                	ld	s7,40(sp)
ffffffffc020428a:	7c02                	ld	s8,32(sp)
ffffffffc020428c:	6ce2                	ld	s9,24(sp)
ffffffffc020428e:	6d42                	ld	s10,16(sp)
}
ffffffffc0204290:	70a6                	ld	ra,104(sp)
ffffffffc0204292:	69a6                	ld	s3,72(sp)
ffffffffc0204294:	6165                	addi	sp,sp,112
ffffffffc0204296:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204298:	e43a                	sd	a4,8(sp)
ffffffffc020429a:	ca0ff0ef          	jal	ffffffffc020373a <mm_create>
ffffffffc020429e:	8d2a                	mv	s10,a0
ffffffffc02042a0:	c959                	beqz	a0,ffffffffc0204336 <do_fork+0x2de>
    if ((page = alloc_page()) == NULL)
ffffffffc02042a2:	4505                	li	a0,1
ffffffffc02042a4:	beffd0ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc02042a8:	c541                	beqz	a0,ffffffffc0204330 <do_fork+0x2d8>
    return page - pages + nbase;
ffffffffc02042aa:	000a3683          	ld	a3,0(s4)
ffffffffc02042ae:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc02042b0:	000b3783          	ld	a5,0(s6)
    return page - pages + nbase;
ffffffffc02042b4:	40d506b3          	sub	a3,a0,a3
ffffffffc02042b8:	8699                	srai	a3,a3,0x6
ffffffffc02042ba:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02042bc:	0196fcb3          	and	s9,a3,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc02042c0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02042c2:	14fcf863          	bgeu	s9,a5,ffffffffc0204412 <do_fork+0x3ba>
ffffffffc02042c6:	000bb783          	ld	a5,0(s7)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02042ca:	00097597          	auipc	a1,0x97
ffffffffc02042ce:	2e65b583          	ld	a1,742(a1) # ffffffffc029b5b0 <boot_pgdir_va>
ffffffffc02042d2:	864e                	mv	a2,s3
ffffffffc02042d4:	00f689b3          	add	s3,a3,a5
ffffffffc02042d8:	854e                	mv	a0,s3
ffffffffc02042da:	542010ef          	jal	ffffffffc020581c <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02042de:	038c0c93          	addi	s9,s8,56
    mm->pgdir = pgdir;
ffffffffc02042e2:	013d3c23          	sd	s3,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02042e6:	4785                	li	a5,1
ffffffffc02042e8:	40fcb7af          	amoor.d	a5,a5,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02042ec:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042f0:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042f4:	4985                	li	s3,1
ffffffffc02042f6:	cb91                	beqz	a5,ffffffffc020430a <do_fork+0x2b2>
    {
        schedule();
ffffffffc02042f8:	715000ef          	jal	ffffffffc020520c <schedule>
ffffffffc02042fc:	413cb7af          	amoor.d	a5,s3,(s9)
    while (!try_lock(lock))
ffffffffc0204300:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204304:	03f75793          	srli	a5,a4,0x3f
ffffffffc0204308:	fbe5                	bnez	a5,ffffffffc02042f8 <do_fork+0x2a0>
        ret = dup_mmap(mm, oldmm);
ffffffffc020430a:	85e2                	mv	a1,s8
ffffffffc020430c:	856a                	mv	a0,s10
ffffffffc020430e:	e88ff0ef          	jal	ffffffffc0203996 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204312:	57f9                	li	a5,-2
ffffffffc0204314:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc0204318:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020431a:	12078563          	beqz	a5,ffffffffc0204444 <do_fork+0x3ec>
    if ((mm = mm_create()) == NULL)
ffffffffc020431e:	8c6a                	mv	s8,s10
    if (ret != 0)
ffffffffc0204320:	de0506e3          	beqz	a0,ffffffffc020410c <do_fork+0xb4>
    exit_mmap(mm);
ffffffffc0204324:	856a                	mv	a0,s10
ffffffffc0204326:	f08ff0ef          	jal	ffffffffc0203a2e <exit_mmap>
    put_pgdir(mm);
ffffffffc020432a:	856a                	mv	a0,s10
ffffffffc020432c:	c45ff0ef          	jal	ffffffffc0203f70 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204330:	856a                	mv	a0,s10
ffffffffc0204332:	d46ff0ef          	jal	ffffffffc0203878 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204336:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204338:	c02007b7          	lui	a5,0xc0200
ffffffffc020433c:	0af6ef63          	bltu	a3,a5,ffffffffc02043fa <do_fork+0x3a2>
ffffffffc0204340:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage)
ffffffffc0204344:	000b3703          	ld	a4,0(s6)
    return pa2page(PADDR(kva));
ffffffffc0204348:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020434c:	83b1                	srli	a5,a5,0xc
ffffffffc020434e:	08e7fa63          	bgeu	a5,a4,ffffffffc02043e2 <do_fork+0x38a>
    return &pages[PPN(pa) - nbase];
ffffffffc0204352:	000ab703          	ld	a4,0(s5)
ffffffffc0204356:	000a3503          	ld	a0,0(s4)
ffffffffc020435a:	4589                	li	a1,2
ffffffffc020435c:	8f99                	sub	a5,a5,a4
ffffffffc020435e:	079a                	slli	a5,a5,0x6
ffffffffc0204360:	953e                	add	a0,a0,a5
ffffffffc0204362:	b6bfd0ef          	jal	ffffffffc0201ecc <free_pages>
}
ffffffffc0204366:	6a06                	ld	s4,64(sp)
ffffffffc0204368:	7ae2                	ld	s5,56(sp)
ffffffffc020436a:	7b42                	ld	s6,48(sp)
ffffffffc020436c:	7c02                	ld	s8,32(sp)
ffffffffc020436e:	6ce2                	ld	s9,24(sp)
    kfree(proc);
ffffffffc0204370:	8522                	mv	a0,s0
ffffffffc0204372:	a05fd0ef          	jal	ffffffffc0201d76 <kfree>
ffffffffc0204376:	7ba2                	ld	s7,40(sp)
ffffffffc0204378:	7406                	ld	s0,96(sp)
ffffffffc020437a:	64e6                	ld	s1,88(sp)
ffffffffc020437c:	6946                	ld	s2,80(sp)
ffffffffc020437e:	6d42                	ld	s10,16(sp)
    ret = -E_NO_MEM;
ffffffffc0204380:	5571                	li	a0,-4
    return ret;
ffffffffc0204382:	b739                	j	ffffffffc0204290 <do_fork+0x238>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204384:	8936                	mv	s2,a3
ffffffffc0204386:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020438a:	00000797          	auipc	a5,0x0
ffffffffc020438e:	b5a78793          	addi	a5,a5,-1190 # ffffffffc0203ee4 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204392:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204394:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204396:	100027f3          	csrr	a5,sstatus
ffffffffc020439a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020439c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020439e:	de0782e3          	beqz	a5,ffffffffc0204182 <do_fork+0x12a>
        intr_disable();
ffffffffc02043a2:	d62fc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc02043a6:	00093517          	auipc	a0,0x93
ffffffffc02043aa:	d9e52503          	lw	a0,-610(a0) # ffffffffc0297144 <last_pid.1>
ffffffffc02043ae:	6789                	lui	a5,0x2
        return 1;
ffffffffc02043b0:	4905                	li	s2,1
ffffffffc02043b2:	2505                	addiw	a0,a0,1
ffffffffc02043b4:	00093717          	auipc	a4,0x93
ffffffffc02043b8:	d8a72823          	sw	a0,-624(a4) # ffffffffc0297144 <last_pid.1>
ffffffffc02043bc:	dcf54fe3          	blt	a0,a5,ffffffffc020419a <do_fork+0x142>
        last_pid = 1;
ffffffffc02043c0:	4505                	li	a0,1
ffffffffc02043c2:	00093797          	auipc	a5,0x93
ffffffffc02043c6:	d8a7a123          	sw	a0,-638(a5) # ffffffffc0297144 <last_pid.1>
        goto inside;
ffffffffc02043ca:	b3d5                	j	ffffffffc02041ae <do_fork+0x156>
        intr_enable();
ffffffffc02043cc:	d32fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02043d0:	b555                	j	ffffffffc0204274 <do_fork+0x21c>
                    if (last_pid >= MAX_PID)
ffffffffc02043d2:	6789                	lui	a5,0x2
ffffffffc02043d4:	00f6c363          	blt	a3,a5,ffffffffc02043da <do_fork+0x382>
                        last_pid = 1;
ffffffffc02043d8:	4685                	li	a3,1
                    goto repeat;
ffffffffc02043da:	4585                	li	a1,1
ffffffffc02043dc:	b3f5                	j	ffffffffc02041c8 <do_fork+0x170>
    int ret = -E_NO_FREE_PROC;
ffffffffc02043de:	556d                	li	a0,-5
ffffffffc02043e0:	bd45                	j	ffffffffc0204290 <do_fork+0x238>
        panic("pa2page called with invalid pa");
ffffffffc02043e2:	00002617          	auipc	a2,0x2
ffffffffc02043e6:	2b660613          	addi	a2,a2,694 # ffffffffc0206698 <etext+0xe64>
ffffffffc02043ea:	06900593          	li	a1,105
ffffffffc02043ee:	00002517          	auipc	a0,0x2
ffffffffc02043f2:	20250513          	addi	a0,a0,514 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02043f6:	850fc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02043fa:	00002617          	auipc	a2,0x2
ffffffffc02043fe:	27660613          	addi	a2,a2,630 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0204402:	07700593          	li	a1,119
ffffffffc0204406:	00002517          	auipc	a0,0x2
ffffffffc020440a:	1ea50513          	addi	a0,a0,490 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc020440e:	838fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204412:	00002617          	auipc	a2,0x2
ffffffffc0204416:	1b660613          	addi	a2,a2,438 # ffffffffc02065c8 <etext+0xd94>
ffffffffc020441a:	07100593          	li	a1,113
ffffffffc020441e:	00002517          	auipc	a0,0x2
ffffffffc0204422:	1d250513          	addi	a0,a0,466 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0204426:	820fc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020442a:	86be                	mv	a3,a5
ffffffffc020442c:	00002617          	auipc	a2,0x2
ffffffffc0204430:	24460613          	addi	a2,a2,580 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0204434:	18e00593          	li	a1,398
ffffffffc0204438:	00003517          	auipc	a0,0x3
ffffffffc020443c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204440:	806fc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204444:	00003617          	auipc	a2,0x3
ffffffffc0204448:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0207010 <etext+0x17dc>
ffffffffc020444c:	03f00593          	li	a1,63
ffffffffc0204450:	00003517          	auipc	a0,0x3
ffffffffc0204454:	bd050513          	addi	a0,a0,-1072 # ffffffffc0207020 <etext+0x17ec>
ffffffffc0204458:	feffb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020445c <kernel_thread>:
{
ffffffffc020445c:	7129                	addi	sp,sp,-320
ffffffffc020445e:	fa22                	sd	s0,304(sp)
ffffffffc0204460:	f626                	sd	s1,296(sp)
ffffffffc0204462:	f24a                	sd	s2,288(sp)
ffffffffc0204464:	842a                	mv	s0,a0
ffffffffc0204466:	84ae                	mv	s1,a1
ffffffffc0204468:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020446a:	850a                	mv	a0,sp
ffffffffc020446c:	12000613          	li	a2,288
ffffffffc0204470:	4581                	li	a1,0
{
ffffffffc0204472:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204474:	396010ef          	jal	ffffffffc020580a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204478:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020447a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020447c:	100027f3          	csrr	a5,sstatus
ffffffffc0204480:	edd7f793          	andi	a5,a5,-291
ffffffffc0204484:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204488:	860a                	mv	a2,sp
ffffffffc020448a:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020448e:	00000717          	auipc	a4,0x0
ffffffffc0204492:	9dc70713          	addi	a4,a4,-1572 # ffffffffc0203e6a <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204496:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204498:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020449a:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020449c:	bbdff0ef          	jal	ffffffffc0204058 <do_fork>
}
ffffffffc02044a0:	70f2                	ld	ra,312(sp)
ffffffffc02044a2:	7452                	ld	s0,304(sp)
ffffffffc02044a4:	74b2                	ld	s1,296(sp)
ffffffffc02044a6:	7912                	ld	s2,288(sp)
ffffffffc02044a8:	6131                	addi	sp,sp,320
ffffffffc02044aa:	8082                	ret

ffffffffc02044ac <do_exit>:
{
ffffffffc02044ac:	7179                	addi	sp,sp,-48
ffffffffc02044ae:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02044b0:	00097417          	auipc	s0,0x97
ffffffffc02044b4:	12840413          	addi	s0,s0,296 # ffffffffc029b5d8 <current>
ffffffffc02044b8:	601c                	ld	a5,0(s0)
ffffffffc02044ba:	00097717          	auipc	a4,0x97
ffffffffc02044be:	12e73703          	ld	a4,302(a4) # ffffffffc029b5e8 <idleproc>
{
ffffffffc02044c2:	f406                	sd	ra,40(sp)
ffffffffc02044c4:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02044c6:	0ce78b63          	beq	a5,a4,ffffffffc020459c <do_exit+0xf0>
    if (current == initproc)
ffffffffc02044ca:	00097497          	auipc	s1,0x97
ffffffffc02044ce:	11648493          	addi	s1,s1,278 # ffffffffc029b5e0 <initproc>
ffffffffc02044d2:	6098                	ld	a4,0(s1)
ffffffffc02044d4:	e84a                	sd	s2,16(sp)
ffffffffc02044d6:	0ee78a63          	beq	a5,a4,ffffffffc02045ca <do_exit+0x11e>
ffffffffc02044da:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc02044dc:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02044de:	c115                	beqz	a0,ffffffffc0204502 <do_exit+0x56>
ffffffffc02044e0:	00097797          	auipc	a5,0x97
ffffffffc02044e4:	0c87b783          	ld	a5,200(a5) # ffffffffc029b5a8 <boot_pgdir_pa>
ffffffffc02044e8:	577d                	li	a4,-1
ffffffffc02044ea:	177e                	slli	a4,a4,0x3f
ffffffffc02044ec:	83b1                	srli	a5,a5,0xc
ffffffffc02044ee:	8fd9                	or	a5,a5,a4
ffffffffc02044f0:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044f4:	591c                	lw	a5,48(a0)
ffffffffc02044f6:	37fd                	addiw	a5,a5,-1
ffffffffc02044f8:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc02044fa:	cfd5                	beqz	a5,ffffffffc02045b6 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc02044fc:	601c                	ld	a5,0(s0)
ffffffffc02044fe:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204502:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc0204504:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204508:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020450a:	100027f3          	csrr	a5,sstatus
ffffffffc020450e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204510:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204512:	ebe1                	bnez	a5,ffffffffc02045e2 <do_exit+0x136>
        proc = current->parent;
ffffffffc0204514:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204516:	800007b7          	lui	a5,0x80000
ffffffffc020451a:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        proc = current->parent;
ffffffffc020451c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020451e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204522:	0cf70463          	beq	a4,a5,ffffffffc02045ea <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204526:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204528:	800005b7          	lui	a1,0x80000
ffffffffc020452c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        while (current->cptr != NULL)
ffffffffc020452e:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204530:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204532:	e789                	bnez	a5,ffffffffc020453c <do_exit+0x90>
ffffffffc0204534:	a83d                	j	ffffffffc0204572 <do_exit+0xc6>
ffffffffc0204536:	6018                	ld	a4,0(s0)
ffffffffc0204538:	7b7c                	ld	a5,240(a4)
ffffffffc020453a:	cf85                	beqz	a5,ffffffffc0204572 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc020453c:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204540:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204542:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc0204544:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204548:	7978                	ld	a4,240(a0)
ffffffffc020454a:	10e7b023          	sd	a4,256(a5)
ffffffffc020454e:	c311                	beqz	a4,ffffffffc0204552 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204550:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204552:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204554:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204556:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204558:	fcc71fe3          	bne	a4,a2,ffffffffc0204536 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020455c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204560:	fcb79be3          	bne	a5,a1,ffffffffc0204536 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc0204564:	415000ef          	jal	ffffffffc0205178 <wakeup_proc>
ffffffffc0204568:	800005b7          	lui	a1,0x80000
ffffffffc020456c:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
ffffffffc020456e:	460d                	li	a2,3
ffffffffc0204570:	b7d9                	j	ffffffffc0204536 <do_exit+0x8a>
    if (flag)
ffffffffc0204572:	02091263          	bnez	s2,ffffffffc0204596 <do_exit+0xea>
    schedule();
ffffffffc0204576:	497000ef          	jal	ffffffffc020520c <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020457a:	601c                	ld	a5,0(s0)
ffffffffc020457c:	00003617          	auipc	a2,0x3
ffffffffc0204580:	adc60613          	addi	a2,a2,-1316 # ffffffffc0207058 <etext+0x1824>
ffffffffc0204584:	24b00593          	li	a1,587
ffffffffc0204588:	43d4                	lw	a3,4(a5)
ffffffffc020458a:	00003517          	auipc	a0,0x3
ffffffffc020458e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204592:	eb5fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc0204596:	b68fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020459a:	bff1                	j	ffffffffc0204576 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc020459c:	00003617          	auipc	a2,0x3
ffffffffc02045a0:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0207038 <etext+0x1804>
ffffffffc02045a4:	21700593          	li	a1,535
ffffffffc02045a8:	00003517          	auipc	a0,0x3
ffffffffc02045ac:	a5050513          	addi	a0,a0,-1456 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02045b0:	e84a                	sd	s2,16(sp)
ffffffffc02045b2:	e95fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc02045b6:	e42a                	sd	a0,8(sp)
ffffffffc02045b8:	c76ff0ef          	jal	ffffffffc0203a2e <exit_mmap>
            put_pgdir(mm);
ffffffffc02045bc:	6522                	ld	a0,8(sp)
ffffffffc02045be:	9b3ff0ef          	jal	ffffffffc0203f70 <put_pgdir>
            mm_destroy(mm);
ffffffffc02045c2:	6522                	ld	a0,8(sp)
ffffffffc02045c4:	ab4ff0ef          	jal	ffffffffc0203878 <mm_destroy>
ffffffffc02045c8:	bf15                	j	ffffffffc02044fc <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02045ca:	00003617          	auipc	a2,0x3
ffffffffc02045ce:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0207048 <etext+0x1814>
ffffffffc02045d2:	21b00593          	li	a1,539
ffffffffc02045d6:	00003517          	auipc	a0,0x3
ffffffffc02045da:	a2250513          	addi	a0,a0,-1502 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02045de:	e69fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc02045e2:	b22fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02045e6:	4905                	li	s2,1
ffffffffc02045e8:	b735                	j	ffffffffc0204514 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02045ea:	38f000ef          	jal	ffffffffc0205178 <wakeup_proc>
ffffffffc02045ee:	bf25                	j	ffffffffc0204526 <do_exit+0x7a>

ffffffffc02045f0 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02045f0:	7179                	addi	sp,sp,-48
ffffffffc02045f2:	ec26                	sd	s1,24(sp)
ffffffffc02045f4:	e84a                	sd	s2,16(sp)
ffffffffc02045f6:	e44e                	sd	s3,8(sp)
ffffffffc02045f8:	f406                	sd	ra,40(sp)
ffffffffc02045fa:	f022                	sd	s0,32(sp)
ffffffffc02045fc:	84aa                	mv	s1,a0
ffffffffc02045fe:	892e                	mv	s2,a1
ffffffffc0204600:	00097997          	auipc	s3,0x97
ffffffffc0204604:	fd898993          	addi	s3,s3,-40 # ffffffffc029b5d8 <current>
    if (pid != 0)
ffffffffc0204608:	cd19                	beqz	a0,ffffffffc0204626 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc020460a:	6789                	lui	a5,0x2
ffffffffc020460c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc020460e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204612:	12e7f563          	bgeu	a5,a4,ffffffffc020473c <do_wait.part.0+0x14c>
}
ffffffffc0204616:	70a2                	ld	ra,40(sp)
ffffffffc0204618:	7402                	ld	s0,32(sp)
ffffffffc020461a:	64e2                	ld	s1,24(sp)
ffffffffc020461c:	6942                	ld	s2,16(sp)
ffffffffc020461e:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204620:	5579                	li	a0,-2
}
ffffffffc0204622:	6145                	addi	sp,sp,48
ffffffffc0204624:	8082                	ret
        proc = current->cptr;
ffffffffc0204626:	0009b703          	ld	a4,0(s3)
ffffffffc020462a:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020462c:	d46d                	beqz	s0,ffffffffc0204616 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020462e:	468d                	li	a3,3
ffffffffc0204630:	a021                	j	ffffffffc0204638 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204632:	10043403          	ld	s0,256(s0)
ffffffffc0204636:	c075                	beqz	s0,ffffffffc020471a <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204638:	401c                	lw	a5,0(s0)
ffffffffc020463a:	fed79ce3          	bne	a5,a3,ffffffffc0204632 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc020463e:	00097797          	auipc	a5,0x97
ffffffffc0204642:	faa7b783          	ld	a5,-86(a5) # ffffffffc029b5e8 <idleproc>
ffffffffc0204646:	14878263          	beq	a5,s0,ffffffffc020478a <do_wait.part.0+0x19a>
ffffffffc020464a:	00097797          	auipc	a5,0x97
ffffffffc020464e:	f967b783          	ld	a5,-106(a5) # ffffffffc029b5e0 <initproc>
ffffffffc0204652:	12f40c63          	beq	s0,a5,ffffffffc020478a <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc0204656:	00090663          	beqz	s2,ffffffffc0204662 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc020465a:	0e842783          	lw	a5,232(s0)
ffffffffc020465e:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204662:	100027f3          	csrr	a5,sstatus
ffffffffc0204666:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204668:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020466a:	10079963          	bnez	a5,ffffffffc020477c <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020466e:	6c74                	ld	a3,216(s0)
ffffffffc0204670:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204672:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc0204676:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204678:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020467a:	6474                	ld	a3,200(s0)
ffffffffc020467c:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc020467e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204680:	e314                	sd	a3,0(a4)
ffffffffc0204682:	c789                	beqz	a5,ffffffffc020468c <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc0204684:	7c78                	ld	a4,248(s0)
ffffffffc0204686:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc0204688:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc020468c:	7c78                	ld	a4,248(s0)
ffffffffc020468e:	c36d                	beqz	a4,ffffffffc0204770 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204690:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204694:	00097797          	auipc	a5,0x97
ffffffffc0204698:	f3c7a783          	lw	a5,-196(a5) # ffffffffc029b5d0 <nr_process>
ffffffffc020469c:	37fd                	addiw	a5,a5,-1
ffffffffc020469e:	00097717          	auipc	a4,0x97
ffffffffc02046a2:	f2f72923          	sw	a5,-206(a4) # ffffffffc029b5d0 <nr_process>
    if (flag)
ffffffffc02046a6:	e271                	bnez	a2,ffffffffc020476a <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02046a8:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02046aa:	c02007b7          	lui	a5,0xc0200
ffffffffc02046ae:	10f6e663          	bltu	a3,a5,ffffffffc02047ba <do_wait.part.0+0x1ca>
ffffffffc02046b2:	00097717          	auipc	a4,0x97
ffffffffc02046b6:	f0673703          	ld	a4,-250(a4) # ffffffffc029b5b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02046ba:	00097797          	auipc	a5,0x97
ffffffffc02046be:	f067b783          	ld	a5,-250(a5) # ffffffffc029b5c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc02046c2:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02046c4:	82b1                	srli	a3,a3,0xc
ffffffffc02046c6:	0cf6fe63          	bgeu	a3,a5,ffffffffc02047a2 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02046ca:	00003797          	auipc	a5,0x3
ffffffffc02046ce:	2b67b783          	ld	a5,694(a5) # ffffffffc0207980 <nbase>
ffffffffc02046d2:	00097517          	auipc	a0,0x97
ffffffffc02046d6:	ef653503          	ld	a0,-266(a0) # ffffffffc029b5c8 <pages>
ffffffffc02046da:	4589                	li	a1,2
ffffffffc02046dc:	8e9d                	sub	a3,a3,a5
ffffffffc02046de:	069a                	slli	a3,a3,0x6
ffffffffc02046e0:	9536                	add	a0,a0,a3
ffffffffc02046e2:	feafd0ef          	jal	ffffffffc0201ecc <free_pages>
    kfree(proc);
ffffffffc02046e6:	8522                	mv	a0,s0
ffffffffc02046e8:	e8efd0ef          	jal	ffffffffc0201d76 <kfree>
}
ffffffffc02046ec:	70a2                	ld	ra,40(sp)
ffffffffc02046ee:	7402                	ld	s0,32(sp)
ffffffffc02046f0:	64e2                	ld	s1,24(sp)
ffffffffc02046f2:	6942                	ld	s2,16(sp)
ffffffffc02046f4:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02046f6:	4501                	li	a0,0
}
ffffffffc02046f8:	6145                	addi	sp,sp,48
ffffffffc02046fa:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02046fc:	00097997          	auipc	s3,0x97
ffffffffc0204700:	edc98993          	addi	s3,s3,-292 # ffffffffc029b5d8 <current>
ffffffffc0204704:	0009b703          	ld	a4,0(s3)
ffffffffc0204708:	f487b683          	ld	a3,-184(a5)
ffffffffc020470c:	f0e695e3          	bne	a3,a4,ffffffffc0204616 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204710:	f287a603          	lw	a2,-216(a5)
ffffffffc0204714:	468d                	li	a3,3
ffffffffc0204716:	06d60063          	beq	a2,a3,ffffffffc0204776 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020471a:	800007b7          	lui	a5,0x80000
ffffffffc020471e:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        current->state = PROC_SLEEPING;
ffffffffc0204720:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204722:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204726:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204728:	2e5000ef          	jal	ffffffffc020520c <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020472c:	0009b783          	ld	a5,0(s3)
ffffffffc0204730:	0b07a783          	lw	a5,176(a5)
ffffffffc0204734:	8b85                	andi	a5,a5,1
ffffffffc0204736:	e7b9                	bnez	a5,ffffffffc0204784 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204738:	ee0487e3          	beqz	s1,ffffffffc0204626 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020473c:	45a9                	li	a1,10
ffffffffc020473e:	8526                	mv	a0,s1
ffffffffc0204740:	435000ef          	jal	ffffffffc0205374 <hash32>
ffffffffc0204744:	02051793          	slli	a5,a0,0x20
ffffffffc0204748:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020474c:	00093797          	auipc	a5,0x93
ffffffffc0204750:	e1478793          	addi	a5,a5,-492 # ffffffffc0297560 <hash_list>
ffffffffc0204754:	953e                	add	a0,a0,a5
ffffffffc0204756:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204758:	a029                	j	ffffffffc0204762 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc020475a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020475e:	f8970fe3          	beq	a4,s1,ffffffffc02046fc <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204762:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204764:	fef51be3          	bne	a0,a5,ffffffffc020475a <do_wait.part.0+0x16a>
ffffffffc0204768:	b57d                	j	ffffffffc0204616 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc020476a:	994fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020476e:	bf2d                	j	ffffffffc02046a8 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204770:	7018                	ld	a4,32(s0)
ffffffffc0204772:	fb7c                	sd	a5,240(a4)
ffffffffc0204774:	b705                	j	ffffffffc0204694 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204776:	f2878413          	addi	s0,a5,-216
ffffffffc020477a:	b5d1                	j	ffffffffc020463e <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc020477c:	988fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204780:	4605                	li	a2,1
ffffffffc0204782:	b5f5                	j	ffffffffc020466e <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc0204784:	555d                	li	a0,-9
ffffffffc0204786:	d27ff0ef          	jal	ffffffffc02044ac <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc020478a:	00003617          	auipc	a2,0x3
ffffffffc020478e:	8ee60613          	addi	a2,a2,-1810 # ffffffffc0207078 <etext+0x1844>
ffffffffc0204792:	36c00593          	li	a1,876
ffffffffc0204796:	00003517          	auipc	a0,0x3
ffffffffc020479a:	86250513          	addi	a0,a0,-1950 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc020479e:	ca9fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02047a2:	00002617          	auipc	a2,0x2
ffffffffc02047a6:	ef660613          	addi	a2,a2,-266 # ffffffffc0206698 <etext+0xe64>
ffffffffc02047aa:	06900593          	li	a1,105
ffffffffc02047ae:	00002517          	auipc	a0,0x2
ffffffffc02047b2:	e4250513          	addi	a0,a0,-446 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02047b6:	c91fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02047ba:	00002617          	auipc	a2,0x2
ffffffffc02047be:	eb660613          	addi	a2,a2,-330 # ffffffffc0206670 <etext+0xe3c>
ffffffffc02047c2:	07700593          	li	a1,119
ffffffffc02047c6:	00002517          	auipc	a0,0x2
ffffffffc02047ca:	e2a50513          	addi	a0,a0,-470 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc02047ce:	c79fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02047d2 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047d2:	1141                	addi	sp,sp,-16
ffffffffc02047d4:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047d6:	f2efd0ef          	jal	ffffffffc0201f04 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047da:	cf2fd0ef          	jal	ffffffffc0201ccc <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047de:	4601                	li	a2,0
ffffffffc02047e0:	4581                	li	a1,0
ffffffffc02047e2:	fffff517          	auipc	a0,0xfffff
ffffffffc02047e6:	71050513          	addi	a0,a0,1808 # ffffffffc0203ef2 <user_main>
ffffffffc02047ea:	c73ff0ef          	jal	ffffffffc020445c <kernel_thread>
    if (pid <= 0)
ffffffffc02047ee:	00a04563          	bgtz	a0,ffffffffc02047f8 <init_main+0x26>
ffffffffc02047f2:	a071                	j	ffffffffc020487e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047f4:	219000ef          	jal	ffffffffc020520c <schedule>
    if (code_store != NULL)
ffffffffc02047f8:	4581                	li	a1,0
ffffffffc02047fa:	4501                	li	a0,0
ffffffffc02047fc:	df5ff0ef          	jal	ffffffffc02045f0 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204800:	d975                	beqz	a0,ffffffffc02047f4 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204802:	00003517          	auipc	a0,0x3
ffffffffc0204806:	8b650513          	addi	a0,a0,-1866 # ffffffffc02070b8 <etext+0x1884>
ffffffffc020480a:	98bfb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020480e:	00097797          	auipc	a5,0x97
ffffffffc0204812:	dd27b783          	ld	a5,-558(a5) # ffffffffc029b5e0 <initproc>
ffffffffc0204816:	7bf8                	ld	a4,240(a5)
ffffffffc0204818:	e339                	bnez	a4,ffffffffc020485e <init_main+0x8c>
ffffffffc020481a:	7ff8                	ld	a4,248(a5)
ffffffffc020481c:	e329                	bnez	a4,ffffffffc020485e <init_main+0x8c>
ffffffffc020481e:	1007b703          	ld	a4,256(a5)
ffffffffc0204822:	ef15                	bnez	a4,ffffffffc020485e <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204824:	00097697          	auipc	a3,0x97
ffffffffc0204828:	dac6a683          	lw	a3,-596(a3) # ffffffffc029b5d0 <nr_process>
ffffffffc020482c:	4709                	li	a4,2
ffffffffc020482e:	0ae69463          	bne	a3,a4,ffffffffc02048d6 <init_main+0x104>
ffffffffc0204832:	00097697          	auipc	a3,0x97
ffffffffc0204836:	d2e68693          	addi	a3,a3,-722 # ffffffffc029b560 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020483a:	6698                	ld	a4,8(a3)
ffffffffc020483c:	0c878793          	addi	a5,a5,200
ffffffffc0204840:	06f71b63          	bne	a4,a5,ffffffffc02048b6 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204844:	629c                	ld	a5,0(a3)
ffffffffc0204846:	04f71863          	bne	a4,a5,ffffffffc0204896 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020484a:	00003517          	auipc	a0,0x3
ffffffffc020484e:	95650513          	addi	a0,a0,-1706 # ffffffffc02071a0 <etext+0x196c>
ffffffffc0204852:	943fb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204856:	60a2                	ld	ra,8(sp)
ffffffffc0204858:	4501                	li	a0,0
ffffffffc020485a:	0141                	addi	sp,sp,16
ffffffffc020485c:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020485e:	00003697          	auipc	a3,0x3
ffffffffc0204862:	88268693          	addi	a3,a3,-1918 # ffffffffc02070e0 <etext+0x18ac>
ffffffffc0204866:	00002617          	auipc	a2,0x2
ffffffffc020486a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206218 <etext+0x9e4>
ffffffffc020486e:	3da00593          	li	a1,986
ffffffffc0204872:	00002517          	auipc	a0,0x2
ffffffffc0204876:	78650513          	addi	a0,a0,1926 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc020487a:	bcdfb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc020487e:	00003617          	auipc	a2,0x3
ffffffffc0204882:	81a60613          	addi	a2,a2,-2022 # ffffffffc0207098 <etext+0x1864>
ffffffffc0204886:	3d100593          	li	a1,977
ffffffffc020488a:	00002517          	auipc	a0,0x2
ffffffffc020488e:	76e50513          	addi	a0,a0,1902 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204892:	bb5fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204896:	00003697          	auipc	a3,0x3
ffffffffc020489a:	8da68693          	addi	a3,a3,-1830 # ffffffffc0207170 <etext+0x193c>
ffffffffc020489e:	00002617          	auipc	a2,0x2
ffffffffc02048a2:	97a60613          	addi	a2,a2,-1670 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02048a6:	3dd00593          	li	a1,989
ffffffffc02048aa:	00002517          	auipc	a0,0x2
ffffffffc02048ae:	74e50513          	addi	a0,a0,1870 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02048b2:	b95fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048b6:	00003697          	auipc	a3,0x3
ffffffffc02048ba:	88a68693          	addi	a3,a3,-1910 # ffffffffc0207140 <etext+0x190c>
ffffffffc02048be:	00002617          	auipc	a2,0x2
ffffffffc02048c2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02048c6:	3dc00593          	li	a1,988
ffffffffc02048ca:	00002517          	auipc	a0,0x2
ffffffffc02048ce:	72e50513          	addi	a0,a0,1838 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02048d2:	b75fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc02048d6:	00003697          	auipc	a3,0x3
ffffffffc02048da:	85a68693          	addi	a3,a3,-1958 # ffffffffc0207130 <etext+0x18fc>
ffffffffc02048de:	00002617          	auipc	a2,0x2
ffffffffc02048e2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02048e6:	3db00593          	li	a1,987
ffffffffc02048ea:	00002517          	auipc	a0,0x2
ffffffffc02048ee:	70e50513          	addi	a0,a0,1806 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02048f2:	b55fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02048f6 <do_execve>:
{
ffffffffc02048f6:	7171                	addi	sp,sp,-176
ffffffffc02048f8:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048fa:	00097d17          	auipc	s10,0x97
ffffffffc02048fe:	cded0d13          	addi	s10,s10,-802 # ffffffffc029b5d8 <current>
ffffffffc0204902:	000d3783          	ld	a5,0(s10)
{
ffffffffc0204906:	e94a                	sd	s2,144(sp)
ffffffffc0204908:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020490a:	0287b903          	ld	s2,40(a5)
{
ffffffffc020490e:	84ae                	mv	s1,a1
ffffffffc0204910:	e54e                	sd	s3,136(sp)
ffffffffc0204912:	ec32                	sd	a2,24(sp)
ffffffffc0204914:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204916:	85aa                	mv	a1,a0
ffffffffc0204918:	8626                	mv	a2,s1
ffffffffc020491a:	854a                	mv	a0,s2
ffffffffc020491c:	4681                	li	a3,0
{
ffffffffc020491e:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204920:	ca6ff0ef          	jal	ffffffffc0203dc6 <user_mem_check>
ffffffffc0204924:	46050f63          	beqz	a0,ffffffffc0204da2 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204928:	4641                	li	a2,16
ffffffffc020492a:	1808                	addi	a0,sp,48
ffffffffc020492c:	4581                	li	a1,0
ffffffffc020492e:	6dd000ef          	jal	ffffffffc020580a <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204932:	47bd                	li	a5,15
ffffffffc0204934:	8626                	mv	a2,s1
ffffffffc0204936:	0e97ef63          	bltu	a5,s1,ffffffffc0204a34 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc020493a:	85ce                	mv	a1,s3
ffffffffc020493c:	1808                	addi	a0,sp,48
ffffffffc020493e:	6df000ef          	jal	ffffffffc020581c <memcpy>
    if (mm != NULL)
ffffffffc0204942:	10090063          	beqz	s2,ffffffffc0204a42 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc0204946:	00002517          	auipc	a0,0x2
ffffffffc020494a:	47a50513          	addi	a0,a0,1146 # ffffffffc0206dc0 <etext+0x158c>
ffffffffc020494e:	87dfb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc0204952:	00097797          	auipc	a5,0x97
ffffffffc0204956:	c567b783          	ld	a5,-938(a5) # ffffffffc029b5a8 <boot_pgdir_pa>
ffffffffc020495a:	577d                	li	a4,-1
ffffffffc020495c:	177e                	slli	a4,a4,0x3f
ffffffffc020495e:	83b1                	srli	a5,a5,0xc
ffffffffc0204960:	8fd9                	or	a5,a5,a4
ffffffffc0204962:	18079073          	csrw	satp,a5
ffffffffc0204966:	03092783          	lw	a5,48(s2)
ffffffffc020496a:	37fd                	addiw	a5,a5,-1
ffffffffc020496c:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204970:	30078563          	beqz	a5,ffffffffc0204c7a <do_execve+0x384>
        current->mm = NULL;
ffffffffc0204974:	000d3783          	ld	a5,0(s10)
ffffffffc0204978:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020497c:	dbffe0ef          	jal	ffffffffc020373a <mm_create>
ffffffffc0204980:	892a                	mv	s2,a0
ffffffffc0204982:	22050063          	beqz	a0,ffffffffc0204ba2 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc0204986:	4505                	li	a0,1
ffffffffc0204988:	d0afd0ef          	jal	ffffffffc0201e92 <alloc_pages>
ffffffffc020498c:	42050063          	beqz	a0,ffffffffc0204dac <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc0204990:	f0e2                	sd	s8,96(sp)
ffffffffc0204992:	00097c17          	auipc	s8,0x97
ffffffffc0204996:	c36c0c13          	addi	s8,s8,-970 # ffffffffc029b5c8 <pages>
ffffffffc020499a:	000c3783          	ld	a5,0(s8)
ffffffffc020499e:	f4de                	sd	s7,104(sp)
ffffffffc02049a0:	00003b97          	auipc	s7,0x3
ffffffffc02049a4:	fe0bbb83          	ld	s7,-32(s7) # ffffffffc0207980 <nbase>
ffffffffc02049a8:	40f506b3          	sub	a3,a0,a5
ffffffffc02049ac:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02049ae:	00097c97          	auipc	s9,0x97
ffffffffc02049b2:	c12c8c93          	addi	s9,s9,-1006 # ffffffffc029b5c0 <npage>
ffffffffc02049b6:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02049b8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049ba:	5b7d                	li	s6,-1
ffffffffc02049bc:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02049c0:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02049c2:	00cb5713          	srli	a4,s6,0xc
ffffffffc02049c6:	e83a                	sd	a4,16(sp)
ffffffffc02049c8:	fcd6                	sd	s5,120(sp)
ffffffffc02049ca:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049cc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049ce:	40f77263          	bgeu	a4,a5,ffffffffc0204dd2 <do_execve+0x4dc>
ffffffffc02049d2:	00097a97          	auipc	s5,0x97
ffffffffc02049d6:	be6a8a93          	addi	s5,s5,-1050 # ffffffffc029b5b8 <va_pa_offset>
ffffffffc02049da:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049de:	00097597          	auipc	a1,0x97
ffffffffc02049e2:	bd25b583          	ld	a1,-1070(a1) # ffffffffc029b5b0 <boot_pgdir_va>
ffffffffc02049e6:	6605                	lui	a2,0x1
ffffffffc02049e8:	00f684b3          	add	s1,a3,a5
ffffffffc02049ec:	8526                	mv	a0,s1
ffffffffc02049ee:	62f000ef          	jal	ffffffffc020581c <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049f2:	66e2                	ld	a3,24(sp)
ffffffffc02049f4:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049f8:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049fc:	4298                	lw	a4,0(a3)
ffffffffc02049fe:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3c7>
ffffffffc0204a02:	06f70863          	beq	a4,a5,ffffffffc0204a72 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204a06:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204a08:	854a                	mv	a0,s2
ffffffffc0204a0a:	d66ff0ef          	jal	ffffffffc0203f70 <put_pgdir>
ffffffffc0204a0e:	7ae6                	ld	s5,120(sp)
ffffffffc0204a10:	7b46                	ld	s6,112(sp)
ffffffffc0204a12:	7ba6                	ld	s7,104(sp)
ffffffffc0204a14:	7c06                	ld	s8,96(sp)
ffffffffc0204a16:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204a18:	854a                	mv	a0,s2
ffffffffc0204a1a:	e5ffe0ef          	jal	ffffffffc0203878 <mm_destroy>
    do_exit(ret);
ffffffffc0204a1e:	8526                	mv	a0,s1
ffffffffc0204a20:	f122                	sd	s0,160(sp)
ffffffffc0204a22:	e152                	sd	s4,128(sp)
ffffffffc0204a24:	fcd6                	sd	s5,120(sp)
ffffffffc0204a26:	f8da                	sd	s6,112(sp)
ffffffffc0204a28:	f4de                	sd	s7,104(sp)
ffffffffc0204a2a:	f0e2                	sd	s8,96(sp)
ffffffffc0204a2c:	ece6                	sd	s9,88(sp)
ffffffffc0204a2e:	e4ee                	sd	s11,72(sp)
ffffffffc0204a30:	a7dff0ef          	jal	ffffffffc02044ac <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204a34:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204a36:	85ce                	mv	a1,s3
ffffffffc0204a38:	1808                	addi	a0,sp,48
ffffffffc0204a3a:	5e3000ef          	jal	ffffffffc020581c <memcpy>
    if (mm != NULL)
ffffffffc0204a3e:	f00914e3          	bnez	s2,ffffffffc0204946 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204a42:	000d3783          	ld	a5,0(s10)
ffffffffc0204a46:	779c                	ld	a5,40(a5)
ffffffffc0204a48:	db95                	beqz	a5,ffffffffc020497c <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a4a:	00002617          	auipc	a2,0x2
ffffffffc0204a4e:	77660613          	addi	a2,a2,1910 # ffffffffc02071c0 <etext+0x198c>
ffffffffc0204a52:	25700593          	li	a1,599
ffffffffc0204a56:	00002517          	auipc	a0,0x2
ffffffffc0204a5a:	5a250513          	addi	a0,a0,1442 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204a5e:	f122                	sd	s0,160(sp)
ffffffffc0204a60:	e152                	sd	s4,128(sp)
ffffffffc0204a62:	fcd6                	sd	s5,120(sp)
ffffffffc0204a64:	f8da                	sd	s6,112(sp)
ffffffffc0204a66:	f4de                	sd	s7,104(sp)
ffffffffc0204a68:	f0e2                	sd	s8,96(sp)
ffffffffc0204a6a:	ece6                	sd	s9,88(sp)
ffffffffc0204a6c:	e4ee                	sd	s11,72(sp)
ffffffffc0204a6e:	9d9fb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a72:	0386d703          	lhu	a4,56(a3)
ffffffffc0204a76:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a78:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a7c:	00371793          	slli	a5,a4,0x3
ffffffffc0204a80:	8f99                	sub	a5,a5,a4
ffffffffc0204a82:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a84:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a86:	97d2                	add	a5,a5,s4
ffffffffc0204a88:	f122                	sd	s0,160(sp)
ffffffffc0204a8a:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a8c:	00fa7e63          	bgeu	s4,a5,ffffffffc0204aa8 <do_execve+0x1b2>
ffffffffc0204a90:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a92:	000a2783          	lw	a5,0(s4)
ffffffffc0204a96:	4705                	li	a4,1
ffffffffc0204a98:	10e78763          	beq	a5,a4,ffffffffc0204ba6 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc0204a9c:	77a2                	ld	a5,40(sp)
ffffffffc0204a9e:	038a0a13          	addi	s4,s4,56
ffffffffc0204aa2:	fefa68e3          	bltu	s4,a5,ffffffffc0204a92 <do_execve+0x19c>
ffffffffc0204aa6:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204aa8:	4701                	li	a4,0
ffffffffc0204aaa:	46ad                	li	a3,11
ffffffffc0204aac:	00100637          	lui	a2,0x100
ffffffffc0204ab0:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204ab4:	854a                	mv	a0,s2
ffffffffc0204ab6:	e15fe0ef          	jal	ffffffffc02038ca <mm_map>
ffffffffc0204aba:	84aa                	mv	s1,a0
ffffffffc0204abc:	1a051963          	bnez	a0,ffffffffc0204c6e <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ac0:	01893503          	ld	a0,24(s2)
ffffffffc0204ac4:	467d                	li	a2,31
ffffffffc0204ac6:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204aca:	b8ffe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204ace:	3a050163          	beqz	a0,ffffffffc0204e70 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ad2:	01893503          	ld	a0,24(s2)
ffffffffc0204ad6:	467d                	li	a2,31
ffffffffc0204ad8:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204adc:	b7dfe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204ae0:	36050763          	beqz	a0,ffffffffc0204e4e <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ae4:	01893503          	ld	a0,24(s2)
ffffffffc0204ae8:	467d                	li	a2,31
ffffffffc0204aea:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204aee:	b6bfe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204af2:	32050d63          	beqz	a0,ffffffffc0204e2c <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204af6:	01893503          	ld	a0,24(s2)
ffffffffc0204afa:	467d                	li	a2,31
ffffffffc0204afc:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b00:	b59fe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204b04:	30050363          	beqz	a0,ffffffffc0204e0a <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204b08:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b0c:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b10:	01893683          	ld	a3,24(s2)
ffffffffc0204b14:	2785                	addiw	a5,a5,1
ffffffffc0204b16:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b1a:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e70>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b1e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b22:	2cf6e763          	bltu	a3,a5,ffffffffc0204df0 <do_execve+0x4fa>
ffffffffc0204b26:	000ab783          	ld	a5,0(s5)
ffffffffc0204b2a:	577d                	li	a4,-1
ffffffffc0204b2c:	177e                	slli	a4,a4,0x3f
ffffffffc0204b2e:	8e9d                	sub	a3,a3,a5
ffffffffc0204b30:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b34:	f654                	sd	a3,168(a2)
ffffffffc0204b36:	8fd9                	or	a5,a5,a4
ffffffffc0204b38:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b3c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b3e:	4581                	li	a1,0
ffffffffc0204b40:	12000613          	li	a2,288
ffffffffc0204b44:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b46:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b4a:	4c1000ef          	jal	ffffffffc020580a <memset>
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204b4e:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b50:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204b54:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204b58:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc0204b5a:	4785                	li	a5,1
ffffffffc0204b5c:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204b5e:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry; // 设置程序计数器
ffffffffc0204b62:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
ffffffffc0204b66:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
ffffffffc0204b68:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b6c:	4641                	li	a2,16
ffffffffc0204b6e:	4581                	li	a1,0
ffffffffc0204b70:	0b498513          	addi	a0,s3,180
ffffffffc0204b74:	497000ef          	jal	ffffffffc020580a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b78:	180c                	addi	a1,sp,48
ffffffffc0204b7a:	0b498513          	addi	a0,s3,180
ffffffffc0204b7e:	463d                	li	a2,15
ffffffffc0204b80:	49d000ef          	jal	ffffffffc020581c <memcpy>
ffffffffc0204b84:	740a                	ld	s0,160(sp)
ffffffffc0204b86:	6a0a                	ld	s4,128(sp)
ffffffffc0204b88:	7ae6                	ld	s5,120(sp)
ffffffffc0204b8a:	7b46                	ld	s6,112(sp)
ffffffffc0204b8c:	7ba6                	ld	s7,104(sp)
ffffffffc0204b8e:	7c06                	ld	s8,96(sp)
ffffffffc0204b90:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204b92:	70aa                	ld	ra,168(sp)
ffffffffc0204b94:	694a                	ld	s2,144(sp)
ffffffffc0204b96:	69aa                	ld	s3,136(sp)
ffffffffc0204b98:	6d46                	ld	s10,80(sp)
ffffffffc0204b9a:	8526                	mv	a0,s1
ffffffffc0204b9c:	64ea                	ld	s1,152(sp)
ffffffffc0204b9e:	614d                	addi	sp,sp,176
ffffffffc0204ba0:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204ba2:	54f1                	li	s1,-4
ffffffffc0204ba4:	bdad                	j	ffffffffc0204a1e <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204ba6:	028a3603          	ld	a2,40(s4)
ffffffffc0204baa:	020a3783          	ld	a5,32(s4)
ffffffffc0204bae:	20f66363          	bltu	a2,a5,ffffffffc0204db4 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bb2:	004a2783          	lw	a5,4(s4)
ffffffffc0204bb6:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bba:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bbe:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bc0:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bc2:	c6f1                	beqz	a3,ffffffffc0204c8e <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bc4:	1c079763          	bnez	a5,ffffffffc0204d92 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bc8:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204bca:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204bce:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204bd0:	c709                	beqz	a4,ffffffffc0204bda <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204bd2:	67a2                	ld	a5,8(sp)
ffffffffc0204bd4:	0087e793          	ori	a5,a5,8
ffffffffc0204bd8:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bda:	010a3583          	ld	a1,16(s4)
ffffffffc0204bde:	4701                	li	a4,0
ffffffffc0204be0:	854a                	mv	a0,s2
ffffffffc0204be2:	ce9fe0ef          	jal	ffffffffc02038ca <mm_map>
ffffffffc0204be6:	84aa                	mv	s1,a0
ffffffffc0204be8:	1c051463          	bnez	a0,ffffffffc0204db0 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bec:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bf0:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bf4:	77fd                	lui	a5,0xfffff
ffffffffc0204bf6:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bfa:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204bfc:	1a9b7563          	bgeu	s6,s1,ffffffffc0204da6 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c00:	008a3983          	ld	s3,8(s4)
ffffffffc0204c04:	67e2                	ld	a5,24(sp)
ffffffffc0204c06:	99be                	add	s3,s3,a5
ffffffffc0204c08:	a881                	j	ffffffffc0204c58 <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c0a:	6785                	lui	a5,0x1
ffffffffc0204c0c:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204c10:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204c14:	01b4e463          	bltu	s1,s11,ffffffffc0204c1c <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c18:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204c1c:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c20:	67c2                	ld	a5,16(sp)
ffffffffc0204c22:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204c26:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c2a:	8699                	srai	a3,a3,0x6
ffffffffc0204c2c:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c2e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c32:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c34:	18a87363          	bgeu	a6,a0,ffffffffc0204dba <do_execve+0x4c4>
ffffffffc0204c38:	000ab503          	ld	a0,0(s5)
ffffffffc0204c3c:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c40:	e032                	sd	a2,0(sp)
ffffffffc0204c42:	9536                	add	a0,a0,a3
ffffffffc0204c44:	952e                	add	a0,a0,a1
ffffffffc0204c46:	85ce                	mv	a1,s3
ffffffffc0204c48:	3d5000ef          	jal	ffffffffc020581c <memcpy>
            start += size, from += size;
ffffffffc0204c4c:	6602                	ld	a2,0(sp)
ffffffffc0204c4e:	9b32                	add	s6,s6,a2
ffffffffc0204c50:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204c52:	049b7563          	bgeu	s6,s1,ffffffffc0204c9c <do_execve+0x3a6>
ffffffffc0204c56:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c58:	01893503          	ld	a0,24(s2)
ffffffffc0204c5c:	6622                	ld	a2,8(sp)
ffffffffc0204c5e:	e02e                	sd	a1,0(sp)
ffffffffc0204c60:	9f9fe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204c64:	6582                	ld	a1,0(sp)
ffffffffc0204c66:	842a                	mv	s0,a0
ffffffffc0204c68:	f14d                	bnez	a0,ffffffffc0204c0a <do_execve+0x314>
ffffffffc0204c6a:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204c6c:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204c6e:	854a                	mv	a0,s2
ffffffffc0204c70:	dbffe0ef          	jal	ffffffffc0203a2e <exit_mmap>
ffffffffc0204c74:	740a                	ld	s0,160(sp)
ffffffffc0204c76:	6a0a                	ld	s4,128(sp)
ffffffffc0204c78:	bb41                	j	ffffffffc0204a08 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204c7a:	854a                	mv	a0,s2
ffffffffc0204c7c:	db3fe0ef          	jal	ffffffffc0203a2e <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c80:	854a                	mv	a0,s2
ffffffffc0204c82:	aeeff0ef          	jal	ffffffffc0203f70 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c86:	854a                	mv	a0,s2
ffffffffc0204c88:	bf1fe0ef          	jal	ffffffffc0203878 <mm_destroy>
ffffffffc0204c8c:	b1e5                	j	ffffffffc0204974 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c8e:	0e078e63          	beqz	a5,ffffffffc0204d8a <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204c92:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204c94:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204c98:	e43e                	sd	a5,8(sp)
ffffffffc0204c9a:	bf1d                	j	ffffffffc0204bd0 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c9c:	010a3483          	ld	s1,16(s4)
ffffffffc0204ca0:	028a3683          	ld	a3,40(s4)
ffffffffc0204ca4:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204ca6:	07bb7c63          	bgeu	s6,s11,ffffffffc0204d1e <do_execve+0x428>
            if (start == end)
ffffffffc0204caa:	df6489e3          	beq	s1,s6,ffffffffc0204a9c <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204cae:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204cb2:	0fb4f563          	bgeu	s1,s11,ffffffffc0204d9c <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204cb6:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204cba:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204cbe:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cc2:	8699                	srai	a3,a3,0x6
ffffffffc0204cc4:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cc6:	00c69593          	slli	a1,a3,0xc
ffffffffc0204cca:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ccc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cce:	0ec5f663          	bgeu	a1,a2,ffffffffc0204dba <do_execve+0x4c4>
ffffffffc0204cd2:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cd6:	6505                	lui	a0,0x1
ffffffffc0204cd8:	955a                	add	a0,a0,s6
ffffffffc0204cda:	96b2                	add	a3,a3,a2
ffffffffc0204cdc:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ce0:	9536                	add	a0,a0,a3
ffffffffc0204ce2:	864e                	mv	a2,s3
ffffffffc0204ce4:	4581                	li	a1,0
ffffffffc0204ce6:	325000ef          	jal	ffffffffc020580a <memset>
            start += size;
ffffffffc0204cea:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cec:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204cf0:	01b4f463          	bgeu	s1,s11,ffffffffc0204cf8 <do_execve+0x402>
ffffffffc0204cf4:	db6484e3          	beq	s1,s6,ffffffffc0204a9c <do_execve+0x1a6>
ffffffffc0204cf8:	e299                	bnez	a3,ffffffffc0204cfe <do_execve+0x408>
ffffffffc0204cfa:	03bb0263          	beq	s6,s11,ffffffffc0204d1e <do_execve+0x428>
ffffffffc0204cfe:	00002697          	auipc	a3,0x2
ffffffffc0204d02:	4ea68693          	addi	a3,a3,1258 # ffffffffc02071e8 <etext+0x19b4>
ffffffffc0204d06:	00001617          	auipc	a2,0x1
ffffffffc0204d0a:	51260613          	addi	a2,a2,1298 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0204d0e:	2c000593          	li	a1,704
ffffffffc0204d12:	00002517          	auipc	a0,0x2
ffffffffc0204d16:	2e650513          	addi	a0,a0,742 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204d1a:	f2cfb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204d1e:	d69b7fe3          	bgeu	s6,s1,ffffffffc0204a9c <do_execve+0x1a6>
ffffffffc0204d22:	56fd                	li	a3,-1
ffffffffc0204d24:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d28:	f03e                	sd	a5,32(sp)
ffffffffc0204d2a:	a0b9                	j	ffffffffc0204d78 <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d2c:	6785                	lui	a5,0x1
ffffffffc0204d2e:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204d32:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d36:	0104e463          	bltu	s1,a6,ffffffffc0204d3e <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d3a:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204d3e:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d42:	7782                	ld	a5,32(sp)
ffffffffc0204d44:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204d48:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d4c:	8699                	srai	a3,a3,0x6
ffffffffc0204d4e:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d50:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d56:	06b57263          	bgeu	a0,a1,ffffffffc0204dba <do_execve+0x4c4>
ffffffffc0204d5a:	000ab583          	ld	a1,0(s5)
ffffffffc0204d5e:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d62:	864e                	mv	a2,s3
ffffffffc0204d64:	96ae                	add	a3,a3,a1
ffffffffc0204d66:	9536                	add	a0,a0,a3
ffffffffc0204d68:	4581                	li	a1,0
            start += size;
ffffffffc0204d6a:	9b4e                	add	s6,s6,s3
ffffffffc0204d6c:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d6e:	29d000ef          	jal	ffffffffc020580a <memset>
        while (start < end)
ffffffffc0204d72:	d29b75e3          	bgeu	s6,s1,ffffffffc0204a9c <do_execve+0x1a6>
ffffffffc0204d76:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d78:	01893503          	ld	a0,24(s2)
ffffffffc0204d7c:	6622                	ld	a2,8(sp)
ffffffffc0204d7e:	85ee                	mv	a1,s11
ffffffffc0204d80:	8d9fe0ef          	jal	ffffffffc0203658 <pgdir_alloc_page>
ffffffffc0204d84:	842a                	mv	s0,a0
ffffffffc0204d86:	f15d                	bnez	a0,ffffffffc0204d2c <do_execve+0x436>
ffffffffc0204d88:	b5cd                	j	ffffffffc0204c6a <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d8a:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d8c:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d8e:	e43e                	sd	a5,8(sp)
ffffffffc0204d90:	b581                	j	ffffffffc0204bd0 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d92:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204d94:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204d98:	e43e                	sd	a5,8(sp)
ffffffffc0204d9a:	bd1d                	j	ffffffffc0204bd0 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d9c:	416d89b3          	sub	s3,s11,s6
ffffffffc0204da0:	bf19                	j	ffffffffc0204cb6 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204da2:	54f5                	li	s1,-3
ffffffffc0204da4:	b3fd                	j	ffffffffc0204b92 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204da6:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204da8:	84da                	mv	s1,s6
ffffffffc0204daa:	bddd                	j	ffffffffc0204ca0 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204dac:	54f1                	li	s1,-4
ffffffffc0204dae:	b1ad                	j	ffffffffc0204a18 <do_execve+0x122>
ffffffffc0204db0:	6da6                	ld	s11,72(sp)
ffffffffc0204db2:	bd75                	j	ffffffffc0204c6e <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204db4:	6da6                	ld	s11,72(sp)
ffffffffc0204db6:	54e1                	li	s1,-8
ffffffffc0204db8:	bd5d                	j	ffffffffc0204c6e <do_execve+0x378>
ffffffffc0204dba:	00002617          	auipc	a2,0x2
ffffffffc0204dbe:	80e60613          	addi	a2,a2,-2034 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0204dc2:	07100593          	li	a1,113
ffffffffc0204dc6:	00002517          	auipc	a0,0x2
ffffffffc0204dca:	82a50513          	addi	a0,a0,-2006 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0204dce:	e78fb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204dd2:	00001617          	auipc	a2,0x1
ffffffffc0204dd6:	7f660613          	addi	a2,a2,2038 # ffffffffc02065c8 <etext+0xd94>
ffffffffc0204dda:	07100593          	li	a1,113
ffffffffc0204dde:	00002517          	auipc	a0,0x2
ffffffffc0204de2:	81250513          	addi	a0,a0,-2030 # ffffffffc02065f0 <etext+0xdbc>
ffffffffc0204de6:	f122                	sd	s0,160(sp)
ffffffffc0204de8:	e152                	sd	s4,128(sp)
ffffffffc0204dea:	e4ee                	sd	s11,72(sp)
ffffffffc0204dec:	e5afb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204df0:	00002617          	auipc	a2,0x2
ffffffffc0204df4:	88060613          	addi	a2,a2,-1920 # ffffffffc0206670 <etext+0xe3c>
ffffffffc0204df8:	2df00593          	li	a1,735
ffffffffc0204dfc:	00002517          	auipc	a0,0x2
ffffffffc0204e00:	1fc50513          	addi	a0,a0,508 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204e04:	e4ee                	sd	s11,72(sp)
ffffffffc0204e06:	e40fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e0a:	00002697          	auipc	a3,0x2
ffffffffc0204e0e:	4f668693          	addi	a3,a3,1270 # ffffffffc0207300 <etext+0x1acc>
ffffffffc0204e12:	00001617          	auipc	a2,0x1
ffffffffc0204e16:	40660613          	addi	a2,a2,1030 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0204e1a:	2da00593          	li	a1,730
ffffffffc0204e1e:	00002517          	auipc	a0,0x2
ffffffffc0204e22:	1da50513          	addi	a0,a0,474 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204e26:	e4ee                	sd	s11,72(sp)
ffffffffc0204e28:	e1efb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e2c:	00002697          	auipc	a3,0x2
ffffffffc0204e30:	48c68693          	addi	a3,a3,1164 # ffffffffc02072b8 <etext+0x1a84>
ffffffffc0204e34:	00001617          	auipc	a2,0x1
ffffffffc0204e38:	3e460613          	addi	a2,a2,996 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0204e3c:	2d900593          	li	a1,729
ffffffffc0204e40:	00002517          	auipc	a0,0x2
ffffffffc0204e44:	1b850513          	addi	a0,a0,440 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204e48:	e4ee                	sd	s11,72(sp)
ffffffffc0204e4a:	dfcfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e4e:	00002697          	auipc	a3,0x2
ffffffffc0204e52:	42268693          	addi	a3,a3,1058 # ffffffffc0207270 <etext+0x1a3c>
ffffffffc0204e56:	00001617          	auipc	a2,0x1
ffffffffc0204e5a:	3c260613          	addi	a2,a2,962 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0204e5e:	2d800593          	li	a1,728
ffffffffc0204e62:	00002517          	auipc	a0,0x2
ffffffffc0204e66:	19650513          	addi	a0,a0,406 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204e6a:	e4ee                	sd	s11,72(sp)
ffffffffc0204e6c:	ddafb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e70:	00002697          	auipc	a3,0x2
ffffffffc0204e74:	3b868693          	addi	a3,a3,952 # ffffffffc0207228 <etext+0x19f4>
ffffffffc0204e78:	00001617          	auipc	a2,0x1
ffffffffc0204e7c:	3a060613          	addi	a2,a2,928 # ffffffffc0206218 <etext+0x9e4>
ffffffffc0204e80:	2d700593          	li	a1,727
ffffffffc0204e84:	00002517          	auipc	a0,0x2
ffffffffc0204e88:	17450513          	addi	a0,a0,372 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0204e8c:	e4ee                	sd	s11,72(sp)
ffffffffc0204e8e:	db8fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204e92 <do_yield>:
    current->need_resched = 1;
ffffffffc0204e92:	00096797          	auipc	a5,0x96
ffffffffc0204e96:	7467b783          	ld	a5,1862(a5) # ffffffffc029b5d8 <current>
ffffffffc0204e9a:	4705                	li	a4,1
}
ffffffffc0204e9c:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204e9e:	ef98                	sd	a4,24(a5)
}
ffffffffc0204ea0:	8082                	ret

ffffffffc0204ea2 <do_wait>:
    if (code_store != NULL)
ffffffffc0204ea2:	c59d                	beqz	a1,ffffffffc0204ed0 <do_wait+0x2e>
{
ffffffffc0204ea4:	1101                	addi	sp,sp,-32
ffffffffc0204ea6:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204ea8:	00096517          	auipc	a0,0x96
ffffffffc0204eac:	73053503          	ld	a0,1840(a0) # ffffffffc029b5d8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eb0:	4685                	li	a3,1
ffffffffc0204eb2:	4611                	li	a2,4
ffffffffc0204eb4:	7508                	ld	a0,40(a0)
{
ffffffffc0204eb6:	ec06                	sd	ra,24(sp)
ffffffffc0204eb8:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eba:	f0dfe0ef          	jal	ffffffffc0203dc6 <user_mem_check>
ffffffffc0204ebe:	6702                	ld	a4,0(sp)
ffffffffc0204ec0:	67a2                	ld	a5,8(sp)
ffffffffc0204ec2:	c909                	beqz	a0,ffffffffc0204ed4 <do_wait+0x32>
}
ffffffffc0204ec4:	60e2                	ld	ra,24(sp)
ffffffffc0204ec6:	85be                	mv	a1,a5
ffffffffc0204ec8:	853a                	mv	a0,a4
ffffffffc0204eca:	6105                	addi	sp,sp,32
ffffffffc0204ecc:	f24ff06f          	j	ffffffffc02045f0 <do_wait.part.0>
ffffffffc0204ed0:	f20ff06f          	j	ffffffffc02045f0 <do_wait.part.0>
ffffffffc0204ed4:	60e2                	ld	ra,24(sp)
ffffffffc0204ed6:	5575                	li	a0,-3
ffffffffc0204ed8:	6105                	addi	sp,sp,32
ffffffffc0204eda:	8082                	ret

ffffffffc0204edc <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204edc:	6789                	lui	a5,0x2
ffffffffc0204ede:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ee2:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0204ee4:	06e7e463          	bltu	a5,a4,ffffffffc0204f4c <do_kill+0x70>
{
ffffffffc0204ee8:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eea:	45a9                	li	a1,10
{
ffffffffc0204eec:	ec06                	sd	ra,24(sp)
ffffffffc0204eee:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ef0:	484000ef          	jal	ffffffffc0205374 <hash32>
ffffffffc0204ef4:	02051793          	slli	a5,a0,0x20
ffffffffc0204ef8:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204efc:	00092797          	auipc	a5,0x92
ffffffffc0204f00:	66478793          	addi	a5,a5,1636 # ffffffffc0297560 <hash_list>
ffffffffc0204f04:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204f06:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f08:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f0a:	a029                	j	ffffffffc0204f14 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204f0c:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204f10:	00c70963          	beq	a4,a2,ffffffffc0204f22 <do_kill+0x46>
ffffffffc0204f14:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204f16:	fea69be3          	bne	a3,a0,ffffffffc0204f0c <do_kill+0x30>
}
ffffffffc0204f1a:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204f1c:	5575                	li	a0,-3
}
ffffffffc0204f1e:	6105                	addi	sp,sp,32
ffffffffc0204f20:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f22:	fd852703          	lw	a4,-40(a0)
ffffffffc0204f26:	00177693          	andi	a3,a4,1
ffffffffc0204f2a:	e29d                	bnez	a3,ffffffffc0204f50 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f2c:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204f2e:	00176713          	ori	a4,a4,1
ffffffffc0204f32:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f36:	0006c663          	bltz	a3,ffffffffc0204f42 <do_kill+0x66>
            return 0;
ffffffffc0204f3a:	4501                	li	a0,0
}
ffffffffc0204f3c:	60e2                	ld	ra,24(sp)
ffffffffc0204f3e:	6105                	addi	sp,sp,32
ffffffffc0204f40:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204f42:	f2850513          	addi	a0,a0,-216
ffffffffc0204f46:	232000ef          	jal	ffffffffc0205178 <wakeup_proc>
ffffffffc0204f4a:	bfc5                	j	ffffffffc0204f3a <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204f4c:	5575                	li	a0,-3
}
ffffffffc0204f4e:	8082                	ret
        return -E_KILLED;
ffffffffc0204f50:	555d                	li	a0,-9
ffffffffc0204f52:	b7ed                	j	ffffffffc0204f3c <do_kill+0x60>

ffffffffc0204f54 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f54:	1101                	addi	sp,sp,-32
ffffffffc0204f56:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f58:	00096797          	auipc	a5,0x96
ffffffffc0204f5c:	60878793          	addi	a5,a5,1544 # ffffffffc029b560 <proc_list>
ffffffffc0204f60:	ec06                	sd	ra,24(sp)
ffffffffc0204f62:	e822                	sd	s0,16(sp)
ffffffffc0204f64:	e04a                	sd	s2,0(sp)
ffffffffc0204f66:	00092497          	auipc	s1,0x92
ffffffffc0204f6a:	5fa48493          	addi	s1,s1,1530 # ffffffffc0297560 <hash_list>
ffffffffc0204f6e:	e79c                	sd	a5,8(a5)
ffffffffc0204f70:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f72:	00096717          	auipc	a4,0x96
ffffffffc0204f76:	5ee70713          	addi	a4,a4,1518 # ffffffffc029b560 <proc_list>
ffffffffc0204f7a:	87a6                	mv	a5,s1
ffffffffc0204f7c:	e79c                	sd	a5,8(a5)
ffffffffc0204f7e:	e39c                	sd	a5,0(a5)
ffffffffc0204f80:	07c1                	addi	a5,a5,16
ffffffffc0204f82:	fee79de3          	bne	a5,a4,ffffffffc0204f7c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f86:	eedfe0ef          	jal	ffffffffc0203e72 <alloc_proc>
ffffffffc0204f8a:	00096917          	auipc	s2,0x96
ffffffffc0204f8e:	65e90913          	addi	s2,s2,1630 # ffffffffc029b5e8 <idleproc>
ffffffffc0204f92:	00a93023          	sd	a0,0(s2)
ffffffffc0204f96:	10050363          	beqz	a0,ffffffffc020509c <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f9a:	4789                	li	a5,2
ffffffffc0204f9c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f9e:	00003797          	auipc	a5,0x3
ffffffffc0204fa2:	06278793          	addi	a5,a5,98 # ffffffffc0208000 <bootstack>
ffffffffc0204fa6:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fa8:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204fac:	4785                	li	a5,1
ffffffffc0204fae:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb0:	4641                	li	a2,16
ffffffffc0204fb2:	8522                	mv	a0,s0
ffffffffc0204fb4:	4581                	li	a1,0
ffffffffc0204fb6:	055000ef          	jal	ffffffffc020580a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fba:	8522                	mv	a0,s0
ffffffffc0204fbc:	463d                	li	a2,15
ffffffffc0204fbe:	00002597          	auipc	a1,0x2
ffffffffc0204fc2:	3a258593          	addi	a1,a1,930 # ffffffffc0207360 <etext+0x1b2c>
ffffffffc0204fc6:	057000ef          	jal	ffffffffc020581c <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204fca:	00096797          	auipc	a5,0x96
ffffffffc0204fce:	6067a783          	lw	a5,1542(a5) # ffffffffc029b5d0 <nr_process>

    current = idleproc;
ffffffffc0204fd2:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fd6:	4601                	li	a2,0
    nr_process++;
ffffffffc0204fd8:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fda:	4581                	li	a1,0
ffffffffc0204fdc:	fffff517          	auipc	a0,0xfffff
ffffffffc0204fe0:	7f650513          	addi	a0,a0,2038 # ffffffffc02047d2 <init_main>
    current = idleproc;
ffffffffc0204fe4:	00096697          	auipc	a3,0x96
ffffffffc0204fe8:	5ee6ba23          	sd	a4,1524(a3) # ffffffffc029b5d8 <current>
    nr_process++;
ffffffffc0204fec:	00096717          	auipc	a4,0x96
ffffffffc0204ff0:	5ef72223          	sw	a5,1508(a4) # ffffffffc029b5d0 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ff4:	c68ff0ef          	jal	ffffffffc020445c <kernel_thread>
ffffffffc0204ff8:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204ffa:	08a05563          	blez	a0,ffffffffc0205084 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ffe:	6789                	lui	a5,0x2
ffffffffc0205000:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0205002:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205006:	02e7e463          	bltu	a5,a4,ffffffffc020502e <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020500a:	45a9                	li	a1,10
ffffffffc020500c:	368000ef          	jal	ffffffffc0205374 <hash32>
ffffffffc0205010:	02051713          	slli	a4,a0,0x20
ffffffffc0205014:	01c75793          	srli	a5,a4,0x1c
ffffffffc0205018:	00f486b3          	add	a3,s1,a5
ffffffffc020501c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020501e:	a029                	j	ffffffffc0205028 <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0205020:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205024:	04870d63          	beq	a4,s0,ffffffffc020507e <proc_init+0x12a>
    return listelm->next;
ffffffffc0205028:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020502a:	fef69be3          	bne	a3,a5,ffffffffc0205020 <proc_init+0xcc>
    return NULL;
ffffffffc020502e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205030:	0b478413          	addi	s0,a5,180
ffffffffc0205034:	4641                	li	a2,16
ffffffffc0205036:	4581                	li	a1,0
ffffffffc0205038:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020503a:	00096717          	auipc	a4,0x96
ffffffffc020503e:	5af73323          	sd	a5,1446(a4) # ffffffffc029b5e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205042:	7c8000ef          	jal	ffffffffc020580a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205046:	8522                	mv	a0,s0
ffffffffc0205048:	463d                	li	a2,15
ffffffffc020504a:	00002597          	auipc	a1,0x2
ffffffffc020504e:	33e58593          	addi	a1,a1,830 # ffffffffc0207388 <etext+0x1b54>
ffffffffc0205052:	7ca000ef          	jal	ffffffffc020581c <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205056:	00093783          	ld	a5,0(s2)
ffffffffc020505a:	cfad                	beqz	a5,ffffffffc02050d4 <proc_init+0x180>
ffffffffc020505c:	43dc                	lw	a5,4(a5)
ffffffffc020505e:	ebbd                	bnez	a5,ffffffffc02050d4 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205060:	00096797          	auipc	a5,0x96
ffffffffc0205064:	5807b783          	ld	a5,1408(a5) # ffffffffc029b5e0 <initproc>
ffffffffc0205068:	c7b1                	beqz	a5,ffffffffc02050b4 <proc_init+0x160>
ffffffffc020506a:	43d8                	lw	a4,4(a5)
ffffffffc020506c:	4785                	li	a5,1
ffffffffc020506e:	04f71363          	bne	a4,a5,ffffffffc02050b4 <proc_init+0x160>
}
ffffffffc0205072:	60e2                	ld	ra,24(sp)
ffffffffc0205074:	6442                	ld	s0,16(sp)
ffffffffc0205076:	64a2                	ld	s1,8(sp)
ffffffffc0205078:	6902                	ld	s2,0(sp)
ffffffffc020507a:	6105                	addi	sp,sp,32
ffffffffc020507c:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020507e:	f2878793          	addi	a5,a5,-216
ffffffffc0205082:	b77d                	j	ffffffffc0205030 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0205084:	00002617          	auipc	a2,0x2
ffffffffc0205088:	2e460613          	addi	a2,a2,740 # ffffffffc0207368 <etext+0x1b34>
ffffffffc020508c:	40000593          	li	a1,1024
ffffffffc0205090:	00002517          	auipc	a0,0x2
ffffffffc0205094:	f6850513          	addi	a0,a0,-152 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc0205098:	baefb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc020509c:	00002617          	auipc	a2,0x2
ffffffffc02050a0:	2ac60613          	addi	a2,a2,684 # ffffffffc0207348 <etext+0x1b14>
ffffffffc02050a4:	3f100593          	li	a1,1009
ffffffffc02050a8:	00002517          	auipc	a0,0x2
ffffffffc02050ac:	f5050513          	addi	a0,a0,-176 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02050b0:	b96fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050b4:	00002697          	auipc	a3,0x2
ffffffffc02050b8:	30468693          	addi	a3,a3,772 # ffffffffc02073b8 <etext+0x1b84>
ffffffffc02050bc:	00001617          	auipc	a2,0x1
ffffffffc02050c0:	15c60613          	addi	a2,a2,348 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02050c4:	40700593          	li	a1,1031
ffffffffc02050c8:	00002517          	auipc	a0,0x2
ffffffffc02050cc:	f3050513          	addi	a0,a0,-208 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02050d0:	b76fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050d4:	00002697          	auipc	a3,0x2
ffffffffc02050d8:	2bc68693          	addi	a3,a3,700 # ffffffffc0207390 <etext+0x1b5c>
ffffffffc02050dc:	00001617          	auipc	a2,0x1
ffffffffc02050e0:	13c60613          	addi	a2,a2,316 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02050e4:	40600593          	li	a1,1030
ffffffffc02050e8:	00002517          	auipc	a0,0x2
ffffffffc02050ec:	f1050513          	addi	a0,a0,-240 # ffffffffc0206ff8 <etext+0x17c4>
ffffffffc02050f0:	b56fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02050f4 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050f4:	1141                	addi	sp,sp,-16
ffffffffc02050f6:	e022                	sd	s0,0(sp)
ffffffffc02050f8:	e406                	sd	ra,8(sp)
ffffffffc02050fa:	00096417          	auipc	s0,0x96
ffffffffc02050fe:	4de40413          	addi	s0,s0,1246 # ffffffffc029b5d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205102:	6018                	ld	a4,0(s0)
ffffffffc0205104:	6f1c                	ld	a5,24(a4)
ffffffffc0205106:	dffd                	beqz	a5,ffffffffc0205104 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205108:	104000ef          	jal	ffffffffc020520c <schedule>
ffffffffc020510c:	bfdd                	j	ffffffffc0205102 <cpu_idle+0xe>

ffffffffc020510e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020510e:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205112:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205116:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205118:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020511a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020511e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205122:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205126:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020512a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020512e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205132:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205136:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020513a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020513e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205142:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205146:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020514a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020514c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020514e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205152:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205156:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020515a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020515e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205162:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205166:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020516a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020516e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205172:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205176:	8082                	ret

ffffffffc0205178 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205178:	4118                	lw	a4,0(a0)
{
ffffffffc020517a:	1101                	addi	sp,sp,-32
ffffffffc020517c:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020517e:	478d                	li	a5,3
ffffffffc0205180:	06f70763          	beq	a4,a5,ffffffffc02051ee <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205184:	100027f3          	csrr	a5,sstatus
ffffffffc0205188:	8b89                	andi	a5,a5,2
ffffffffc020518a:	eb91                	bnez	a5,ffffffffc020519e <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020518c:	4789                	li	a5,2
ffffffffc020518e:	02f70763          	beq	a4,a5,ffffffffc02051bc <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205192:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc0205194:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205196:	0e052623          	sw	zero,236(a0)
}
ffffffffc020519a:	6105                	addi	sp,sp,32
ffffffffc020519c:	8082                	ret
        intr_disable();
ffffffffc020519e:	e42a                	sd	a0,8(sp)
ffffffffc02051a0:	f64fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051a4:	6522                	ld	a0,8(sp)
ffffffffc02051a6:	4789                	li	a5,2
ffffffffc02051a8:	4118                	lw	a4,0(a0)
ffffffffc02051aa:	02f70663          	beq	a4,a5,ffffffffc02051d6 <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc02051ae:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02051b0:	0e052623          	sw	zero,236(a0)
}
ffffffffc02051b4:	60e2                	ld	ra,24(sp)
ffffffffc02051b6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051b8:	f46fb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc02051bc:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051be:	00002617          	auipc	a2,0x2
ffffffffc02051c2:	25a60613          	addi	a2,a2,602 # ffffffffc0207418 <etext+0x1be4>
ffffffffc02051c6:	45d1                	li	a1,20
ffffffffc02051c8:	00002517          	auipc	a0,0x2
ffffffffc02051cc:	23850513          	addi	a0,a0,568 # ffffffffc0207400 <etext+0x1bcc>
}
ffffffffc02051d0:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051d2:	adefb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc02051d6:	00002617          	auipc	a2,0x2
ffffffffc02051da:	24260613          	addi	a2,a2,578 # ffffffffc0207418 <etext+0x1be4>
ffffffffc02051de:	45d1                	li	a1,20
ffffffffc02051e0:	00002517          	auipc	a0,0x2
ffffffffc02051e4:	22050513          	addi	a0,a0,544 # ffffffffc0207400 <etext+0x1bcc>
ffffffffc02051e8:	ac8fb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc02051ec:	b7e1                	j	ffffffffc02051b4 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051ee:	00002697          	auipc	a3,0x2
ffffffffc02051f2:	1f268693          	addi	a3,a3,498 # ffffffffc02073e0 <etext+0x1bac>
ffffffffc02051f6:	00001617          	auipc	a2,0x1
ffffffffc02051fa:	02260613          	addi	a2,a2,34 # ffffffffc0206218 <etext+0x9e4>
ffffffffc02051fe:	45a5                	li	a1,9
ffffffffc0205200:	00002517          	auipc	a0,0x2
ffffffffc0205204:	20050513          	addi	a0,a0,512 # ffffffffc0207400 <etext+0x1bcc>
ffffffffc0205208:	a3efb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020520c <schedule>:

void schedule(void)
{
ffffffffc020520c:	1101                	addi	sp,sp,-32
ffffffffc020520e:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205210:	100027f3          	csrr	a5,sstatus
ffffffffc0205214:	8b89                	andi	a5,a5,2
ffffffffc0205216:	4301                	li	t1,0
ffffffffc0205218:	e3c1                	bnez	a5,ffffffffc0205298 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020521a:	00096897          	auipc	a7,0x96
ffffffffc020521e:	3be8b883          	ld	a7,958(a7) # ffffffffc029b5d8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205222:	00096517          	auipc	a0,0x96
ffffffffc0205226:	3c653503          	ld	a0,966(a0) # ffffffffc029b5e8 <idleproc>
        current->need_resched = 0;
ffffffffc020522a:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020522e:	04a88f63          	beq	a7,a0,ffffffffc020528c <schedule+0x80>
ffffffffc0205232:	0c888693          	addi	a3,a7,200
ffffffffc0205236:	00096617          	auipc	a2,0x96
ffffffffc020523a:	32a60613          	addi	a2,a2,810 # ffffffffc029b560 <proc_list>
        le = last;
ffffffffc020523e:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205240:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205242:	4809                	li	a6,2
ffffffffc0205244:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205246:	00c78863          	beq	a5,a2,ffffffffc0205256 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc020524a:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020524e:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205252:	03070363          	beq	a4,a6,ffffffffc0205278 <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205256:	fef697e3          	bne	a3,a5,ffffffffc0205244 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020525a:	ed99                	bnez	a1,ffffffffc0205278 <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020525c:	451c                	lw	a5,8(a0)
ffffffffc020525e:	2785                	addiw	a5,a5,1
ffffffffc0205260:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205262:	00a88663          	beq	a7,a0,ffffffffc020526e <schedule+0x62>
ffffffffc0205266:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc0205268:	d7ffe0ef          	jal	ffffffffc0203fe6 <proc_run>
ffffffffc020526c:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc020526e:	00031b63          	bnez	t1,ffffffffc0205284 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205272:	60e2                	ld	ra,24(sp)
ffffffffc0205274:	6105                	addi	sp,sp,32
ffffffffc0205276:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205278:	4198                	lw	a4,0(a1)
ffffffffc020527a:	4789                	li	a5,2
ffffffffc020527c:	fef710e3          	bne	a4,a5,ffffffffc020525c <schedule+0x50>
ffffffffc0205280:	852e                	mv	a0,a1
ffffffffc0205282:	bfe9                	j	ffffffffc020525c <schedule+0x50>
}
ffffffffc0205284:	60e2                	ld	ra,24(sp)
ffffffffc0205286:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205288:	e76fb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020528c:	00096617          	auipc	a2,0x96
ffffffffc0205290:	2d460613          	addi	a2,a2,724 # ffffffffc029b560 <proc_list>
ffffffffc0205294:	86b2                	mv	a3,a2
ffffffffc0205296:	b765                	j	ffffffffc020523e <schedule+0x32>
        intr_disable();
ffffffffc0205298:	e6cfb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc020529c:	4305                	li	t1,1
ffffffffc020529e:	bfb5                	j	ffffffffc020521a <schedule+0xe>

ffffffffc02052a0 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052a0:	00096797          	auipc	a5,0x96
ffffffffc02052a4:	3387b783          	ld	a5,824(a5) # ffffffffc029b5d8 <current>
}
ffffffffc02052a8:	43c8                	lw	a0,4(a5)
ffffffffc02052aa:	8082                	ret

ffffffffc02052ac <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052ac:	4501                	li	a0,0
ffffffffc02052ae:	8082                	ret

ffffffffc02052b0 <sys_putc>:
    cputchar(c);
ffffffffc02052b0:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052b2:	1141                	addi	sp,sp,-16
ffffffffc02052b4:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052b6:	f13fa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc02052ba:	60a2                	ld	ra,8(sp)
ffffffffc02052bc:	4501                	li	a0,0
ffffffffc02052be:	0141                	addi	sp,sp,16
ffffffffc02052c0:	8082                	ret

ffffffffc02052c2 <sys_kill>:
    return do_kill(pid);
ffffffffc02052c2:	4108                	lw	a0,0(a0)
ffffffffc02052c4:	c19ff06f          	j	ffffffffc0204edc <do_kill>

ffffffffc02052c8 <sys_yield>:
    return do_yield();
ffffffffc02052c8:	bcbff06f          	j	ffffffffc0204e92 <do_yield>

ffffffffc02052cc <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052cc:	6d14                	ld	a3,24(a0)
ffffffffc02052ce:	6910                	ld	a2,16(a0)
ffffffffc02052d0:	650c                	ld	a1,8(a0)
ffffffffc02052d2:	6108                	ld	a0,0(a0)
ffffffffc02052d4:	e22ff06f          	j	ffffffffc02048f6 <do_execve>

ffffffffc02052d8 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052d8:	650c                	ld	a1,8(a0)
ffffffffc02052da:	4108                	lw	a0,0(a0)
ffffffffc02052dc:	bc7ff06f          	j	ffffffffc0204ea2 <do_wait>

ffffffffc02052e0 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052e0:	00096797          	auipc	a5,0x96
ffffffffc02052e4:	2f87b783          	ld	a5,760(a5) # ffffffffc029b5d8 <current>
    return do_fork(0, stack, tf);
ffffffffc02052e8:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02052ea:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052ec:	6a0c                	ld	a1,16(a2)
ffffffffc02052ee:	d6bfe06f          	j	ffffffffc0204058 <do_fork>

ffffffffc02052f2 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052f2:	4108                	lw	a0,0(a0)
ffffffffc02052f4:	9b8ff06f          	j	ffffffffc02044ac <do_exit>

ffffffffc02052f8 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc02052f8:	00096697          	auipc	a3,0x96
ffffffffc02052fc:	2e06b683          	ld	a3,736(a3) # ffffffffc029b5d8 <current>
syscall(void) {
ffffffffc0205300:	715d                	addi	sp,sp,-80
ffffffffc0205302:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205304:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205306:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205308:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020530a:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020530c:	02d7ec63          	bltu	a5,a3,ffffffffc0205344 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc0205310:	00002797          	auipc	a5,0x2
ffffffffc0205314:	35078793          	addi	a5,a5,848 # ffffffffc0207660 <syscalls>
ffffffffc0205318:	00369613          	slli	a2,a3,0x3
ffffffffc020531c:	97b2                	add	a5,a5,a2
ffffffffc020531e:	639c                	ld	a5,0(a5)
ffffffffc0205320:	c395                	beqz	a5,ffffffffc0205344 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc0205322:	7028                	ld	a0,96(s0)
ffffffffc0205324:	742c                	ld	a1,104(s0)
ffffffffc0205326:	7830                	ld	a2,112(s0)
ffffffffc0205328:	7c34                	ld	a3,120(s0)
ffffffffc020532a:	6c38                	ld	a4,88(s0)
ffffffffc020532c:	f02a                	sd	a0,32(sp)
ffffffffc020532e:	f42e                	sd	a1,40(sp)
ffffffffc0205330:	f832                	sd	a2,48(sp)
ffffffffc0205332:	fc36                	sd	a3,56(sp)
ffffffffc0205334:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205336:	0828                	addi	a0,sp,24
ffffffffc0205338:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020533a:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020533c:	e828                	sd	a0,80(s0)
}
ffffffffc020533e:	6406                	ld	s0,64(sp)
ffffffffc0205340:	6161                	addi	sp,sp,80
ffffffffc0205342:	8082                	ret
    print_trapframe(tf);
ffffffffc0205344:	8522                	mv	a0,s0
ffffffffc0205346:	e436                	sd	a3,8(sp)
ffffffffc0205348:	facfb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020534c:	00096797          	auipc	a5,0x96
ffffffffc0205350:	28c7b783          	ld	a5,652(a5) # ffffffffc029b5d8 <current>
ffffffffc0205354:	66a2                	ld	a3,8(sp)
ffffffffc0205356:	00002617          	auipc	a2,0x2
ffffffffc020535a:	0e260613          	addi	a2,a2,226 # ffffffffc0207438 <etext+0x1c04>
ffffffffc020535e:	43d8                	lw	a4,4(a5)
ffffffffc0205360:	06200593          	li	a1,98
ffffffffc0205364:	0b478793          	addi	a5,a5,180
ffffffffc0205368:	00002517          	auipc	a0,0x2
ffffffffc020536c:	10050513          	addi	a0,a0,256 # ffffffffc0207468 <etext+0x1c34>
ffffffffc0205370:	8d6fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205374 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205374:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205378:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e49>
ffffffffc020537a:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc020537e:	02000513          	li	a0,32
ffffffffc0205382:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205384:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0205388:	8082                	ret

ffffffffc020538a <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020538a:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020538c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205390:	f022                	sd	s0,32(sp)
ffffffffc0205392:	ec26                	sd	s1,24(sp)
ffffffffc0205394:	e84a                	sd	s2,16(sp)
ffffffffc0205396:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205398:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020539c:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc020539e:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053a2:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053a6:	84aa                	mv	s1,a0
ffffffffc02053a8:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02053aa:	03067d63          	bgeu	a2,a6,ffffffffc02053e4 <printnum+0x5a>
ffffffffc02053ae:	e44e                	sd	s3,8(sp)
ffffffffc02053b0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053b2:	4785                	li	a5,1
ffffffffc02053b4:	00e7d763          	bge	a5,a4,ffffffffc02053c2 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02053b8:	85ca                	mv	a1,s2
ffffffffc02053ba:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02053bc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053be:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053c0:	fc65                	bnez	s0,ffffffffc02053b8 <printnum+0x2e>
ffffffffc02053c2:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053c4:	00002797          	auipc	a5,0x2
ffffffffc02053c8:	0bc78793          	addi	a5,a5,188 # ffffffffc0207480 <etext+0x1c4c>
ffffffffc02053cc:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053ce:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d0:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02053d4:	70a2                	ld	ra,40(sp)
ffffffffc02053d6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d8:	85ca                	mv	a1,s2
ffffffffc02053da:	87a6                	mv	a5,s1
}
ffffffffc02053dc:	6942                	ld	s2,16(sp)
ffffffffc02053de:	64e2                	ld	s1,24(sp)
ffffffffc02053e0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053e4:	03065633          	divu	a2,a2,a6
ffffffffc02053e8:	8722                	mv	a4,s0
ffffffffc02053ea:	fa1ff0ef          	jal	ffffffffc020538a <printnum>
ffffffffc02053ee:	bfd9                	j	ffffffffc02053c4 <printnum+0x3a>

ffffffffc02053f0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053f0:	7119                	addi	sp,sp,-128
ffffffffc02053f2:	f4a6                	sd	s1,104(sp)
ffffffffc02053f4:	f0ca                	sd	s2,96(sp)
ffffffffc02053f6:	ecce                	sd	s3,88(sp)
ffffffffc02053f8:	e8d2                	sd	s4,80(sp)
ffffffffc02053fa:	e4d6                	sd	s5,72(sp)
ffffffffc02053fc:	e0da                	sd	s6,64(sp)
ffffffffc02053fe:	f862                	sd	s8,48(sp)
ffffffffc0205400:	fc86                	sd	ra,120(sp)
ffffffffc0205402:	f8a2                	sd	s0,112(sp)
ffffffffc0205404:	fc5e                	sd	s7,56(sp)
ffffffffc0205406:	f466                	sd	s9,40(sp)
ffffffffc0205408:	f06a                	sd	s10,32(sp)
ffffffffc020540a:	ec6e                	sd	s11,24(sp)
ffffffffc020540c:	84aa                	mv	s1,a0
ffffffffc020540e:	8c32                	mv	s8,a2
ffffffffc0205410:	8a36                	mv	s4,a3
ffffffffc0205412:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205414:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205418:	05500b13          	li	s6,85
ffffffffc020541c:	00002a97          	auipc	s5,0x2
ffffffffc0205420:	344a8a93          	addi	s5,s5,836 # ffffffffc0207760 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205424:	000c4503          	lbu	a0,0(s8)
ffffffffc0205428:	001c0413          	addi	s0,s8,1
ffffffffc020542c:	01350a63          	beq	a0,s3,ffffffffc0205440 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205430:	cd0d                	beqz	a0,ffffffffc020546a <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205432:	85ca                	mv	a1,s2
ffffffffc0205434:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205436:	00044503          	lbu	a0,0(s0)
ffffffffc020543a:	0405                	addi	s0,s0,1
ffffffffc020543c:	ff351ae3          	bne	a0,s3,ffffffffc0205430 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0205440:	5cfd                	li	s9,-1
ffffffffc0205442:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205444:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0205448:	4b81                	li	s7,0
ffffffffc020544a:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020544c:	00044683          	lbu	a3,0(s0)
ffffffffc0205450:	00140c13          	addi	s8,s0,1
ffffffffc0205454:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0205458:	0ff5f593          	zext.b	a1,a1
ffffffffc020545c:	02bb6663          	bltu	s6,a1,ffffffffc0205488 <vprintfmt+0x98>
ffffffffc0205460:	058a                	slli	a1,a1,0x2
ffffffffc0205462:	95d6                	add	a1,a1,s5
ffffffffc0205464:	4198                	lw	a4,0(a1)
ffffffffc0205466:	9756                	add	a4,a4,s5
ffffffffc0205468:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020546a:	70e6                	ld	ra,120(sp)
ffffffffc020546c:	7446                	ld	s0,112(sp)
ffffffffc020546e:	74a6                	ld	s1,104(sp)
ffffffffc0205470:	7906                	ld	s2,96(sp)
ffffffffc0205472:	69e6                	ld	s3,88(sp)
ffffffffc0205474:	6a46                	ld	s4,80(sp)
ffffffffc0205476:	6aa6                	ld	s5,72(sp)
ffffffffc0205478:	6b06                	ld	s6,64(sp)
ffffffffc020547a:	7be2                	ld	s7,56(sp)
ffffffffc020547c:	7c42                	ld	s8,48(sp)
ffffffffc020547e:	7ca2                	ld	s9,40(sp)
ffffffffc0205480:	7d02                	ld	s10,32(sp)
ffffffffc0205482:	6de2                	ld	s11,24(sp)
ffffffffc0205484:	6109                	addi	sp,sp,128
ffffffffc0205486:	8082                	ret
            putch('%', putdat);
ffffffffc0205488:	85ca                	mv	a1,s2
ffffffffc020548a:	02500513          	li	a0,37
ffffffffc020548e:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205490:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205494:	02500713          	li	a4,37
ffffffffc0205498:	8c22                	mv	s8,s0
ffffffffc020549a:	f8e785e3          	beq	a5,a4,ffffffffc0205424 <vprintfmt+0x34>
ffffffffc020549e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02054a2:	1c7d                	addi	s8,s8,-1
ffffffffc02054a4:	fee79de3          	bne	a5,a4,ffffffffc020549e <vprintfmt+0xae>
ffffffffc02054a8:	bfb5                	j	ffffffffc0205424 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02054aa:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02054ae:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02054b0:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02054b4:	fd06071b          	addiw	a4,a2,-48
ffffffffc02054b8:	24e56a63          	bltu	a0,a4,ffffffffc020570c <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02054bc:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054be:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02054c0:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02054c4:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054c8:	0197073b          	addw	a4,a4,s9
ffffffffc02054cc:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054d0:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054d2:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054d6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054d8:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02054dc:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02054e0:	feb570e3          	bgeu	a0,a1,ffffffffc02054c0 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02054e4:	f60d54e3          	bgez	s10,ffffffffc020544c <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02054e8:	8d66                	mv	s10,s9
ffffffffc02054ea:	5cfd                	li	s9,-1
ffffffffc02054ec:	b785                	j	ffffffffc020544c <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054ee:	8db6                	mv	s11,a3
ffffffffc02054f0:	8462                	mv	s0,s8
ffffffffc02054f2:	bfa9                	j	ffffffffc020544c <vprintfmt+0x5c>
ffffffffc02054f4:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02054f6:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02054f8:	bf91                	j	ffffffffc020544c <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02054fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205500:	00f74463          	blt	a4,a5,ffffffffc0205508 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205504:	1a078763          	beqz	a5,ffffffffc02056b2 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205508:	000a3603          	ld	a2,0(s4)
ffffffffc020550c:	46c1                	li	a3,16
ffffffffc020550e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205510:	000d879b          	sext.w	a5,s11
ffffffffc0205514:	876a                	mv	a4,s10
ffffffffc0205516:	85ca                	mv	a1,s2
ffffffffc0205518:	8526                	mv	a0,s1
ffffffffc020551a:	e71ff0ef          	jal	ffffffffc020538a <printnum>
            break;
ffffffffc020551e:	b719                	j	ffffffffc0205424 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205520:	000a2503          	lw	a0,0(s4)
ffffffffc0205524:	85ca                	mv	a1,s2
ffffffffc0205526:	0a21                	addi	s4,s4,8
ffffffffc0205528:	9482                	jalr	s1
            break;
ffffffffc020552a:	bded                	j	ffffffffc0205424 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020552c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020552e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205532:	00f74463          	blt	a4,a5,ffffffffc020553a <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0205536:	16078963          	beqz	a5,ffffffffc02056a8 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020553a:	000a3603          	ld	a2,0(s4)
ffffffffc020553e:	46a9                	li	a3,10
ffffffffc0205540:	8a2e                	mv	s4,a1
ffffffffc0205542:	b7f9                	j	ffffffffc0205510 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205544:	85ca                	mv	a1,s2
ffffffffc0205546:	03000513          	li	a0,48
ffffffffc020554a:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc020554c:	85ca                	mv	a1,s2
ffffffffc020554e:	07800513          	li	a0,120
ffffffffc0205552:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205554:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0205558:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020555a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020555c:	bf55                	j	ffffffffc0205510 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc020555e:	85ca                	mv	a1,s2
ffffffffc0205560:	02500513          	li	a0,37
ffffffffc0205564:	9482                	jalr	s1
            break;
ffffffffc0205566:	bd7d                	j	ffffffffc0205424 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0205568:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020556c:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc020556e:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0205570:	bf95                	j	ffffffffc02054e4 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205572:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205574:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205578:	00f74463          	blt	a4,a5,ffffffffc0205580 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc020557c:	12078163          	beqz	a5,ffffffffc020569e <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205580:	000a3603          	ld	a2,0(s4)
ffffffffc0205584:	46a1                	li	a3,8
ffffffffc0205586:	8a2e                	mv	s4,a1
ffffffffc0205588:	b761                	j	ffffffffc0205510 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020558a:	876a                	mv	a4,s10
ffffffffc020558c:	000d5363          	bgez	s10,ffffffffc0205592 <vprintfmt+0x1a2>
ffffffffc0205590:	4701                	li	a4,0
ffffffffc0205592:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205596:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205598:	bd55                	j	ffffffffc020544c <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020559a:	000d841b          	sext.w	s0,s11
ffffffffc020559e:	fd340793          	addi	a5,s0,-45
ffffffffc02055a2:	00f037b3          	snez	a5,a5
ffffffffc02055a6:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055aa:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02055ae:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055b0:	008a0793          	addi	a5,s4,8
ffffffffc02055b4:	e43e                	sd	a5,8(sp)
ffffffffc02055b6:	100d8c63          	beqz	s11,ffffffffc02056ce <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02055ba:	12071363          	bnez	a4,ffffffffc02056e0 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055be:	000dc783          	lbu	a5,0(s11)
ffffffffc02055c2:	0007851b          	sext.w	a0,a5
ffffffffc02055c6:	c78d                	beqz	a5,ffffffffc02055f0 <vprintfmt+0x200>
ffffffffc02055c8:	0d85                	addi	s11,s11,1
ffffffffc02055ca:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055cc:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055d0:	000cc563          	bltz	s9,ffffffffc02055da <vprintfmt+0x1ea>
ffffffffc02055d4:	3cfd                	addiw	s9,s9,-1
ffffffffc02055d6:	008c8d63          	beq	s9,s0,ffffffffc02055f0 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055da:	020b9663          	bnez	s7,ffffffffc0205606 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02055de:	85ca                	mv	a1,s2
ffffffffc02055e0:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e2:	000dc783          	lbu	a5,0(s11)
ffffffffc02055e6:	0d85                	addi	s11,s11,1
ffffffffc02055e8:	3d7d                	addiw	s10,s10,-1
ffffffffc02055ea:	0007851b          	sext.w	a0,a5
ffffffffc02055ee:	f3ed                	bnez	a5,ffffffffc02055d0 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02055f0:	01a05963          	blez	s10,ffffffffc0205602 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02055f4:	85ca                	mv	a1,s2
ffffffffc02055f6:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02055fa:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02055fc:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02055fe:	fe0d1be3          	bnez	s10,ffffffffc02055f4 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205602:	6a22                	ld	s4,8(sp)
ffffffffc0205604:	b505                	j	ffffffffc0205424 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205606:	3781                	addiw	a5,a5,-32
ffffffffc0205608:	fcfa7be3          	bgeu	s4,a5,ffffffffc02055de <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc020560c:	03f00513          	li	a0,63
ffffffffc0205610:	85ca                	mv	a1,s2
ffffffffc0205612:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205614:	000dc783          	lbu	a5,0(s11)
ffffffffc0205618:	0d85                	addi	s11,s11,1
ffffffffc020561a:	3d7d                	addiw	s10,s10,-1
ffffffffc020561c:	0007851b          	sext.w	a0,a5
ffffffffc0205620:	dbe1                	beqz	a5,ffffffffc02055f0 <vprintfmt+0x200>
ffffffffc0205622:	fa0cd9e3          	bgez	s9,ffffffffc02055d4 <vprintfmt+0x1e4>
ffffffffc0205626:	b7c5                	j	ffffffffc0205606 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0205628:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020562c:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc020562e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205630:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205634:	8fb9                	xor	a5,a5,a4
ffffffffc0205636:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020563a:	02d64563          	blt	a2,a3,ffffffffc0205664 <vprintfmt+0x274>
ffffffffc020563e:	00002797          	auipc	a5,0x2
ffffffffc0205642:	27a78793          	addi	a5,a5,634 # ffffffffc02078b8 <error_string>
ffffffffc0205646:	00369713          	slli	a4,a3,0x3
ffffffffc020564a:	97ba                	add	a5,a5,a4
ffffffffc020564c:	639c                	ld	a5,0(a5)
ffffffffc020564e:	cb99                	beqz	a5,ffffffffc0205664 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205650:	86be                	mv	a3,a5
ffffffffc0205652:	00000617          	auipc	a2,0x0
ffffffffc0205656:	20e60613          	addi	a2,a2,526 # ffffffffc0205860 <etext+0x2c>
ffffffffc020565a:	85ca                	mv	a1,s2
ffffffffc020565c:	8526                	mv	a0,s1
ffffffffc020565e:	0d8000ef          	jal	ffffffffc0205736 <printfmt>
ffffffffc0205662:	b3c9                	j	ffffffffc0205424 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205664:	00002617          	auipc	a2,0x2
ffffffffc0205668:	e3c60613          	addi	a2,a2,-452 # ffffffffc02074a0 <etext+0x1c6c>
ffffffffc020566c:	85ca                	mv	a1,s2
ffffffffc020566e:	8526                	mv	a0,s1
ffffffffc0205670:	0c6000ef          	jal	ffffffffc0205736 <printfmt>
ffffffffc0205674:	bb45                	j	ffffffffc0205424 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205676:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205678:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020567c:	00f74363          	blt	a4,a5,ffffffffc0205682 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205680:	cf81                	beqz	a5,ffffffffc0205698 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205682:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205686:	02044b63          	bltz	s0,ffffffffc02056bc <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020568a:	8622                	mv	a2,s0
ffffffffc020568c:	8a5e                	mv	s4,s7
ffffffffc020568e:	46a9                	li	a3,10
ffffffffc0205690:	b541                	j	ffffffffc0205510 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205692:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205694:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205696:	bb5d                	j	ffffffffc020544c <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0205698:	000a2403          	lw	s0,0(s4)
ffffffffc020569c:	b7ed                	j	ffffffffc0205686 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc020569e:	000a6603          	lwu	a2,0(s4)
ffffffffc02056a2:	46a1                	li	a3,8
ffffffffc02056a4:	8a2e                	mv	s4,a1
ffffffffc02056a6:	b5ad                	j	ffffffffc0205510 <vprintfmt+0x120>
ffffffffc02056a8:	000a6603          	lwu	a2,0(s4)
ffffffffc02056ac:	46a9                	li	a3,10
ffffffffc02056ae:	8a2e                	mv	s4,a1
ffffffffc02056b0:	b585                	j	ffffffffc0205510 <vprintfmt+0x120>
ffffffffc02056b2:	000a6603          	lwu	a2,0(s4)
ffffffffc02056b6:	46c1                	li	a3,16
ffffffffc02056b8:	8a2e                	mv	s4,a1
ffffffffc02056ba:	bd99                	j	ffffffffc0205510 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02056bc:	85ca                	mv	a1,s2
ffffffffc02056be:	02d00513          	li	a0,45
ffffffffc02056c2:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02056c4:	40800633          	neg	a2,s0
ffffffffc02056c8:	8a5e                	mv	s4,s7
ffffffffc02056ca:	46a9                	li	a3,10
ffffffffc02056cc:	b591                	j	ffffffffc0205510 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02056ce:	e329                	bnez	a4,ffffffffc0205710 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056d0:	02800793          	li	a5,40
ffffffffc02056d4:	853e                	mv	a0,a5
ffffffffc02056d6:	00002d97          	auipc	s11,0x2
ffffffffc02056da:	dc3d8d93          	addi	s11,s11,-573 # ffffffffc0207499 <etext+0x1c65>
ffffffffc02056de:	b5f5                	j	ffffffffc02055ca <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056e0:	85e6                	mv	a1,s9
ffffffffc02056e2:	856e                	mv	a0,s11
ffffffffc02056e4:	08a000ef          	jal	ffffffffc020576e <strnlen>
ffffffffc02056e8:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02056ec:	01a05863          	blez	s10,ffffffffc02056fc <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02056f0:	85ca                	mv	a1,s2
ffffffffc02056f2:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056f4:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02056f6:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056f8:	fe0d1ce3          	bnez	s10,ffffffffc02056f0 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056fc:	000dc783          	lbu	a5,0(s11)
ffffffffc0205700:	0007851b          	sext.w	a0,a5
ffffffffc0205704:	ec0792e3          	bnez	a5,ffffffffc02055c8 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205708:	6a22                	ld	s4,8(sp)
ffffffffc020570a:	bb29                	j	ffffffffc0205424 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020570c:	8462                	mv	s0,s8
ffffffffc020570e:	bbd9                	j	ffffffffc02054e4 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205710:	85e6                	mv	a1,s9
ffffffffc0205712:	00002517          	auipc	a0,0x2
ffffffffc0205716:	d8650513          	addi	a0,a0,-634 # ffffffffc0207498 <etext+0x1c64>
ffffffffc020571a:	054000ef          	jal	ffffffffc020576e <strnlen>
ffffffffc020571e:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205722:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0205726:	00002d97          	auipc	s11,0x2
ffffffffc020572a:	d72d8d93          	addi	s11,s11,-654 # ffffffffc0207498 <etext+0x1c64>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020572e:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205730:	fda040e3          	bgtz	s10,ffffffffc02056f0 <vprintfmt+0x300>
ffffffffc0205734:	bd51                	j	ffffffffc02055c8 <vprintfmt+0x1d8>

ffffffffc0205736 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205736:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205738:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020573c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020573e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205740:	ec06                	sd	ra,24(sp)
ffffffffc0205742:	f83a                	sd	a4,48(sp)
ffffffffc0205744:	fc3e                	sd	a5,56(sp)
ffffffffc0205746:	e0c2                	sd	a6,64(sp)
ffffffffc0205748:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020574a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020574c:	ca5ff0ef          	jal	ffffffffc02053f0 <vprintfmt>
}
ffffffffc0205750:	60e2                	ld	ra,24(sp)
ffffffffc0205752:	6161                	addi	sp,sp,80
ffffffffc0205754:	8082                	ret

ffffffffc0205756 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205756:	00054783          	lbu	a5,0(a0)
ffffffffc020575a:	cb81                	beqz	a5,ffffffffc020576a <strlen+0x14>
    size_t cnt = 0;
ffffffffc020575c:	4781                	li	a5,0
        cnt ++;
ffffffffc020575e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0205760:	00f50733          	add	a4,a0,a5
ffffffffc0205764:	00074703          	lbu	a4,0(a4)
ffffffffc0205768:	fb7d                	bnez	a4,ffffffffc020575e <strlen+0x8>
    }
    return cnt;
}
ffffffffc020576a:	853e                	mv	a0,a5
ffffffffc020576c:	8082                	ret

ffffffffc020576e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020576e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205770:	e589                	bnez	a1,ffffffffc020577a <strnlen+0xc>
ffffffffc0205772:	a811                	j	ffffffffc0205786 <strnlen+0x18>
        cnt ++;
ffffffffc0205774:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205776:	00f58863          	beq	a1,a5,ffffffffc0205786 <strnlen+0x18>
ffffffffc020577a:	00f50733          	add	a4,a0,a5
ffffffffc020577e:	00074703          	lbu	a4,0(a4)
ffffffffc0205782:	fb6d                	bnez	a4,ffffffffc0205774 <strnlen+0x6>
ffffffffc0205784:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205786:	852e                	mv	a0,a1
ffffffffc0205788:	8082                	ret

ffffffffc020578a <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020578a:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020578c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205790:	0585                	addi	a1,a1,1
ffffffffc0205792:	0785                	addi	a5,a5,1
ffffffffc0205794:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205798:	fb75                	bnez	a4,ffffffffc020578c <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020579a:	8082                	ret

ffffffffc020579c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020579c:	00054783          	lbu	a5,0(a0)
ffffffffc02057a0:	e791                	bnez	a5,ffffffffc02057ac <strcmp+0x10>
ffffffffc02057a2:	a01d                	j	ffffffffc02057c8 <strcmp+0x2c>
ffffffffc02057a4:	00054783          	lbu	a5,0(a0)
ffffffffc02057a8:	cb99                	beqz	a5,ffffffffc02057be <strcmp+0x22>
ffffffffc02057aa:	0585                	addi	a1,a1,1
ffffffffc02057ac:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02057b0:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057b2:	fef709e3          	beq	a4,a5,ffffffffc02057a4 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057b6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057ba:	9d19                	subw	a0,a0,a4
ffffffffc02057bc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057be:	0015c703          	lbu	a4,1(a1)
ffffffffc02057c2:	4501                	li	a0,0
}
ffffffffc02057c4:	9d19                	subw	a0,a0,a4
ffffffffc02057c6:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057c8:	0005c703          	lbu	a4,0(a1)
ffffffffc02057cc:	4501                	li	a0,0
ffffffffc02057ce:	b7f5                	j	ffffffffc02057ba <strcmp+0x1e>

ffffffffc02057d0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057d0:	ce01                	beqz	a2,ffffffffc02057e8 <strncmp+0x18>
ffffffffc02057d2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057d6:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057d8:	cb91                	beqz	a5,ffffffffc02057ec <strncmp+0x1c>
ffffffffc02057da:	0005c703          	lbu	a4,0(a1)
ffffffffc02057de:	00f71763          	bne	a4,a5,ffffffffc02057ec <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02057e2:	0505                	addi	a0,a0,1
ffffffffc02057e4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057e6:	f675                	bnez	a2,ffffffffc02057d2 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057e8:	4501                	li	a0,0
ffffffffc02057ea:	8082                	ret
ffffffffc02057ec:	00054503          	lbu	a0,0(a0)
ffffffffc02057f0:	0005c783          	lbu	a5,0(a1)
ffffffffc02057f4:	9d1d                	subw	a0,a0,a5
}
ffffffffc02057f6:	8082                	ret

ffffffffc02057f8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02057f8:	a021                	j	ffffffffc0205800 <strchr+0x8>
        if (*s == c) {
ffffffffc02057fa:	00f58763          	beq	a1,a5,ffffffffc0205808 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc02057fe:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205800:	00054783          	lbu	a5,0(a0)
ffffffffc0205804:	fbfd                	bnez	a5,ffffffffc02057fa <strchr+0x2>
    }
    return NULL;
ffffffffc0205806:	4501                	li	a0,0
}
ffffffffc0205808:	8082                	ret

ffffffffc020580a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020580a:	ca01                	beqz	a2,ffffffffc020581a <memset+0x10>
ffffffffc020580c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020580e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205810:	0785                	addi	a5,a5,1
ffffffffc0205812:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205816:	fef61de3          	bne	a2,a5,ffffffffc0205810 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020581a:	8082                	ret

ffffffffc020581c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020581c:	ca19                	beqz	a2,ffffffffc0205832 <memcpy+0x16>
ffffffffc020581e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205820:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205822:	0005c703          	lbu	a4,0(a1)
ffffffffc0205826:	0585                	addi	a1,a1,1
ffffffffc0205828:	0785                	addi	a5,a5,1
ffffffffc020582a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020582e:	feb61ae3          	bne	a2,a1,ffffffffc0205822 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205832:	8082                	ret
