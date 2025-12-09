# Lab5 实验报告

### 练习0：填写已有实验

> 本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。
> 注意：为了能够正确执行 lab5 的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。

**解答：** 

1. teap.c文件更改

    更改原来lab3相应位置的代码为下面的代码：

    ```c++
    clock_set_next_event(); // 设置下一次时钟中断
    ticks++; // ticks 计数器自增
    if (ticks % TICK_NUM == 0) { // 每 TICK_NUM 次中断
        print_ticks();
        if (current) { // 若有当前进程，设置为需要重调度
            current->need_resched = 1;
        }
    }
    ```

2. proc.c文件更改

    首先要在alloc_proc函数处增加lab5新增成员变量的初始化。其次要修改do_fork函数，确保父进程的wait_state为0，且在插入进程集合时不直接用 list_add/nr_process++，而调用 set_links(proc)。更改代码如下：

    ```c++
    // alloc_proc(void)函数新增
    proc->exit_code = 0;
    proc->wait_state = 0;
    proc->cptr = proc->yptr = proc->optr = NULL;

    // do_fork函数更改
    // ...
    // 1.创建进程结构体 
    if ((proc = alloc_proc()) == NULL)
    {
        goto fork_out;
    }
    // 设置父进程
    proc->parent = current;
    current->wait_state = 0; // 新增：确保父进程的wait_state为0
    
    // 2.创建内核栈
    if (setup_kstack(proc) != 0)
    {
        goto bad_fork_cleanup_proc;
    }

    // 3.共享内存管理结构体
    if (copy_mm(clone_flags, proc) != 0)
    {
        goto bad_fork_cleanup_kstack;
    }

    // 4.设置trapframe和context
    copy_thread(proc, stack, tf);
    // 以下操作需要关中断保护,因为涉及全局数据结构的修改
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        //    5. 设置进程状态为可运行
        // 分配唯一的PID
        proc->pid = get_pid();
        // 加入进程hash表
        hash_proc(proc);

        // 更改：不用 list_add和nr_process++，而调用 set_links(proc)
        //list_add(&proc_list, &(proc->list_link));
        //nr_process++;
        set_links(proc); // 加入全局进程链表
    }
    // ...
    ```

### 练习1：加载应用程序并执行

> do_execve函数调用load_icode（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充load_icode的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好proc_struct结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

**实现过程：**

1. 设置用户栈顶指针：把用户态的栈指针设为用户栈顶（USTACKTOP），使进程在进入用户态后从该地址向下生长使用栈。

2. 设置程序计数器：把用户程序的入口地址写入 trapframe 的 EPC 字段（这个值会在内核返回用户态时成为 CSR sepc 的值），sret 返回时 CPU 会从该地址开始在用户态执行。

3. 设置处理器状态信息：这一步要做的就是把 SPP 置零以使 sret 将特权降到 U-mode；置位 SPIE 以在返回后允许在用户态发生中断。
涉及到两个关键状态位：SPP和SPIE。

- SPP：当从 U-mode 或 S-mode 发生异常并进入 S-mode 处理时，硬件会把发生异常前的特权级记录到 SPP。sret 指令在从 S-mode 返回时会参考 SPP 来决定返回到哪个特权级：如果 SPP=0 则返回到 U-mode，否则返回到 S-mode（或按规范的语义）。
- SPIE：表示处理器在异常或中断发生前的中断使能状态。它的值为 0 时表示异常或中断发生前中断被禁用，为 1 时表示中断被启用。

load_icode的第6步代码如下：

```c++
tf->gpr.sp = USTACKTOP; // 设置用户栈顶指针
tf->epc = elf->e_entry; // 设置程序计数器
tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE; // 设置处理器状态信息
```

**经过：**

- 准备阶段：
  - 若 mm 不为空，说明该进程是一个用户进程，先切回内核页表，在内核页表下根据 mm 的引用计数决定后续处理。若引用数降为 0 则释放该 mm 的 VMA/映射、释放页表并销毁 mm；最后把 mm 置为空，完成旧用户空间的回收/重置。

- 加载与映射：
  - 解析 ELF 头和段表，为进程新建 mm 并建立新的页目录（复制内核高位映射以保留内核地址映射）。
  - 对每个 LOAD 段：在 mm 中添加对应的 VMA，为段内用到的虚拟页分配物理页，在页表建立映射并把文件内容拷贝到这些物理页；对 BSS 部分做清零处理。
  - 为用户栈建立 VMA，并显式地为栈顶附近的若干页分配物理页，栈顶地址为约定的 USTACKTOP。

- 激活地址空间
  - 增加 mm 的引用计数并把 mm 挂到 current ；把页表物理基址写入并通过 lsatp 把 SATP 设置为新页表，从而使后续访存走新进程的虚拟地址映射。

- 建立返回现场并跳回用户态
  - 初始化并设置 trapframe：保存原 sstatus、清零 trapframe，然后设置用户栈指针为 USTACKTOP、把 ELF 的入口写入 epc，并把 sstatus 的 SPP 清 0、置 SPIE。
  - 通过正常上下文切换路径恢复并使用该 trapframe，最终执行 sret，CPU 降到用户特权并从 ELF 的入口开始执行第一条用户指令。

### 练习2：父进程复制自己的内存空间给子进程

> 创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过copy_range函数（位于kern/mm/pmm.c中）实现的，请补充copy_range的实现，确保能够正确执行。
>
> 请在实验报告中简要说明你的设计实现过程。
> - 如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。
> > Copy-on-write（简称COW）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。

**解答 :**


### 练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现

> 请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：
>
> - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
> - 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
>
> 执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-4.1.1）

**解答 :** 

### 扩展练习 Challenge 1 ：实现 Copy on Write （COW）机制

> 给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。
>
> 这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。
>
> 由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。
>
> 这是一个big challenge.

### 扩展练习 Challenge 2

> 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？


