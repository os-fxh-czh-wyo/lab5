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
> 
> - 如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。
> 
> > Copy-on-write（简称COW）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。

**解答 :**

1. **内存复制机制**
   
   - 在 `do_fork` 创建子进程时，把父进程用户地址空间 [start, end) 中的合法页完整复制到子进程的页表中，实现内存资源的“dup”语义（不做 COW）。
   
   - copy_range 代码补全
     
     ```c++
     int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
                    bool share)
     {
         assert(start % PGSIZE == 0 && end % PGSIZE == 0);
         assert(USER_ACCESS(start, end));
         // 遍历父进程页表中 [start, end) 的每个虚拟页，逐页复制到子进程的页表中
         do
         {
             // 在 from 页目录中查找 start 对应的 PTE，不创建下级页表（create = 0）
             pte_t *ptep = get_pte(from, start, 0), *nptep;
             if (ptep == NULL)
             {
                 start = ROUNDDOWN(start + PTSIZE, PTSIZE);
                 continue;
             }
             if (*ptep & PTE_V)
             {
                 // 在目标页目录 to 中查找/创建对应的 PTE（create = 1，会为缺失的页表分配页）
                 if ((nptep = get_pte(to, start, 1)) == NULL)
                 {
                     return -E_NO_MEM;
                 }
     
                 // 取出源 PTE 的用户权限位，用于在目标中重建相同的权限。
                 uint32_t perm = (*ptep & PTE_USER);
     
                 // 得到源物理页并为目标分配新页
                 struct Page *page = pte2page(*ptep);
                 struct Page *npage = alloc_page();
                 assert(page != NULL);
                 assert(npage != NULL);
     
                 int ret = 0;
     
                 // 以下为补全的代码
                 void *src_kvaddr = page2kva(page); // 拿到源页的内核虚拟地址
                 void *dst_kvaddr = page2kva(npage); // 拿到新页的内核虚拟地址
                 memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // 内存拷贝
                 ret = page_insert(to, npage, start, perm); // 建立页表映射
     
                 assert(ret == 0);
             }
             start += PGSIZE;
         } while (start != 0 && start < end);
         return 0;
     }
     ```

2. **COW 机制**
   
   实现 COW 的关键在于把“读”和“写”的处理区分开：
   
   读操作无需复制物理页，只要让父子进程共享同一物理页并通过指针访问即可；写操作则在首次写时触发缺页/保护异常，由内核在异常处理里为该进程分配新的物理页、把原页内容拷贝过去并更新该进程的页表项，使其拥有独立的可写映射。
   
   因此，在 fork 时不复制全部物理页，只需把相关页表项改为只读（以便后续写时产生异常）并让子进程引用相同的页框；当某一进程尝试写入时，内核捕获写保护异常，执行按需复制（分配新页、memcpy、修改页表并恢复写权限），从而在保持内存共享和减少复制开销的同时保证写时的语义隔离。

### 练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现

> 请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：
> 
> - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
> - 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
> 
> 执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-4.1.1）

**解答 :** 

- `fork`的执行流程
  
  - 用户通过系统调用接口触发`fork`，在用户态准备系统调用参数
  
  - 内核态部分，`do_fork` 主要的工作有：
    
    - 调用 `alloc_proc()`分配进程控制块
    
    - 调用 `setup_kstack()`分配内核栈
    
    - 调用 `copy_mm()`复制、共享内存空间
    
    - 调用 `copy_thread()`设置上下文和中断帧
    
    - 获取唯一 PID
    
    - 加入进程哈希表和链表
    
    - 唤醒子进程

- `exec`的执行流程：
  
  - 在用户态准备程序路径、参数、环境变量
  
  - 在内核态调用`do_execve`:
    
    - 检查参数合法性
    
    - 释放当前进程内存空间
    
    - 调用 `load_icode()`加载新程序：
    
    - 解析 ELF 文件格式
    
    - 创建新的内存映射
    
    - 复制代码段、数据段
    
    - 设置 BSS 段
    
    - 建立用户栈
    
    - 设置新的中断帧（入口点、栈指针、状态）

- `wait`的执行流程
  
  - 用户通过系统调用接口触发 `wait` 或 `waitpid`，在用户态准备系统调用参数
  
  - 内核态部分，`do_wait` 主要的工作有：
    
    - 验证参数合法性（如 `code_store` 的用户地址可写性）
    
    - 遍历当前进程的子进程列表（或查找指定 `pid` 的子进程），检查是否有子进程处于 `PROC_ZOMBIE` 状态
    
    - 若找到僵尸子进程

      - 将子进程的 `exit_code` 写回用户提供的 `code_store`

      - 在关中断保护区内从进程哈希表和父子链表中移除该子进程

      - 释放子进程的内核资源（`put_kstack`、`kfree(proc)` 等由父进程负责真正回收）

      - 返回（成功）并把结果通过 `syscall` 返回给用户态
    
    - 若存在子进程但无僵尸，则将当前进程置为睡眠，设置 `wait_state（WT_CHILD）`，调用 `schedule()` 阻塞，等待被唤醒后重试检查
    
    - 若没有任何子进程，则返回错误

