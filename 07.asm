;将字符显示到缓冲区中，并显示number的数位，学习循环

jmp near start         ;跳转到start标号处，near截取低16位

mytext db 'h',0x07,'e',0x07,'l',0x07,'l',0x07,'o',0x07,'a',0x07,'s',0x07,'m',0x07        ;提前为数据段占据内存空间
number db 0,0,0,0,0

start:
mov ax,0x7c0        ;设置数据段基地址为0x7c00
mov ds,ax

mov ax,0xb800        ;设置附加段寄存器基地址为显存缓冲区
mov es,ax

cld                                   ;设置flags标志寄存器的方向位置0，为正方向
mov si,mytext                         ;数据段偏移指针指向提前占位的内存
mov di,0
mov cx,(number-mytext)/2              ;传送字符的字数
rep movsw                             ;movsb传送字节，movsw传送字，后者比前者速度快，rep是连续传送的指令

mov ax,number

mov bx,ax
mov cx,5
mov si,10

digit:
xor dx,dx 
div si                  
mov [bx],dl                 ;bx是基址寄存器，可以用它表示内存
inc bx                      ;inc是加一
loop digit                  ;loop是循环，如果cx（计数寄存器）为0则跳出循环

mov bx,number               
mov si,4

show:
mov al,[bx+si]              ;寻址方式为基址+偏移地址，基址寄存器有bx，bp，偏移地址寄存器si，di，其他寄存器不可以这么使用
add al,0x30
mov ah,0x04
mov [es:di],ax
add di,2
dec si
jns show                    ;jns，如果sf标志位不为0则跳转，si为0时，16位的sf最高位是0，则跳出循环

mov word [es:di],0x0744     ;word表示传的是两个字节，44是D的ascii码，07是属性

jmp near $                  ;$表示当前行的标号（汇编地址），此处是个死循环

times 510-($-$$) db 0       ;$$表示当前程序段的起始地址，相减代表字节数，剩余的用0填满
db 0x55,0xaa

