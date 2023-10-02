;一个基本程序加载器的编写

app_lba_start equ 100                         ;声明一个常数代表第100个扇区，equ是等于的意思，不占汇编地址和内存

SECTION mbr align=16 vstart=0x7c00              ;段的写法，16位对齐，起始地址为0x7c00


        mov ax,0                                ;初始化加载器的栈段寄存器和栈指针寄存器
        mov ss,ax
        mov sp,ax

        mov ax,[cs:phy_base]                    ;将物理地址转换成段地址，并存到ax中行
        mov dx,[cs:phy_base+0x02]
        mov bx,16
        div bx
        mov ds,ax                               ;初始化ds，es
        mov es,ax

        xor di,di                               ;di保存高位
        mov si,app_lba_start                    ;si保存用户程序的起始扇区，si保存28位中的低位
        xor bx,bx 
        call read_hard_disk_0                   ;读取硬盘

        mov ax,[0]                              ;程序的总长度除以512，求出扇区数量
        mov dx,[2]
        mov bx,512
        div bx
        cmp dx,0
        jnz @1                                 ;余数不为0跳转
        dec ax                                 ;余数为0减1

     @1:                                       
        cmp ax,0                               ;小于一个扇区跳转
        jz direct

        push ds

        mov cx,ax                              ;记录剩余扇区数

     @2:
        mov ax,ds                              ;每次将数据段地址加512，将剩余扇区读完为止
        add ax,0x20
        mov ds,ax

        xor bx,bx
        inc si
        call read_hard_disk_0
        loop @2

        pop ds

 direct:                                       ;重置入口点的代码段地址
        mov dx,[0x08]
        mov ax,[0x06]
        call callc_segment_base
        mov [0x06],ax                          ;将最终正确的段地址写入到低地址处

        mov cx,[0x0a]                          ;将段重定位表项数记录
        mov bx,0x0c

realloc:
        mov dx,[bx+0x02]                       ;将段重定位表中的段地址重新写入
        mov ax,[bx]
        call callc_segment_base
        mov [bx],ax
        add bx,4
        loop realloc

        jmp far [0x04]

;-------------------------------------------------------------------------------
read_hard_disk_0:                              ;读取一个扇区的内容

        push ax 
        push bx
        push cx
        push dx

        mov dx,0x1f2                           ;0x1f2端口写入读取扇区的数量
        mov al,1
        out dx,al

        inc dx                                 ;0x1f3和0x1f4保存si
        mov ax,si
        out dx,al

        inc dx
        mov al,ah
        out dx,al

        inc dx                                 ;0x1f5和0x1f6保存di
        mov ax,di
        out dx,al

        inc dx
        mov al,0xe0                            ;0xe0是1110 0000，高四位确定0x1f6的状态
        or al,ah
        out dx,al

        inc dx
        mov al,0x20                            ;请求硬盘读
        out dx,al

 .waits:                                       ;判断硬盘的状态，如果不忙则读取硬盘的内容到内存中
        in al,dx
        and al,0x88
        cmp al,0x08
        jnz .waits

        mov cx,256                             ;一次写入两个字节，一个扇区512个字节，读256次
        mov dx,0x1f0

 .readw:
        in ax,dx                               ;bx是基址寄存器，读取扇区内容
        mov [bx],ax
        add bx,2
        loop .readw

        pop dx                                 ;将原来寄存器的内容弹出栈
        pop cx
        pop bx
        pop ax

        ret                                    ;返回原代码处

;-------------------------------------------------------------------------------
callc_segment_base:

        push dx

        add ax,[cs:phy_base]                   ;将20位物理地址转换成16位的段地址
        adc dx,[cs:phy_base+0x02]
        shr ax,4                               ;右移四位，最后一个比特位进入cf
        ror dx,4                               ;循环右移四位
        and dx,0xf000                          ;只保留高16位中的高四位
        or ax,dx                               ;将最终结果合并到ax中

        pop dx

        ret


;-------------------------------------------------------------------------------
        phy_base dd 0x10000                    ;将用户程序加载到0x10000物理内存

times 510-($-$$) db 0
             db 0x55,0xaa   
