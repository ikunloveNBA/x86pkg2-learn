

     mov sp,0x7c00                                 ;初始化栈
     mov ax,cs
     mov ss,ax

     mov dx,[cs:gdt_base+0x7c00+0x02]              ;将gdt物理地址转换为逻辑地址
     mov ax,[cs:gdt_base+0x7c00]                   ;并且存放到ds中
     mov bx,16
     div bx
     mov ds,ax
     mov si,dx

     mov dword[si],0x00                            ;第一个gdt是null段
     mov dword[si+0x04],0x00

     mov dword[si+0x08],0x8000ffff                 ;第二个是显存数据段
     mov dword[si+0x0c],0x0040920b

     mov word[cs:gdt_size+0x7c00],15               ;设置gdt的大小

     lgdt [cs:gdt_size+0x7c00]                     ;初始化gdtr

     mov dx,0x92                                   ;将A20第二个位设为1
     in al,dx                                      ;打开寄存器高位
     or al,0x02
     out dx,al

     cli                                           ;设置保护模式中断前，禁止中断

     mov eax,cr0                                   ;控制寄存器cr0最低位置位
     or eax,0x01
     mov cr0,eax

     mov cx,0x08                                   ;初始化ds，设置段选择器
     mov ds,cx

     mov byte [0x00],'P'
     mov byte [0x02],'r'
     mov byte [0x04],'o'
     mov byte [0x06],'t'
     mov byte [0x08],'e'
     mov byte [0x0a],'c'
     mov byte [0x0c],'t'
     mov byte [0x0e],' '
     mov byte [0x10],'m'
     mov byte [0x12],'o'
     mov byte [0x14],'d'
     mov byte [0x16],'e'
     mov byte [0x18],' '
     mov byte [0x1a],'O'
     mov byte [0x1c],'K'
     mov byte [0x1e],'.'

     hlt

     gdt_size dw 15
     gdt_base  dd 0x7e00                           ;设置gdt的位置
                                                   ;因为mbr只有512字节，刚好到这
     times 510-($-$$) db 0
                      db 0x55,0xaa 
