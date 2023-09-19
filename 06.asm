;设置数据段指向缓冲区
mov ax,0xb800     ;8086处理器可访问1mb内存，其中0x00000-0x9ffff属于常规内存，0xf0000-0xfffff是ROM-BIOS芯片（基本的输入输出系统），0xb8000-0xbffff属于显存
mov es,ax         ;ds是数据段寄存器，es是附加段寄存器，ax是累加寄存器

;将字符写到显存缓冲区
mov byte [es:0x00],'H'       ;数据段寄存器默认为ds，使用es要用超越段前缀
mov byte [es:0x01],0x07      ;一个ascii字符占两个位，低位是字符位，高位是属性位
mov byte [es:0x02],'E'
mov byte [es:0x03],0x07
mov byte [es:0x04],'L'
mov byte [es:0x05],0x07
mov byte [es:0x06],'L'
mov byte [es:0x07],0x07
mov byte [es:0x08],'O'
mov byte [es:0x09],0x07
mov byte [es:0x0a],','
mov byte [es:0x0b],0x07
mov byte [es:0x0c],'A'
mov byte [es:0x0d],0x07
mov byte [es:0x0e],'S'
mov byte [es:0x0f],0x07
mov byte [es:0x10],'M'
mov byte [es:0x11],0x07

;设置被除数和除数
mov ax,number     ;number是标号，处理器访问内存采用段地址：偏移地址，整个代码被看做一个独立的段，偏移地址为0，汇编地址就是偏移地址
mov bx,10         ;16位除法被除数放在ax中，余数在ah，商在al；32位除法被除数在dx:ax，余数在dx，商在ax

;设置数据段基地址
mov cx,cs         ;段寄存器之间必须通过通过通用寄存器传送,而且立即数不能直接被传送到段寄存器
mov ds,cx         ;cs为0x0000，所以ds为0x0000

;余数为个位
mov dx,0          ;number标号最多为16位偏移地址，故可以将dx清零
div bx
mov [0x7c00+number+0x00],dl           ;cs为0x0000，BIOS跳转到0x7c00处，故【】为数据偏移地址

;余数为十位
xor dx,dx         ;xor异或标志，数据位相同则为0，不同则为1，此处将dx清零，而且比减法要快             
div bx            
mov [0x7c00+number+0x01],dl

;余数为百位
xor dx,dx
div bx
mov [0x7c00+number+0x02],dl           ;个位数最多为9，超不过8位，所以余数只在dl中

;余数为千位
xor dx,dx
div bx
mov [0x7c00+number+0x03],dl

;余数为万位
xor dx,dx
div bx
mov [0x7c00+number+0x04],dl           ;因为16位地址最大为65535，所以只需要进行5次除法          

;以下用十进制显示标号的位置
mov al,[0x7c00+number+0x04]           
add al,0x30                           ;因为屏幕显示的是ascii码，故要将结果转变成ascii对应的二进制编码
mov [es:0x1a],al                      ;al为8位，所以不用加byte修饰                    
mov byte [es:0x1b],0x04 

mov al,[0x7c00+number+0x03]
add al,0x30
mov [es:0x1c],al
mov byte [es:0x1d],0x04

mov al,[0x7c00+number+0x02]
add al,0x30
mov [es:0x1e],al
mov byte [es:0x1f],0x04

mov al,[0x7c00+number+0x01]
add al,0x30
mov [es:0x20],al
mov byte [es:0x21],0x04

mov al,[0x7c00+number+0x00]
add al,0x30
mov [es:0x22],al
mov byte [es:0x23],0x04

mov byte [es:0x24],'D'
mov byte [es:0x25],0x07

infi jmp near infi          ;无限循环，jmp跳转标号原理是用标号汇编地址地址减去当前指令的下一个指令的汇编地址（ip+偏移量）

number db 0,0,0,0,0         ;用db占五个数据位，db是字节，dw是字，dd是双字，dq是四字，伪指令

times 203 db 0              ;执行203次指令
db 0x55,0xaa                ;主引导扇区强制格式，否则计算机不能识别