- `exit`的执行流程：
  
  - 用户通过系统调用接口触发`exit`，在用户态提供退出码并进入内核态执行退出逻辑
  
  - 内核态部分，`do_exit` 主要的工作有:
    
    - 合法性检查
    
    - 回收/处理用户地址空间：如果 `current->mm` 存在，切回内核页表，递减 mm 引用计数，若引用计数为 0 则释放页表和 VMA 结构，最后把 `current->mm` 置为空
    
    - 记录退出码并把进程状态设为 `PROC_ZOMBIE`
    
    - 在关中断保护区内处理父子关系：

      - 若父进程在 `WT_CHILD`，唤醒父进程

      - 将当前进程的所有子进程转移给 `initproc`，必要时唤醒 `initproc` 以便其回收孤儿僵尸
    
    - 调用 `schedule()` 切出（`do_exit` 不返回）

- 生命周期图

PROC_UNINIT
  |  alloc_proc()
  v
RUNNABLE <------------------------------+
  |  scheduler/proc_run/switch_to       |  (yield / need_resched -> schedule)
  |                                     |
  v                                     |
RUNNING ------------------------------- +
  |  do_sleep()/do_wait()  (set PROC_SLEEPING, wait_state) 
  |--> SLEEPING -- wakeup_proc() --> RUNNABLE
  |
  |  do_yield()/need_resched -> schedule -> RUNNABLE
  |
  |  do_fork()  (parent RUNNING) 
  |    -> alloc_proc/setup_kstack/copy_mm/copy_thread
  |    -> init child.tf (a0=0), set pid, hash/set_links, wakeup_proc(child)
  |    => child becomes RUNNABLE
  |
  |  do_execve()/load_icode()  (replace mm, set tf->epc/sp/status)
  |    => process continues (returns to user with new image)
  |
  |  do_exit(error) 
  |    -> release mm (if needed), set state = PROC_ZOMBIE, set exit_code,
  |       reparent children -> initproc, wakeup parent if WT_CHILD
  |    -> schedule() (does not return)
  v
ZOMBIE
  |  parent calls do_wait()/do_waitpid()
  |    -> copy exit_code to user, unhash/remove_links, put_kstack, kfree(proc)
  v
removed (resources freed)

### 扩展练习 Challenge 1 ：实现 Copy on Write （COW）机制

> 给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。
> 
> 这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。
> 
> 由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。
> 
> 这是一个big challenge.

本次实验我实现了 COW 机制的第一阶段：在 `copy_range` 中加入了 `share` 分支，当 `share == true` 时不再为子进程分配新物理页和拷贝数据，而是通过调用 `page_insert` 把父进程（`from`）中对应页的权限修改为 `perm & ~PTE_W`（去掉写权限，从而变为只读），同时在子进程（`to`）中也建立对同一物理页面的只读映射（同样使用 `perm & ~PTE_W`），从而实现父子进程共享同一物理页且均为只读访问，节省内存并延迟复制开销；当 `share == false` 时则保持原来的深拷贝逻辑（分配新页、`memcpy`、`page_insert`）。代码如下：

```c++
// pmm.c 的 copy_range 函数（do/while 循环内部）：
            // ······ 
            // 得到源物理页并为目标分配新页
            struct Page *page = pte2page(*ptep);
            assert(page != NULL);

            int ret = 0;
            if(share)
            {
                // 物理页面共享，并设置两个PTE上的标志位为只读
                page_insert(from, page, start, perm & ~PTE_W);
                ret = page_insert(to, page, start, perm & ~PTE_W);
            }
            else{
                //原来的复制逻辑
                struct Page *npage = alloc_page();
                assert(npage != NULL);

                void *src_kvaddr = page2kva(page);
                void *dst_kvaddr = page2kva(npage);
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
                // 将目标页面地址设置到PTE中
                ret = page_insert(to, npage, start, perm);
            }
            assert(ret == 0);
           // ······
```

需要说明的是，目前我实现了让页表进入“只读共享”状态以及由 `page_insert` 维护的引用计数更新，这是 COW 的准备工作，尚未实现写时复制的完整路径：在页面写保护异常（page fault）处理处加入对只读共享页的识别与分配/拷贝逻辑、根据 `page_ref` 决定是否直接恢复写权限或执行复制、以及与文件映射/MAP_SHARED、内核页、swap 以及并发同步等边界情形。因为写时复制涉及到异常处理、引用计数的竞态控制、TLB 刷新、以及与虚拟内存/换页子系统的复杂交互，改动面大、实现和验证都相对耗时且容易引入难排的 bug，后续若有时间会在 trap/page-fault 处理处补全写时复制逻辑并补充完备的测试用例与状态机说明。

### 扩展练习 Challenge 2

> 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

1. 何时被预先加载

用户程序二进制本身在构建时被嵌入到内核镜像。运行时 `user_main` 调用 `KERNEL_EXECVE -> kernel_execve`（通过 `ebreak` 发起 `SYS_exec`），内核在 `syscall` 路径调用 `do_execve -> load_icode`。`load_icode` 在内核态为进程新建 mm/页表并把嵌入的二进制按段逐页拷贝到用户虚拟地址空间。在程序执行之前，所有需要的内容都已经加载到了内存中。

2. 与常用操作系统的加载的区别

ucore：二进制作为内核镜像的一部分预置到内存映像（无需文件系统/磁盘访问）；exec 时内核一次性为所有段分配页面并 memcpy 到用户页（立即加载，非按需加载）。

常见操作系统：可执行文件存放在持久存储，通过文件系统读取（不是内核镜像内嵌）；exec 主要建立映射与元信息，实际页面在首次访问时从磁盘读入，或通过 file‑backed mmap 映射而非每次拷贝（按需加载）。

3. 原因

省去实现文件系统、块 I/O、swap、复杂按需加载逻辑，便于聚焦进程/内存/调度核心机制；所有用户程序随内核镜像提供，环境可控、测试/打分稳定；实验工程开销低，启动与实现更直接。