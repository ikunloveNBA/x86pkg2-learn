       ;14章章末习题
       ;实时检测1mb以上的内存空间


        mov eax,cs                          ;初始化栈段和栈指针
        mov ss,eax
        mov sp,0x7c00

        mov eax,[cs:pgdt+0x7c00+0x02]       ;将ds初始化为gdt逻辑段地址
        xor edx,edx
        mov ebx,16
        div ebx                             ;将ebx初始化为gdt偏移地址
        mov ds,eax
        mov ebx,edx

        ;创建0#描述符，它是空描述符，这是处理器的要求
        mov dword [ebx+0x00],0x00000000
        mov dword [ebx+0x04],0x00000000

        ;创建1#描述符，这是一个数据段，对应0~4GB的线性地址空间
        mov dword [ebx+0x08],0x0000ffff     ;基地址为0，段界限为0xfffff
        mov dword [ebx+0x0c],0x00cf9200     ;粒度为4KB，存储器段描述符

        ;创建保护模式下初始代码段描述符
        mov dword [ebx+0x10],0x7c0001ff     ;基地址为0x00007c00，512字节
        mov dword [ebx+0x14],0x00409800     ;粒度为1个字节，代码段描述符

        ;创建以上代码段的别名描述符
        mov dword [ebx+0x18],0x7c0001ff     ;基地址为0x00007c00，512字节
        mov dword [ebx+0x1c],0x00409200     ;粒度为1个字节，数据段描述符

        ;创建栈段
        mov dword [ebx+0x20],0x7c00fffe     ;基地址为0x00007c00，界限为0xffffe
        mov dword [ebx+0x24],0x00cf9600     ;粒度为4KB，向下扩展

        mov word  [cs: pgdt+0x7c00],39d     ;设置gdt大小

        lgdt [cs: pgdt+0x7c00]              ;初始化gdtr

        in al,0x92                          ;读取南桥芯片
        or al,0000_0010b
        out 0x92,al                         ;打开A20

        cli                                 ;32位中断尚未开始工作，所以禁止所有中断

        mov eax,cr0                         ;设置PE位
        or eax,1
        mov cr0,eax

        jmp 0x0010:dword flush              ;初始化cs

        [bits 32]                           ;设置32位操作长度

 flush:
        mov eax,0x0018                      ;初始化ds
        mov ds,eax

        mov eax,0x0008                      ;储存器数据段，初始化段寄存器
        mov es,eax
        mov fs,eax
        mov gs,eax

        mov eax,0x0020                      ;初始化栈
        mov ss,eax
        xor esp,esp

        mov dword [es:0x0b8000],0x072e0750  ;字符'P'、'.'及其显示属性
        mov dword [es:0x0b8004],0x072e074d  ;字符'M'、'.'及其显示属性
        mov dword [es:0x0b8008],0x07200720  ;两个空白字符及其显示属性
        mov dword [es:0x0b800c],0x076b076f  ;字符'o'、'k'及其显示属性
;-------------------------------------------------------------------------------

        ;初始化1mb以上的内存
init_memory:
        mov ebx,0x00100000                  ;设置ebx为有效地址
        mov ecx,0x00100000                  ;一共检查0x00100000个字节
        push ebx

 .write:
        mov dword [es:ebx],0x55aa55aa       ;将1mb以上的内存填满0x55aa55aa
        add ebx,4                           ;到0x004fffff
        loop .write                         ;一共填0x00100000个双字

        pop ebx

        ;检查1mb以上的内存
check_memory:
        mov ecx,over-start                  ;显示正在检测内存
        mov ebx,start
        mov edi,0xb8000+240                 ;设置字符串显示区域
        xor esi,esi
        call put_string

        ;显示进度条
        mov ecx,bar_table-ckmemory
        mov ebx,ckmemory
        mov edi,0xb8000+400
        xor esi,esi
        call put_string

        mov ecx,0x00100000                  ;检测0x00100000个双字
        mov ebx,0x00100000
.checking:
        mov eax,[es:ebx]                    
        cmp eax,0x55aa55aa                  ;检测是否为0x55aa55aa
        je .right                           ;如果检测正确就跳转
        add ebx,4
        loop .checking
        jmp check_end

.right:
        mov dword[es:ebx],0xaa55aa55        ;如果检测正确就换成0xaa55aa55
        add ebx,4
        inc edx                             ;已经检测的正确个数
        call upprogressbar
        loop .checking
        jmp check_end

        ;检查完毕，显示已完成
check_end:
        mov ecx,ckmemory-over
        mov ebx,over
        mov edi,0xb8000+240
        xor esi,esi
        call put_string


        hlt


;-------------------------------------------------------------------------------
        ;显示字符串
put_string:
        push eax                            ;eax保存字符的属性和ascii码
        push ebx                            ;ebx保存字符串第一个位置
        push esi                            ;esi保存字符串的偏移量
        push edi                            ;edi保存字符串将要去的第一个位置

.put_char:
        mov ah,0x07                         ;高8位属性
        mov al,[ebx+esi]                    ;低8位字符
        mov [es:edi],ax                     ;传送到显存
        add edi,2
        inc esi
        loop .put_char

        pop edi
        pop esi
        pop ebx
        pop eax

        ret
;-------------------------------------------------------------------------------
        ;更新进度条
upprogressbar:
        push eax
        push ecx
        push edx

        mov ecx,6                           ;显示条一共六个位需要改变


upprogressbar_1:
        mov eax,edx                         
        and eax,1111b                       ;只保留低四位
        mov al,[bar_table+eax]              ;将寄存器中的二进制转换为16进制
        mov [es:0xb8000+400+2+2*ecx],al     ;改变进度条
        shr edx,4                           ;一共6个位，从低到高依次循环
        loop upprogressbar_1

        pop edx
        pop ecx
        pop eax

        ret
;-------------------------------------------------------------------------------
        start       db 'checking'
        over        db 'finish! '
        ckmemory    db '0x000000/0x100000'
        bar_table   db '0123456789abcdef'
;-------------------------------------------------------------------------------
        pgdt        dw 0
                    dd 0x00007e00
;-------------------------------------------------------------------------------
        times 510-($-$$) db 0
                         db 0x55,0xaa 
